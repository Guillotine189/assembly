%include "./dep/constants.inc"

section .data
    cursor_idx dq 0
    history_command_number dq 0
    tabs_times_pressed dq 0

    colour_reset    db 27, "[0m", 0
    colour_blue     db 27, "[34m", 0
    colour_bright_green   db 27, "[92m", 0
    dot db ".", 0
    double_dot db "..", 0
    back_slash db "/", 0
    nine_spaces db "         ", 0
    

get_dent_buffer_cap equ 8192
section .bss
    key_buffer: resb 10
    reusable_buffer_read: resb 4096

    double_tab_string_object_address resq 1

    dir_fd_getdents: resq 1
    dir_get_dent_buffer: resb get_dent_buffer_cap
    dir_get_dent_buffer_len: resq 1

    command_latest_restore_buffer resb 4096

section .rodata
    
    ; what i receive when someone pressed home/end/ctrl+left/right button
    ;move_cur_home_pos db 27, "[H", 0
    ;move_cur_end_pos db 27, "[F", 0
    ;move_cur_left_space -> if ctrl+left_arrow -> i recv- > "[1;5D"
    ; ';' ->modifier 5D; = '5'->ctrl was pressed, 'D' -> left arrow key


    ; what i print when i have to move the cursor somewhere
    move_cur_up db 27, "[A", 0
    move_cur_down db 27, "[B", 0
    move_cur_right db 27, "[C", 0
    move_cur_left db 27, "[D", 0
    move_cur_next_line db 27, "[E"
    erase_char_in_front db 27, "[P"
    clear_to_right db 27, "[K"
    erase_everything_after_cursor_including_cursor db 27, "[0K", 0

    cursor_save    db 27, "[s", 0
    cursor_restore db 27, "[u", 0

section .text

; var
extern filled_size_input_buffer_len
extern input_interrupted
extern input_buffer_address
extern capacity_input_buffer_len
extern error_code
extern exit_status_code
extern _exit_with_status_code
extern new_line
extern exit_flag
extern curr_cwd
extern curr_cwd_len

extern termios
extern old_termios

; funcs
extern _print_malloc_segments_info
extern _malloc
extern _free
extern _mem_copy
extern _print
extern _strlen
extern _strcmp
extern _memcpy_with_end_char
extern _print
extern _print_with_new_line
extern _print_with_tabs
extern _add_cmd_into_history
extern _return_address_of_command_from_newest
extern _string_copy_including_null
extern _cmp_equal_memory
extern print_error_reading_input
extern print_error_increasing_input_mem
extern _strcpy_add_space_before_backslash

extern _print_prefix_line

extern _constructor_mystring
extern _destructor_mystring
extern _append_string_mystring

global _read_input

; TODO: handle overflow into next line
_read_input:
    ; make a read call

    mov qword [rel filled_size_input_buffer_len], 0
    mov qword [rel input_interrupted], 0
    mov qword [rel cursor_idx], 0
    mov qword [rel history_command_number], 0        ; 0 for current, 1 for older
    mov qword [rel command_latest_restore_buffer], 0

    ; in non-cononical mode, ctld+d return \4 

    .read_key:

        
        mov rax, 0                      ;sys_read
        mov rdi, 0                      ; fd 0
        lea rsi, [rel key_buffer]
        mov rdx, 1                      ; len to put into key_buffer
        syscall
        
        cmp rax, EINTR          ; -4, ctrl+c interrupted
        je .interrupted

        test rax, rax
        jl .handle_error_reading_input
            
        cmp byte [rel key_buffer], 0x04         ; in non-cononical mode, this is ctrl+d
        je .handle_eof

        cmp byte [rel key_buffer], 0x09         ; TODO: move cursor to end of line before exit
        je .handle_tab

        mov qword [rel tabs_times_pressed], 0

        cmp byte [rel key_buffer], 27 
        je .escape_seq  

        cmp byte [rel key_buffer], 127          ; backspace
        je .handle_backspace

        cmp byte [rel key_buffer], 0x0a         ; TODO: move cursor to end of line before exit
        je .return

        ; this si for ctrl + keys, right now i just ignore them except 
        cmp byte [rel key_buffer], 31                ; last char before usable chars
        jle .check_if_new_line

        jmp .handle_key

        .check_if_new_line:
            cmp byte [rel key_buffer], 0x0a
            je .return
            jmp .read_key

        .handle_key:
        .add_char_to_input_buffer:

        cmp qword [rel filled_size_input_buffer_len], 0
        jne .complex

        inc qword [rel filled_size_input_buffer_len]
        inc qword [rel cursor_idx]
        mov al, [rel key_buffer]
        mov rcx, [rel input_buffer_address]
        mov [rcx], al

        mov rax, 1
        mov rdi, 1
        mov rsi, [rel input_buffer_address]
        call _print

        jmp .read_key


        .complex:
        ; check if i can add a char
        mov rcx, [rel capacity_input_buffer_len]
        sub rcx, 8                      ; i will add something after, so i need some
        cmp rcx, [rel filled_size_input_buffer_len]
        jle .need_more_space

        jmp .move_char_to_right

        .need_more_space:
            call .get_more_buffer_size
    
        .move_char_to_right:
        ; move all the character from the cursor position to right first
        mov rax, [rel input_buffer_address]
        add rax, [rel filled_size_input_buffer_len]   ; old length, so now rax points to 
        dec rax                 ; address of the right most char in input_buffer
        mov rcx, [rel input_buffer_address]
        add rcx, [rel cursor_idx]   ; address of cursor

        cmp rcx, rax                ; comparing addresses
        jg .done_copying

        .loop_shift_right:
            mov dl, [rax]
            mov [rax+1], dl

            cmp rax, rcx            ; end address and cursor address
            je .done_copying

            dec rax
            jmp .loop_shift_right

        .done_copying:
        inc qword [rel filled_size_input_buffer_len]

        ; insert new character into input_buffer
        mov al, [rel key_buffer]
        mov [rcx], al


        ; print the updated right side
        mov rax, [rel input_buffer_address]
        add rax, [rel filled_size_input_buffer_len]        ; the last byte is 1 byte ahead
        sub rax, rcx                ; address of last byte minus address of cursor position
        push rax 
        mov rdi, 1
        mov rsi, rcx                        ; address where cursor points
        call _print                         ; cursor now at the end

        .done_printing:
        pop rdi
        dec rdi                             ; i still want to move 1 space ahead
        .move_cursor_left:
            test rdi, rdi
            jz .done

            push rdi

            mov rax, 1
            mov rdi, 1
            lea rsi, [rel move_cur_left]
            mov rdx, 3
            syscall

            pop rdi
            dec rdi
            jmp .move_cursor_left

        .done:
        inc [rel cursor_idx]

        jmp .read_key

    .escape_seq:
        ; read '['
        mov rax, 0
        xor rdi, rdi
        lea rsi, [rel key_buffer]
        mov rdx, 1
        syscall

        ; read final char
        mov rax, 0
        xor rdi, rdi
        lea rsi, [rel key_buffer]
        mov rdx, 1
        syscall

        cmp byte [rel key_buffer], 'A'          ; arrow key up
        je .print_older_history

        cmp byte [rel key_buffer], 'B'          ; arrow key down
        je .print_newer_history

        cmp byte [rel key_buffer], 'D' 
        je .cursor_left

        cmp byte [rel key_buffer], 'C'
        je .cursor_right

        cmp byte [rel key_buffer], 'H'
        je .cursor_home

        cmp byte [rel key_buffer], 'F'
        je .cursor_end

        cmp byte [rel key_buffer], '1'
        je .modifier

        jmp .read_key

    .print_newer_history:
        dec qword [rel history_command_number]      ; if it was 2 then 1

        cmp qword [rel history_command_number], 0
        je .print_latest_command
        jl .history_command_zero_and_read_next_key
        jg .get_newer_history

        .history_command_zero_and_read_next_key:
            mov qword [rel history_command_number], 0
            jmp .read_key

        .print_latest_command:
            mov r8, [rel cursor_idx]

            .move_home11:
            test r8, r8
            jz .home_done11

            mov eax, 1
            mov edi, 1
            lea rsi, [rel move_cur_left]
            mov edx, 3
            syscall

            dec r8
            dec qword [rel cursor_idx]
            jmp .move_home11
            .home_done11:

            ; remove all char to the right
            mov eax, 1
            mov edi, 1
            lea rsi, [rel clear_to_right]
            mov edx, 3
            syscall


            lea rdi, [rel command_latest_restore_buffer]
            call _strlen

            ; move the command into the input_buffer
            mov rdi, [rel input_buffer_address]
            lea rsi, [rel command_latest_restore_buffer]
            mov rcx, rax
            rep movsb
        
            mov [rel filled_size_input_buffer_len], rax
            mov [rel cursor_idx], rax
 
            mov rdi, 1
            lea rsi, [rel command_latest_restore_buffer]
            call _print


            jmp .read_key


        .get_newer_history:
        mov rdi, [rel history_command_number]
        call _return_address_of_command_from_newest

        test rax, rax
        jl .no_more_new_commands

        ; rax has address of older command
        mov r12, rax                            ; r12 has address of command
        mov rdi, rax
        call _strlen
        mov r13, rax                            ; r13 len of command
        .loop_memory1:
            cmp r13, [rel capacity_input_buffer_len]
            jg .get_more_memory_buffer1
            jmp .enough_memory1

            .get_more_memory_buffer1:
                call .get_more_buffer_size

            .loopback1:
                jmp .loop_memory

        .enough_memory1:

        ; move cursor to home
        mov rax, [rel cursor_idx] 
        test rax, rax
        jz .home_done1            ; if already at home do nothing
        mov r8, rax

        .move_home2:
        test r8, r8
        jz .home_done2

        mov eax, 1
        mov edi, 1
        lea rsi, [rel move_cur_left]
        mov edx, 3
        syscall

        dec r8
        jmp .move_home2
        .home_done2:

        ; remove all char to the right
        mov eax, 1
        mov edi, 1
        lea rsi, [rel clear_to_right]
        mov edx, 3
        syscall
    
        ; move the commmand into input_buffer_address
        mov rcx, r13
        mov rdi, [rel input_buffer_address]
        mov rsi, r12
        rep movsb

        ; print the input_buffer_address
        mov rax, r13
        mov rdi, 1
        mov rsi, [rel input_buffer_address]
        call _print

        mov [rel filled_size_input_buffer_len], r13
        mov [rel cursor_idx], r13

        jmp .read_key

        ; TODO: maybe this part is obsolete, remove this 
        .no_more_new_commands:   ; i am accessing the latest byte
            mov qword [rel history_command_number], 0
            ; move cursor to home
            mov rax, [rel cursor_idx]
            test rax, rax
            jz .home_done1            ; if already at home do nothing
            mov r8, rax

            .move_home3:
            test r8, r8
            jz .home_done3

            mov eax, 1
            mov edi, 1
            lea rsi, [rel move_cur_left]
            mov edx, 3
            syscall

            dec r8
            jmp .move_home3
            .home_done3:

            ; remove all char to the right
            mov eax, 1
            mov edi, 1
            lea rsi, [rel clear_to_right]
            mov edx, 3
            syscall

            mov qword [rel filled_size_input_buffer_len], 0
            mov qword [rel cursor_idx], 0

            jmp .read_key


    .print_older_history:

        cmp qword [rel history_command_number], 0
        je .save_the_latest_command_in_buffer
        jmp .get_older_his

        ; TODO: this is a hack, if command is > 4095 bytes, memory overflow
        .save_the_latest_command_in_buffer:
            lea rdi, [rel command_latest_restore_buffer]
            mov rsi, [rel input_buffer_address]
            mov rcx, [rel filled_size_input_buffer_len]
            rep movsb
            inc rdi
            mov byte [rdi], 0       ; terminate it with null byte

        .get_older_his:
        inc qword [rel history_command_number]      ; if it was 0 then 1

        mov rdi, [rel history_command_number]
        call _return_address_of_command_from_newest

        test rax, rax
        jl .no_more_old_commands

        ; rax has address of older command
        mov r12, rax                            ; r12 has address of command
        mov rdi, rax
        call _strlen
        mov r13, rax                            ; r13 len of command
        .loop_memory:
            cmp r13, [rel capacity_input_buffer_len]
            jg .get_more_memory_buffer
            jmp .enough_memory

            .get_more_memory_buffer:
                call .get_more_buffer_size

            .loopback:
                jmp .loop_memory

        .enough_memory:

        ; move cursor to home
        mov rax, [rel cursor_idx] 
        test rax, rax
        jz .home_done1            ; if already at home do nothing
        mov rdi, rax

        .move_home1:
        test rdi, rdi
        jz .home_done1
        push rdi

        mov eax, 1
        mov edi, 1
        lea rsi, [rel move_cur_left]
        mov edx, 3
        syscall

        pop rdi
        dec rdi
        jmp .move_home1
        .home_done1:

        ; remove all char to the right
        mov eax, 1
        mov edi, 1
        lea rsi, [rel clear_to_right]
        mov edx, 3
        syscall
    
        ; move the commmand into input_buffer_address
        mov rcx, r13
        mov rdi, [rel input_buffer_address]
        mov rsi, r12
        rep movsb

        ; print the input_buffer_address
        mov rax, r13
        mov rdi, 1
        mov rsi, [rel input_buffer_address]
        call _print

        mov [rel filled_size_input_buffer_len], r13
        mov [rel cursor_idx], r13

        jmp .read_key


        .no_more_old_commands:
            dec qword [rel history_command_number]
            jmp .read_key

    .cursor_home:
        mov rax, [rel cursor_idx] 
        test rax, rax
        jz .read_key            ; if already at home do nothing

        mov rdi, rax

        .move_home:
        test rdi, rdi
        jz .home_done

        push rdi

        mov eax, 1
        mov edi, 1
        lea rsi, [rel move_cur_left]
        mov edx, 3
        syscall

        pop rdi
        dec rdi
        jmp .move_home

        .home_done:
        mov qword [rel cursor_idx], 0
        jmp .read_key


    .cursor_end:
        mov rax, [rel filled_size_input_buffer_len]
        sub rax, [rel cursor_idx]

        ; rax has the number of positions to move right

        .move_end:
        test rax,  rax
        jz .end_done
        push rax

        mov rax, 1
        mov rdi, 1
        lea rsi, [rel move_cur_right]
        mov rdx, 3
        syscall

        pop rax
        dec rax
        jmp .move_end

        .end_done:
        mov rax, [rel filled_size_input_buffer_len]
        mov [rel cursor_idx], rax
        jmp .read_key


    .cursor_left:
        mov rax, [rel cursor_idx]

        test rax, rax
        jz .read_key

        dec rax
        mov [rel cursor_idx], rax

        mov rax, 1
        mov rdi, 1
        lea rsi, [rel move_cur_left]
        mov rdx, 3
        syscall

        jmp .read_key


    .cursor_right:
        
        mov rax, [rel cursor_idx]
        cmp rax, [rel filled_size_input_buffer_len]
        jge .dont_move_forward

        inc rax
        mov [rel cursor_idx], rax

        mov rax, 1
        mov rdi, 1
        lea rsi, [rel move_cur_right]
        mov rdx, 3
        syscall

        .dont_move_forward:

        jmp .read_key



    ; IMP: whichever index my cursor is at, i have to remove the prev element
    .handle_backspace:
        mov rax, [rel cursor_idx]

        test rax, rax               ; if i am at the very beginning dont, do anything
        jz .read_key


        ; else copy memory from cursor till end to left
        mov rax, [rel input_buffer_address]
        add rax, [rel cursor_idx]           ; now i am at cursor index
        dec rax                             ; at the index bfore cursor

        mov rcx, [rel input_buffer_address]
        add rcx, [rel filled_size_input_buffer_len]               ; byte after key_buffer
        dec rcx                             ; last byte of key_buffer

        cmp rax, rcx
        je .done_copying_left       ; to remove the last byte from key_buffer, no copy

        .loop_shift_left:

            cmp rax, rcx            ; when rax = last byte dont run.
            je .done_copying_left

            mov dl, [rax+1]
            mov [rax], dl

            inc rax
            jmp .loop_shift_left

        .done_copying_left:
        dec [rel filled_size_input_buffer_len]

        ; now print the changes, cursor pointing at the starting byte i neet to print

        mov rax, 1
        mov rdi, 1
        lea rsi, [rel move_cur_left]
        mov rdx, 3
        syscall
        dec qword [rel cursor_idx]              ; cursor at correct addess

        mov rax, [rel filled_size_input_buffer_len]
        sub rax, [rel cursor_idx]
        push rax

        mov rdi, 1
        mov rsi, [rel input_buffer_address]
        add rsi, [rel cursor_idx]
        call _print                         ; cursor now at the end

        ; first remove old data, that was after this

        mov rax, 1
        mov rdi, 1
        lea rsi, [rel erase_everything_after_cursor_including_cursor]
        mov rdx, 4
        syscall

        ; now visially change cursor to go back last byte
        pop rdi
        .move_cursor_left_back:
            test rdi, rdi
            jz .done2

            push rdi

            mov rax, 1
            mov rdi, 1
            lea rsi, [rel move_cur_left]
            mov rdx, 3
            syscall

            pop rdi
            dec rdi
            jmp .move_cursor_left_back

        .done2:
        
        jmp .read_key

   .modifier:
        ; Read ';'
        mov rax, 0
        xor rdi, rdi
        lea rsi, [rel key_buffer]
        mov rdx, 1
        syscall


        ; Read modifier number
        mov rax, 0
        xor rdi, rdi
        lea rsi, [rel key_buffer]
        mov rdx, 1
        syscall

        cmp byte [rel key_buffer], '5'
        je .handle_ctrl_key

        jmp .read_key

    .handle_ctrl_key:
        ; read which key presses with ctrl
        mov rax, 0
        xor rdi, rdi
        lea rsi, [rel key_buffer]
        mov rdx, 1
        syscall


        cmp byte [rel key_buffer], 'A'
        je .print_malloc_info

        cmp byte [rel key_buffer], 'D'
        je .cursor_left_space

        cmp byte [rel key_buffer], 'C'
        je .cursor_right_space

        jmp .read_key

    .print_malloc_info:

        mov rax, 1
        mov rdi, 1
        lea rsi, [rel new_line]
        call _print

        call _print_malloc_segments_info

        call _print_prefix_line

        mov rax, [rel filled_size_input_buffer_len]
        mov rdi, 1
        mov rsi, [rel input_buffer_address]
        call _print

        mov rax, [rel filled_size_input_buffer_len]
        mov [rel cursor_idx], rax
        jmp .read_key
        
    .cursor_left_space:
        mov rax, [rel cursor_idx]

        ; Already at beginning
        test rax, rax
        jz .read_key

        mov r9, [rel input_buffer_address]

        .skip_spaces_left:
            test rax, rax
            jz .set_cursor_left_space

            cmp byte [r9 + rax - 1], ' '   ; check if byte before this a white space
            jne .skip_word_left

            dec rax
            push rax
            ; Move visual cursor left
            mov eax, 1
            mov edi, 1
            lea rsi, [rel move_cur_left]
            mov edx, 3
            syscall
            pop rax
            jmp .skip_spaces_left


        .skip_word_left:
            test rax, rax
            jz .set_cursor_left_space

            cmp byte [r9 + rax - 1], ' '
            je .set_cursor_left_space

            dec rax
            push rax

            ; move cursor left
            mov eax, 1
            mov edi, 1
            lea rsi, [rel move_cur_left]
            mov edx, 3
            syscall
            pop rax
            jmp .skip_word_left


        .set_cursor_left_space:
            mov [rel cursor_idx], rax
            jmp .read_key


    .cursor_right_space:
        mov rax, [rel cursor_idx]
        mov r9, [rel input_buffer_address]

        ; Already at end
        cmp rax, [rel filled_size_input_buffer_len]
        jge .read_key

        .skip_word_right:
        cmp rax, [rel filled_size_input_buffer_len]
        jge .set_cursor_right_space

        cmp byte [r9 + rax], ' '
        je .skip_spaces_right

        inc rax

        ; Move visual cursor right
        push rax

        mov eax, 1
        mov edi, 1
        lea rsi, [rel move_cur_right]
        mov edx, 3
        syscall

        pop rax
        jmp .skip_word_right

        .skip_spaces_right:
        cmp rax, [rel filled_size_input_buffer_len]
        jge .set_cursor_right_space

        cmp byte [r9 + rax], ' '
        jne .set_cursor_right_space

        inc rax

        ; move cursor right
        push rax

        mov eax, 1
        mov edi, 1
        lea rsi, [rel move_cur_right]
        mov edx, 3
        syscall

        pop rax
        jmp .skip_spaces_right

        .set_cursor_right_space:
        mov [rel cursor_idx], rax
        jmp .read_key


    .handle_tab:

        inc qword [rel tabs_times_pressed]

        cmp [rel filled_size_input_buffer_len], 0   ;if nothing is written dont check
        jz .read_key


        ; find the last word written 1 byte before cursor pointer

        mov r8, [rel cursor_idx]
        dec r8
        mov r9, [rel input_buffer_address]
        xor r10, r10                    ; holds the position of last backslash
        .loop_last_word_written:

            cmp r8, 0
            je .first_byte_reached


            cmp byte [r9 + r8], '/'
            je .back_slash_enc

            cmp byte [r9 + r8], ' '
            je .space_reached

        .loopback22:
            dec r8
            jmp .loop_last_word_written


        .back_slash_enc:    
            test r10, r10               ; if backslash was encountered already, dont update
            jnz .loopback22

            mov r10, r8
            jmp .loopback22

        .space_reached:
            inc r8              ; index is at space, move it to last

        .first_byte_reached:        
        ; r8 is at first byte, r10 is at index at which last '/'  is there, if there is
        
        ; first tcheck if it was empty or not
        mov rax, [rel cursor_idx]
        
        cmp rax, r8         ; if the len of word is zero
        je .read_key

        ; now i know atleast 1 byte is there 
        ;check if there was slash in the word "./path/to/something"
        ;                                      |. r8    |/ r10
        ;check if no slash  slash in the word "/something"
        ;                                      |/ r8      r10 = r8


        ; if the word start with /, use it as absolute path to check 

        cmp byte [r9 + r8], '/'
        je .absolute_path

        ; here i have to add cwd before whatever the word was typed
        ; eg "./path/file" -> "/cwd/./path" 
        ; eg "file" -> "/cwd/" 
        ; -> then check this path, and print entries matching "file"

        push r10
        push r8
        mov rax, [rel curr_cwd_len]
        lea rdi, [rel reusable_buffer_read]
        lea rsi, [rel curr_cwd]
        mov rdx, '/'
        mov r8, 1
        call _memcpy_with_end_char  ; rax has addres of next byte
        pop r8
        pop r10
        push rax

        ; if there was no slash in word
        test r10, r10
        jz .copy_entire_word

        mov r11, r10
        sub r11, r8                 ; these many byte to copy into buffer
        inc r11
        jmp .copy

        .copy_entire_word:
        mov rcx, [rel cursor_idx]
        sub rcx, r8
        mov r11, rcx                 ; len of word found

        .copy:

        pop rdi
        push r10
        push r8
        
        mov rax, r11
        mov rsi, [rel input_buffer_address]
        add rsi, r8
        mov rdx, 0
        mov r8, 1
        call _memcpy_with_end_char  ; rax has addres of next byte
        pop r8
        pop r10

        

        jmp .find_dir


        .absolute_path:

        ; here i have can check the word was typed
        ; eg1 "/path/file"  ->  check
        ; eg2 "/" -> "/"

        sub r10, r8                 ; these many byte to copy into buffer
        inc r10
        test r10, r10               ; in example 2
        je .increase_len_to_accomodate_slash
        jmp .cont

        .increase_len_to_accomodate_slash:
            inc r10

        .cont:
        push r10
        push r8
        mov rax, r10        
        lea rdi, [rel reusable_buffer_read]
        mov rsi, [rel input_buffer_address]
        add rsi, r8
        mov rdx, 0
        mov r8, 1
        call _memcpy_with_end_char  ; rax has addres of next byte
        pop r8
        pop r10

        .find_dir:

        ; reusable_buffer_read contains the addres of the directory
        ; if the directory exists, then get contents of directory.
        ; check the file with the starting of every entry and print those who matches


        mov     rax, 2
        lea     rdi, [rel reusable_buffer_read]
        mov     rsi, O_RDONLY | O_DIRECTORY
        xor     rdx, rdx
        syscall

        test rax, rax
        jl .read_key        ; if directory does not exists leave it


        mov [rel dir_fd_getdents], rax


        .create_string_object:
        sub rsp, 24
        mov qword [rsp + 0], 1024             ; asking for 1024 bytes
        mov qword [rsp + 8], 0
        mov qword [rsp + 16], 0
        mov rdi, rsp
        call _constructor_mystring

        mov [rel double_tab_string_object_address], rsp


        inc r10             ; r10 is now pointing at the "./file", 'f'
        mov r12, r10
        xor r14, r14            ; hold how manny patterns match
        .loop_get_dents:

        mov rax, sys_getdents64
        mov rdi, [rel dir_fd_getdents]
        lea rsi, [rel dir_get_dent_buffer]
        mov rdx, get_dent_buffer_cap
        syscall

        
        mov r13, [rel cursor_idx]
        sub r13, r12                    ; this is the lenght of "file" in "./file"
        ; r13 is the length after directory


        test rax, rax
        jle .done_constructing   ; if cannot get info/error, or no more info -> just return

        mov [rel dir_get_dent_buffer_len], rax


        lea r9, [rel dir_get_dent_buffer]

        .get_next_segment:
        lea rax, [rel dir_get_dent_buffer]
        add rax, [rel dir_get_dent_buffer_len]
        cmp r9, rax
        jae .loop_get_dents

        .find_type_and_print:
        cmp byte [r9+ 18], DT_DIR
        je .add_dir

        cmp byte [r9+ 18], DT_REG
        je .add_reg_file

        push r9                         ; ignore other types of files for now
        jmp .move_to_next_segment

        .add_reg_file:
            push r9

            ; if the "./" is input, r13 is zero, so append the file
            test r13, r13
            jz .append_reg_file

            ; check if the len of this file >= current len
            lea rdi, [r9 + 19]
            call _strlen

            pop r9
            push r9
            
            cmp rax, r13
            jge .check_if_file_starts_with_end
            jmp .move_to_next_segment

        .check_if_file_starts_with_end:
            ; now i know that the file len => same bytes long as input
            mov rax, r13
            lea rsi, [r9 + 19]
            mov rdi, [rel input_buffer_address]
            add rdi, r12
            call _cmp_equal_memory

            pop r9
            push r9
            
            test rax, rax
            jz .append_reg_file
            jmp .move_to_next_segment

        .append_reg_file:
            inc r14
            lea rdi, [rel reusable_buffer_read]

            lea rsi, [r9 + 19]
            call _strcpy_add_space_before_backslash
            lea rsi, [rel nine_spaces]
            call _string_copy_including_null

            mov rdi, [rel double_tab_string_object_address]
            lea rsi, [rel reusable_buffer_read]
            call _append_string_mystring

            jmp .move_to_next_segment

        .add_dir:
            push r9

            lea rax, [rel dot]
            lea rdi, [r9+19]
            call _strcmp
            test rax, rax
            jz .move_to_next_segment

            pop r9
            push r9

            ; if the "./" is input, r11 is zero, so append the file
            test r13, r13
            jz .append_dir

            ; check if the len of this file >= current len
            lea rdi, [r9 + 19]
            call _strlen

            pop r9
            push r9

            cmp rax, r13
            jge .check_if_dir_starts_with_end
            jmp .move_to_next_segment

        .check_if_dir_starts_with_end:
            ; now i know that the dir len => same bytes long as input
            mov rax, r13
            lea rsi, [r9 + 19]
            mov rdi, [rel input_buffer_address]
            add rdi, r12
            call _cmp_equal_memory

            pop r9
            push r9
            
            test rax, rax
            jz .append_dir
            jmp .move_to_next_segment


        .append_dir:
            inc r14

            lea rdi, [rel reusable_buffer_read]

            lea rsi, [r9 + 19]
            call _strcpy_add_space_before_backslash
            
            lea rsi, [rel back_slash]
            call _string_copy_including_null

            lea rsi, [rel nine_spaces]
            call _string_copy_including_null


            mov rdi, [rel double_tab_string_object_address]
            lea rsi, [rel reusable_buffer_read]
            call _append_string_mystring

        .move_to_next_segment:
            pop r9
            movzx eax, word [r9 + 16]               ; 2 bytes reading 
            add r9, rax
            jmp .get_next_segment

        .done_constructing:

        cmp r14, 1
        jl .zeros_the_tab_and_return
        je .auto_complete
        jmp .print_muliple_files

        .zeros_the_tab_and_return:
            mov qword [rel tabs_times_pressed], 0
            jmp .cleanup_and_return

        .print_muliple_files:

        cmp [rel tabs_times_pressed], 2   ; if tabs not pressed atleast twice, return
        jl .cleanup_and_return

        mov qword [rel tabs_times_pressed], 2

        ; move the cursor to new line
        mov rax, 1
        mov rdi, 1
        lea rsi, [rel new_line]
        call _print


        ; print the line
        mov rax, [rsp + 8]                  ; len of string
        mov rdi, 1
        mov rsi, [rel double_tab_string_object_address]
        mov rsi, [rsi + 16]
        call _print

        ; move the cursor to new line
        mov rax, 1
        mov rdi, 1
        lea rsi, [rel new_line]
        call _print

        ;restore the cursor back
        call _print_prefix_line


        mov rax, [rel filled_size_input_buffer_len]
        mov rdi, 1
        mov rsi, [rel input_buffer_address]
        call _print

        ; right now the cursor in at end, but the value in cursor_idx is old

        mov r8, [rel filled_size_input_buffer_len]     ; index after final_byte

        .loop_restore_cur:

            cmp r8, [rel cursor_idx]
            je .cleanup_and_return

            mov rax, 1
            mov rdi, 1
            lea rsi, [rel move_cur_left]
            mov rdx, 3
            syscall

            dec r8
            jmp .loop_restore_cur


        .auto_complete:

        cmp [rel tabs_times_pressed], 1   ; if tabs pressed once, and can complete
        jne .cleanup_and_return

        .move_cursor_back_left:
            test r13, r13               ; len of the half word i have to autocomplete
            jz .print_auto_complete

            mov rax, 1
            mov rdi, 1
            lea rsi, [rel move_cur_left]
            mov rdx, 3
            syscall
            dec r13
            dec qword [rel cursor_idx]
            dec qword [rel filled_size_input_buffer_len]
            jmp .move_cursor_back_left

        .print_auto_complete:

        mov rdi, [rel double_tab_string_object_address]
        ; len is just word + 9spaces
        mov rax, [rdi + 8]          ; 8 is the offset for size of string
        sub rax, 9                  ; bec i add 9 spaces in the end
        

        ; copy the word in input buffer
        mov rdi, [rel input_buffer_address]
        add rdi, [rel filled_size_input_buffer_len]
        mov rsi, [rel double_tab_string_object_address]
        mov rsi, [rsi + 16]
        mov rcx, rax
        rep movsb

        add [rel cursor_idx], rax
        add [rel filled_size_input_buffer_len], rax

        mov rdi, 1
        mov rsi, [rel double_tab_string_object_address]
        mov rsi, [rsi + 16]
        call _print
        mov qword [rel tabs_times_pressed], 0

        .cleanup_and_return:
        ; destruct the string
        mov rdi, rsp
        call _destructor_mystring
        add rsp, 24
        mov qword [rel double_tab_string_object_address], 0

        jmp .read_key







    .interrupted:
        mov qword [rel input_interrupted], 1
        ret
    

    .get_more_buffer_size:

        mov rdi, [rel capacity_input_buffer_len]
        shl rdi, 1            ; basically 2*capacity_input_buffer_len
        call _malloc

        test rax, rax
        jl .handle_error_increasing_input_buffer_and_exit

        push rax
        ; copy old key_buffer data into new key_buffer
        mov rdi, rax                                    ; new address : Dest
        mov rsi, [rel input_buffer_address]             ; old address : Src
        mov rdx, [rel filled_size_input_buffer_len]                ; total bytes to copy
        call _mem_copy

        mov rdi, [rel input_buffer_address]                ; free old address memory
        call _free 

        pop rax
        mov [rel input_buffer_address], rax             ; update input address
        
        ; rn its: old_cap*2
        mov rax, [rel capacity_input_buffer_len]        ; update key_buffer_capacity
        shl rax, 1
        mov [rel capacity_input_buffer_len], rax

        ret


    .handle_error_reading_input:
        mov [rel error_code], rax
        call print_error_reading_input
        ret

    .handle_error_increasing_input_buffer_and_exit:
        mov [rel error_code], rax
        call print_error_increasing_input_mem
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code

    .handle_eof:
        ; print new line and exit
        mov rax, 1
        mov rdi, 1
        lea rsi, [rel new_line]
        call _print

        mov [rel exit_flag], 1
        ret

    .return:
        
        ; move cursor to end / after the last byte

        mov rax, [rel filled_size_input_buffer_len]
        sub rax, [rel cursor_idx]

        .move_cursor_end:
        test rax,  rax
        jz .move_cursor_down_colum1
        push rax

        mov rax, 1
        mov rdi, 1
        lea rsi, [rel move_cur_right]
        mov rdx, 3
        syscall

        pop rax
        dec rax
        jmp .move_cursor_end

        .move_cursor_down_colum1:
        
        mov rax, 1
        mov rdi, 1
        lea rsi, [rel new_line]
        mov rdx, 1

        syscall

        ;add_char_to_input_buffer

        ; i have atleast 8 bytes of free memory
        ; add char at end of input_buffer

        mov rax, [rel input_buffer_address]
        add rax, [rel filled_size_input_buffer_len]
        mov byte [rax], 0                        ; add a 0

        mov rdi, [rel input_buffer_address]      ; old command should not have \n in end
        call _add_cmd_into_history


        mov rax, [rel input_buffer_address]
        add rax, [rel filled_size_input_buffer_len]
        mov byte [rax], 0x0a                        ; replace the \n with 0

        inc qword [rel filled_size_input_buffer_len]
        inc rax
        mov byte [rax], 0                           ; add a NULL

        ret
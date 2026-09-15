%include "./dep/constants.inc"

section .data
    cursor_idx dq 0


section .bss
    key_buffer resb 10

section .rodata
    
    ;move_cur_home_pos db 27, "[H", 0
    ;move_cur_end_pos db 27, "[F", 0
    ;move_cur_left_space -> if ctrl+left_arrow -> i recv- > "[1;5D"
    ; ';' ->modifier 5D; = '5'->ctrl was pressed, 'D' -> left arrow key

    move_cur_up db 27, "[A", 0
    move_cur_down db 27, "[B", 0
    move_cur_right db 27, "[C", 0
    move_cur_left db 27, "[D", 0
    move_cur_next_line db 27, "[B", 27, "[G"  ; B -> down , G-> column 1
    erase_everything_after_cursor_including_cursor db 27, "[0K", 0


section .text

extern filled_size_input_buffer_len
extern input_interrupted
extern input_buffer_address
extern capacity_input_buffer_len
extern error_code
extern exit_status_code
extern _exit_with_status_code
extern new_line
extern exit_flag

extern termios
extern old_termios

extern _malloc
extern _free
extern _mem_copy
extern _print


extern print_error_reading_input
extern print_error_increasing_input_mem

global _read_input


_read_input:
    ; make a read call

    mov qword [rel filled_size_input_buffer_len], 0
    mov qword [rel input_interrupted], 0
    mov qword [rel cursor_idx], 0

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
            
        cmp byte [rel key_buffer], 0x04                ; non-conp mode ctrl+d = 0x04
        je .handle_eof


        cmp byte [rel key_buffer], 0x04         ; in non-cononical mode, this is ctrl+d
        je .handle_eof

        cmp byte [rel key_buffer], 27 
        je .escape_seq  

        cmp byte [rel key_buffer], 127          ; backspace
        je .handle_backspace

        cmp byte [rel key_buffer], 0x0a         ; TODO: move cursor to end of line before exit
        je .return


        ; this si for ctrl + keys, right now i just ignore them except 
        ; also , TABS is 0x09 so it is also ignored
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

        cmp byte [rel key_buffer], 'A'          ; arrow key up : ignore
        je .read_key

        cmp byte [rel key_buffer], 'B'          ; arrow key down : ignore
        je .read_key

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


        cmp byte [rel key_buffer], 'D'
        je .cursor_left_space

        cmp byte [rel key_buffer], 'C'
        je .cursor_right_space

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
        lea rsi, [rel move_cur_next_line]
        mov rdx, 6
        syscall
        ;add_char_to_input_buffer

        ; i have atleast 8 bytes of free memory
        ; add char at end of input_buffer
        mov rax, [rel input_buffer_address]
        add rax, [rel filled_size_input_buffer_len]
        mov byte [rax], 0x0a                        ; add a \n
        inc qword [rel filled_size_input_buffer_len]
        inc rax
        mov byte [rax], 0                           ; add a NULL

        ret
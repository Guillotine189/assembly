%include "../dependencies/mystring.inc"



section .bss
    ; DO not make this less than 32 bytes, i copy that many bytes as exit code status
    ; directly into the buffer without checking and expanding
    parse_buffer_capacity equ 2048
    parse_buffer resb parse_buffer_capacity
    number_buffer resb 32
    parse_string_object resb MYSTRING_OBJECT_SIZE

section .text

extern input_buffer_address
extern filled_size_input_buffer_len

extern _constructor_mystring
extern _destructor_mystring
extern _append_string_mystring

extern last_command_exit_code_ascii

extern _itoa
extern _print

extern _find_var_in_shell_env

extern _return_address_of_command_from_newest

extern _malloc
extern _free

global parse_string_object
global _parse_input


; i have a parse_string_object that stores the final parsed string
; i have a parse_buffer where i add bytes
; when that parse_buffer is full, i copy the contents into the parse_string_object,
; the parse_string_object grows dynamically


; TODO: "", empty argumets are ignored
; because its basically NULL followed by NULL in parser
_parse_input:
    push rbp
    mov rbp, rsp
    push r12        ; i don't have to save these registers in my program in this function
    push r13
    push r14
    push r15

    ; PARSER LOGIC FOR
    ; ["./program arg1  arg2 arg3\n"] -> ["./program\nagr1\narg2\n\n"]
    ; copy <space> as '\n'
    ; if '\' before ' ', copy this space instead of '\'
    ; double/single quotes: "Hello" -> Hello, "'hello'" -> 'hello'
    ; in dq/sq, '$' still expands the path var
    ; '$' followed by keywords
    ;           : '$?' -> resolbe into the exit status code of last command
    ; '\' -> ignored, '\\' -> '\' and so on
    ; do not copy "", ''
    ; RN -> one command followed by everything as arguments


    ; construct the string object
    mov rax, [rel filled_size_input_buffer_len]
    cmp rax, 1024
    jg .more_than_1024

    mov rax, 1024                   ; if original size is < 1024, allocate 1024
    jmp .create_parse_string_object

    .more_than_1024:
        add rax, 512            ; add to original len 512bytes, safe length

    .create_parse_string_object:
    lea rcx, [rel parse_string_object]
    mov qword [rcx + MYSTRING_CAPACITY_OFF], rax
    mov qword [rcx + MYSTRING_SIZE_OFF], 0
    mov qword [rcx + MYSTRING_POINTER_OFF], 0
    mov rdi, rcx
    call _constructor_mystring

    test rax, rax
    jl .error_creating_string_for_parsing


    xor r12, r12                        ; filled space of parse_buffer
    lea r13, [rel parse_buffer]         ; always contains the parse buffer
    xor r15, r15                        ; weather to print the parsed command or not
    xor rsi, rsi                        ; index for dst to copy bytes to
    xor r8, r8                          ; index for line traversal
    mov r9, [rel input_buffer_address]
    xor r10, r10                        ; weather inside double quotes or not
    xor r11, r11                        ; weather inside single quotes or not
    xor rcx, rcx                        ; weater last byte was '\' or not
    xor rdx, rdx                        ; weather last byte copied was \n or not
    .loop_till_new_line:
        cmp byte [r9 + r8], 0x0a            ; if the byte is \n
        je .buffer_parsed

        cmp byte [r9 + r8], 0x5c            ; '\' front slash
        je .front_slash_was_seen

        cmp byte [r9 + r8], 0x20            ; space
        je .handle_space

        cmp byte [r9 + r8], 0x22            ; for : double quotes ""
        je .handle_dq
        
        cmp byte [r9 + r8], 0x27            ; for : single quotes ''
        je .handle_sq

        cmp byte [r9 + r8], '!'
        je .check_and_replace_with_prev_command

        cmp byte [r9 + r8], '$'
        je .handle_expansion_variable

        xor rcx, rcx                        ; last byte was not '\'

        jmp .copy_byte_and_loop

        .front_slash_was_seen:

            test rcx, rcx
            jz .mark_as_seen_and_continue
            ; last byte was \, so now i can append this
            jmp .copy_byte_and_loop

            .mark_as_seen_and_continue:
            mov rcx, 1
            inc r8
            xor rdx,  rdx               ; this byte not not \n
            jmp .loop_till_new_line


        ; if any other char was passed, copy it to dst addr
        .copy_byte_and_loop:

            cmp r12, parse_buffer_capacity - 1   ; always leave 1 byte for null in the end
            je .call_copy_buffer_into_string
            jmp .copy_byte_to_buffer


            .copy_buffer_into_string:
                push rdx
                push rcx
                push r8
                push r9
                push r10
                push r11
                
                mov byte [r13 + rsi], 0         ; add 0 so i can add this into my string object
                lea rdi, [rel parse_string_object]
                lea rsi, [rel parse_buffer]
                call _append_string_mystring

                xor r12, r12                        ; len of buffer is zero
                xor rsi, rsi         ; move the index to starting address

                pop r11
                pop r10
                pop r9
                pop r8
                pop rcx
                pop rdx

                ret

            .call_copy_buffer_into_string:
                call .copy_buffer_into_string
                test rax, rax
                jl .error_appending_to_string  ; if error when adding, just exit parsing


            .copy_byte_to_buffer:
            mov al, [r9 + r8]
            mov [r13 + rsi], al
            inc r8
            inc rsi
            inc r12                               ; increase the size of parse buffer
            xor rdx, rdx                          ; last byte coped was not \n
            jmp .loop_till_new_line

        .handle_dq:
            xor rcx, rcx                        ; last byte was not \
            
            ; if i am inside dq already, mark it as not inside dq
            test r10, r10
            jg .i_was_inside_dq_not_anymore
            jmp .check_if_i_am_now_inside_sq

            .i_was_inside_dq_not_anymore:
                ; dont copy anything and move one
                inc r8
                xor r10, r10
                jmp .loop_till_new_line

            .check_if_i_am_now_inside_sq:
            ; if i am inside SQ, dont mark this as inside DQ
            test r11, r11
            jnz .copy_byte_and_loop ; i am inside SQ , let DQ be as it is
            
            ; since i was not inside dq or sq, i am now inside DQ
            ; dont copy anything
            mov r10, 1
            inc r8
            jmp .loop_till_new_line


        .handle_sq:
            xor rcx, rcx                        ; last byte was not \
            ; if i am inside sq already, mark it as not inside sq
            test r11, r11
            jnz .i_was_inside_sq
            jmp .check_if_i_am_now_inside_dq

            .i_was_inside_sq:
                ; dont copy anything
                inc r8
                xor r11, r11            ; not inside SQ anymore
                jmp .loop_till_new_line

            .check_if_i_am_now_inside_dq:
            ; if i am inside SQ, dont mark this as inside SQ
            test r10, r10
            jnz .copy_byte_and_loop ; i am inside DQ , let SQ be as it is
            
            ; since not inside dq, or sq, i am now inside SQ
            ; dont copy anything
            inc r8
            mov r11, 1
            jmp .loop_till_new_line


        .handle_space:
            test r10, r10
            jz .check_if_inside_single_quotes   ; if not inside DQ, cehck if inside SQ
            ; if inside DQ, just let this whitespace be
            jmp .copy_byte_and_loop
            

        .check_if_inside_single_quotes:
            test r11, r11
            jnz  .copy_byte_and_loop ; i am inside single quote
            
            ; now i am not inside DQ, or SQ

            ; check if last byte was '\', bec if it was, then allow this space
            test rcx, rcx
            jnz .last_byte_was_front_slash_allow_this_space

            test rdx, rdx
            jnz .last_copied_byte_was_new_line

            ; TODO: maybe i don't have enough space for addition
            cmp r12, parse_buffer_capacity - 1   ; always leave 1 byte for null in the end
            je .get_more_size_capacity
            jmp .replace_space_with_new_line

            .get_more_size_capacity:
                call .copy_buffer_into_string
                test rax, rax
                jl .error_appending_to_string  ; if error when adding, just exit parsing

            .replace_space_with_new_line:
            mov byte [r13 + rsi], 0x0a
            inc rsi
            inc r8
            inc r12
            mov rdx, 1                          ; last byte coped was \n
            jmp .loop_till_new_line

        .last_copied_byte_was_new_line:
            inc r8
            jmp .loop_till_new_line

        .last_byte_was_front_slash_allow_this_space:
            xor rcx, rcx                        ; last byte no longer \

            ; replace the slash with this space

            mov byte [r13 + rsi - 1], ' '           ; replace last dst byte wiht space
            inc r8                                  ; check next byte
            jmp .loop_till_new_line


        .handle_expansion_variable:

                xor rdx, rdx        ; last line was not \n
                xor rcx, rcx        ; last line was not \

                inc r8
                xor rax, rax
                push rax                    ; in stack i store the len of the expansion variable
            .loop_expansion_variable:
                

                cmp byte [r9 + r8], '_'      ; less than 48 not a valid char
                je .valid_expansion_variable_char

                cmp byte [r9 + r8], '0'      ; less than 48 not a valid char
                jb .not_valid_expansion_variable_char

                cmp byte [r9 + r8], '9'
                jbe .valid_expansion_variable_char
                            
                cmp byte [r9 + r8], 'A'
                jb .not_valid_expansion_variable_char

                cmp byte [r9 + r8], 'Z'
                jbe .valid_expansion_variable_char

                cmp byte [r9 + r8], 'a'
                jb .not_valid_expansion_variable_char

                cmp byte [r9 + r8], 'z'
                jbe .valid_expansion_variable_char


                jmp .not_valid_expansion_variable_char

                .valid_expansion_variable_char:
                    inc r8
                    inc qword [rsp]
                    jmp .loop_expansion_variable

                .not_valid_expansion_variable_char:
                
                cmp qword [rsp], 0     ; if valid len is not 0
                jne .check_and_expand_if_it_exists_in_env

                ; if valid length is zero and i immediately got into not_a_valid_char
                ; check the next byte
                jmp .check_if_exit_status

            .check_if_exit_status:
                cmp byte [r9 + r8], '?'
                je .replace_with_last_command_exit_code_status  

                ; if no valid length, "$:", i have to copy both "$" and ":"
                dec r8
                jmp .copy_byte_and_loop


            .replace_with_last_command_exit_code_status:
                ; copy old data before copying the exit code string
                call .copy_buffer_into_string
                
                ; the exit code is null terminated
                ; i can copy 32 bytes into the buffer directly
                ; the string will only append until NULL is found
                lea rdi, [rel parse_buffer]
                lea rsi, [rel last_command_exit_code_ascii]
                mov rcx, 32
                rep movsb

                mov rsi, 31         ; copy buffer into string adds a null terminator at rs
                ; copy exit code from buffer into string, and now buffer is reset
                call .copy_buffer_into_string
                inc r8                  ; i have replace $? with exit status code

                pop rax
                jmp .loop_till_new_line

            .check_and_expand_if_it_exists_in_env:
                ; copy old data before copying the exit code string
                call .copy_buffer_into_string

                ; r8 is pointing at byte after the last byte of env var
                ; eg: "$PATH?", r8 is index at "?", at the non valid char
                sub r8, [rsp]       ; r8 is at the index pointing to "P"

                push rdx
                push rcx
                push r8
                push r9
                push r10
                push r11
                
                lea rdi, [r9 + r8]          ; address of starting of var
                mov rsi, [rsp + 48]              ; len of variable, just added 6qword into stack
                call _find_var_in_shell_env

                test rax, rax
                jl .pop_and_continue

                lea rdi, [rel parse_string_object]
                mov rsi, rax
                call _append_string_mystring

                .pop_and_continue:

                ; start from the beginning 
                xor r12, r12
                xor rsi, rsi 

                pop r11
                pop r10
                pop r9
                pop r8
                pop rcx
                pop rdx

                .not_in_env:
                add r8, [rsp]
                pop rax
                jmp .loop_till_new_line


        .check_and_replace_with_prev_command:

            xor rdx, rdx        ; last byte not \n
            xor rcx, rcx        ; last byte not \

            ; i will now check the next byte directly
            cmp byte [r9 + r8 + 1], '!'      ; i know there is always a next byte available
            jne .copy_byte_and_loop         ; if only single time !, copy

            push rdx
            push rcx
            push r8
            push r9
            push r10
            push r11

            ; else now i have to replace the two with older command
            ; 1 is prev command (which was overwritten by latest), 2 is prev->prev or actual prev command
            mov rdi, 2
            call _return_address_of_command_from_newest

            test rax, rax
            jl .no_more_old_commands
            mov r14, rax                    ; save the address of old command

            ; copy old data into strign first, this function preserves all registers and reset r12, rsi
            call .copy_buffer_into_string

            ; copy the command into the string
            lea rdi, [rel parse_string_object]
            mov rsi, r14
            call _append_string_mystring

            mov r15, 1
            
            ; start from the beginning 
            xor r12, r12
            xor rsi, rsi 


            .no_more_old_commands:
            pop r11
            pop r10
            pop r9
            pop r8
            pop rcx
            pop rdx

            ; increase r8 by 2 positions because of double slash in input buffer
            add r8, 2

            xor rdx, rdx        ; last byte not \n
            xor rcx, rcx        ; last byte not \
            jmp .loop_till_new_line



    .buffer_parsed:
        ; the latest byte comapred was \n, i have to add a null char to copy my bufffer into string
        ; i made sure to have 1 byte left in the end always for this case
        ; so now i can add a null byte without worry
        ; copy the remaining 
        mov byte [r13 + rsi], 0                 ; add NULL so i can copy into string
        test r12, r12
        jnz .copy_final_data_into_string
        jmp .complete_string

        .copy_final_data_into_string:
        lea rdi, [rel parse_string_object]
        lea rsi, [rel parse_buffer]
        call _append_string_mystring
        test rax, rax
        jl .error_appending_to_string  ; if error when adding, just exit parsing
        

        .complete_string:
        ; i still need to add a \n
        xor rsi, rsi       ; next byte will copy from beginning from start in parse buffer
        mov byte [r13 + rsi], 0x0a                 ; copy the \n in to beginning of buffer
        inc rsi

        mov byte [r13 + rsi], 0x0a                 ; copy another the \n 
        inc rsi

        mov byte [r13 + rsi], 0                 ; add NULL after \n so i can append into string
        lea rdi, [rel parse_string_object]
        lea rsi, [rel parse_buffer]
        call _append_string_mystring
        test rax, rax
        jl .error_appending_to_string  ; if error when adding, just exit parsing
        

        jmp .cleanup_and_return

    
    .error_appending_to_string:
        lea rdi, [rel parse_string_object]
        call _destructor_mystring
        mov rax, -1
        jmp .return

    .cleanup_and_return:
        ; DO NOT DEALLOCATE THE STRING RIGHT NOW
        ; DEALLOCATE IT AFTER EXECUTION
        ; or dealllocate it just after failure to parse

        test r15, r15
        jz .no_printing_parsed_command

        call _print_parsed_buffer

        .no_printing_parsed_command:
        mov rax, 0
        jmp .return
    
    .error_creating_string_for_parsing:
        mov rax, -1
        jmp .return

    .return:
        pop r15
        pop r14
        pop r13
        pop r12
        mov rsp, rbp
        pop rbp
        ret


_print_parsed_buffer:
    push r12


    lea rax, [rel parse_string_object]

    mov rdi, [rax + MYSTRING_SIZE_OFF]
    call _malloc

    test rax, rax
    jl .failed_getting_memory

    mov r12, rax                    ; r12: stores the new memory address

    lea r9, [rel parse_string_object]
    mov r9, [r9 + MYSTRING_POINTER_OFF]
    xor r8, r8
    xor r10, r10                ; weather lasst byte was \n
    ; i literally have to undo my parsers work to print
    .loop_copy_new_line_as_space:

        cmp byte [r9 + r8], 0x0a
        je .check_and_replace_with_space

        xor r10, r10            ; mark this byte as not \n
        mov al, [r9 + r8]
        mov [r12 + r8], al         ; move the non \n byte into new memory
        jmp .loopback

        .check_and_replace_with_space:
            test r10, r10  ; if last byte was also \n, this is the end of parsed string
            jne .print_command

            mov r10, 1                      ; mark last byte was \n
            mov byte [r12 + r8], ' '        ; move the \n byte as space into new memory

        .loopback:
        inc r8
        jmp .loop_copy_new_line_as_space

    .print_command:

    dec r8              ; make it point to the second last \n
    mov byte [r12 + r8], 0x0a
    inc r8
    mov byte [r12 + r8], 0x0a
    inc r8

    mov rax, r8
    mov rdi, 1
    mov rsi, r12
    call _print

    mov rdi, r12
    call _free

    .failed_getting_memory:
    pop r12
    ret
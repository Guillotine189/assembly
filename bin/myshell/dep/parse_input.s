section .data
    parse_string_object_address dq 0


section .bss
    ; DO not make this less than 32 bytes, i copy that many bytes as exit code status
    ; directly into the buffer without checking and expanding
    parse_buffer_capacity equ 2048
    parse_buffer resb parse_buffer_capacity
    number_buffer resb 32


section .text

extern input_buffer_address
extern filled_size_input_buffer_len

extern _constructor_mystring
extern _destructor_mystring
extern _append_string_mystring

extern last_command_exit_code_ascii

extern _itoa

extern _find_var_in_env_var

global parse_string_object_address

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
    push r12
    push r13

    ; PARSER LOGIC FOR
    ; ["./program arg1  arg2 arg3\n"] -> ["./program\nagr1\narg2\n\n"]
    ; copy <space> as '\n'
    ; if '\' before ' ', copy this space instead of '\'
    ; double/single quotes: "Hello" -> Hello, "'hello'" -> 'hello'
    ; '$' followed by keywords
    ;           : '$?' -> resolbe into the exit status code of last command
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
    sub rsp, 24
    mov qword [rsp + 0], rax
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov rdi, rsp
    call _constructor_mystring

    test rax, rax
    jl .error_creating_string_for_parsing

    mov [rel parse_string_object_address], rsp


    lea r13, [rel parse_buffer]         ; always contains the parse buffer
    xor r12, r12                        ; length of parse buffer
    xor rdx, rdx                        ; weather last byte copied was \n or not
    xor rsi, rsi                        ; index for dst to copy bytes to
    xor r8, r8                          ; index for line traversal
    mov r9, [rel input_buffer_address]
    xor r10, r10                        ; weather inside double quotes or not
    xor r11, r11                        ; weather inside single quotes or not
    xor rcx, rcx                        ; weater last byte was '\' or not
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


        cmp byte [r9 + r8], '$'
        je .handle_expansion_variable

        xor rcx, rcx                        ; last byte was not '\'

        jmp .copy_byte_and_loop

        .front_slash_was_seen:
            mov rcx, 1

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
                mov rdi, [rel parse_string_object_address]
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

            .check_for_env_var:
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
                call _find_var_in_env_var

                test rax, rax
                jl .pop_and_continue

                mov rdi, [rel parse_string_object_address]
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
        mov rdi, [rel parse_string_object_address]
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
        mov rdi, [rel parse_string_object_address]
        lea rsi, [rel parse_buffer]
        call _append_string_mystring
        test rax, rax
        jl .error_appending_to_string  ; if error when adding, just exit parsing
        

        jmp .cleanup_and_return

    
    .error_appending_to_string:
        mov rdi, [rel parse_string_object_address]
        call _destructor_mystring
        mov rax, -1
        jmp .return

    .cleanup_and_return:
        mov rdi, [rel parse_string_object_address]
        call _destructor_mystring
        mov rax, 0
        jmp .return
    
    .error_creating_string_for_parsing:
        mov rax, -1
        jmp .return

    .return:
        add rsp, 24
        pop r13
        pop r12
        mov rsp, rbp
        pop rbp
        ret

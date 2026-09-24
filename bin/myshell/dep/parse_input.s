%include "../dependencies/mystring.inc"
%include "../dependencies/dynamicarray.inc"

section .rodata
    new_line db 0x0a, 0

section .bss
    ; DO not make this less than 32 bytes, i copy that many bytes as exit code status
    ; directly into the buffer without checking and expanding
    parse_buffer_capacity equ 2048
    parse_buffer resb parse_buffer_capacity
    number_buffer resb 32
    input_buffer_string_object resb MYSTRING_OBJECT_SIZE
    parsed_string_object resb MYSTRING_OBJECT_SIZE
    token_array resb DYNAMICARRAY_OBJECT_SIZE


section .text

extern input_buffer_address
extern filled_size_input_buffer_len

extern last_command_exit_code_ascii

extern _constructor_mystring
extern _destructor_mystring
extern _append_string_mystring
extern _append_bytes_mystring


extern _default_dynamic_array_constructor
extern _default_dynamic_array_destructor
extern _dynamic_array_add_element

extern _itoa
extern _print

extern _find_var_in_shell_env

extern _return_address_of_command_from_newest

extern _malloc
extern _free

extern _add_cmd_into_history

global parsed_string_object
global _parse_input


; i have a parsed_string_object that stores the final parsed string
; i have a parse_buffer where i add bytes
; when that parse_buffer is full, i copy the contents into the parsed_string_object,
; the parsed_string_object grows dynamically






; i can use r12-15 freely here
_expand_double_exclaimation:
        
    xor r15, r15                            ; mark this command as no printing

    ; create a string object because i didn't make the input buffer a string
    lea rcx, [rel input_buffer_string_object]
    mov rax, [rel filled_size_input_buffer_len]
    mov qword [rcx + MYSTRING_CAPACITY_OFF], rax
    mov qword [rcx + MYSTRING_SIZE_OFF], 0
    mov qword [rcx + MYSTRING_POINTER_OFF], 0
    mov rdi, rcx
    call _constructor_mystring

    test rax, rax
    jl .error_creating_string_for_input_buffer

    xor rsi, rsi                                    ; idx for traversal in parse_buffer
    xor r8, r8                                      ; idx for traversal in input buffer
    mov r9, [rel input_buffer_address] 
    xor r10, r10                                    ; weather i am inside DQ
    xor r11, r11                                    ; weather i am inside SQ
    xor r12, r12                                        ; len of parse buffer
    lea r13, [rel parse_buffer]
    .loop_till_new_line:

       cmp byte [r9 + r8], 0x22            ; for : double quotes ""
        je .handle_dq
        
        cmp byte [r9 + r8], 0x27            ; for : single quotes ''
        je .handle_sq

        cmp byte [r9 + r8], '!'
        je .check_and_replace_with_prev_command

        cmp byte [r9 + r8], 0x0a
        je .done

        jmp .copy_byte_and_loop


    .copy_byte_and_loop:

        cmp r12, parse_buffer_capacity - 1   ; always leave 1 byte for null in the end
        je .call_copy_buffer_into_string
        jmp .copy_byte_to_buffer


        .copy_buffer_into_string:
            push r11
            push r10
            push r9
            push r8
            
            mov byte [r13 + rsi], 0         ; add 0 so i can add this into my string object
            lea rdi, [rel input_buffer_string_object]
            lea rsi, [rel parse_buffer]
            call _append_string_mystring

            xor r12, r12                        ; len of parse buffer is zero
            xor rsi, rsi         ; move the index of writing byte in parse buffer to beginning

            pop r8
            pop r9
            pop r10
            pop r11
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
        jmp .loop_till_new_line

    .handle_dq:
        
        ; if i am inside dq already, mark it as not inside dq
        test r10, r10
        jg .i_was_inside_dq_not_anymore
        jmp .check_if_i_am_now_inside_sq

        .i_was_inside_dq_not_anymore:
            
            xor r10, r10
            jmp .copy_byte_and_loop

        .check_if_i_am_now_inside_sq:
        ; if i am inside SQ, dont mark this as inside DQ
        test r11, r11
        jnz .copy_byte_and_loop ; i am inside SQ , let DQ be as it is
        
        ; since i was not inside dq or sq, i am now inside DQ
        ; dont copy anything
        mov r10, 1
        jmp .copy_byte_and_loop


    .handle_sq:
        ; if i am inside sq already, mark it as not inside sq
        test r11, r11
        jnz .i_was_inside_sq
        jmp .check_if_i_am_now_inside_dq

        .i_was_inside_sq:
            
            xor r11, r11            ; not inside SQ anymore
            jmp .copy_byte_and_loop

        .check_if_i_am_now_inside_dq:
        ; if i am inside SQ, dont mark this as inside SQ
        test r10, r10
        jnz .copy_byte_and_loop ; i am inside DQ , let SQ be as it is
        
        mov r11, 1                      ; i am now inside sq
        jmp .copy_byte_and_loop

    .check_and_replace_with_prev_command:
        test r11, r11                   ; if inside single quotes treat this as a normal char
        jne .copy_byte_and_loop         ; if only single time !, copy

        cmp byte [r9 + r8 + 1], '!'      ; i know there is always a next byte available
        jne .copy_byte_and_loop         ; if only single time !, copy

        push rdx
        push r8
        push r9
        push r10
        push r11

        ; else now i have to replace the two with older command
        ; 1 is prev command
        mov rdi, 1
        call _return_address_of_command_from_newest

        test rax, rax
        jl .no_more_old_commands
        mov r14, rax                    ; save the address of old command

        ; copy old data into string first, this function preserves all registers and reset r12, rsi
        call .copy_buffer_into_string

        ; copy the command into the string
        lea rdi, [rel input_buffer_string_object]
        mov rsi, r14
        call _append_string_mystring

        ; start from the beginning 
        xor r12, r12                    ; parse_buffer len = 0
        xor rsi, rsi                    ; idx for writing in parse_buffer = 0


        .no_more_old_commands:
        mov r15, 1                  ; still have to mark this command as somethign that needs to be printed
        pop r11
        pop r10
        pop r9
        pop r8
        pop rdx

        ; increase r8 by 2 positions because of double slash in input buffer
        add r8, 2
        jmp .loop_till_new_line


    .done:
        ; i did not copy the \n, so currently i have scattered data in buffer and string object

        mov byte [r13 + rsi], 0    ; i know i have atleast 1 space left
        call .copy_buffer_into_string
        test rax, rax
        jl .error_appending_to_string
        ; current : i have moved "ls-la",0 into the input string object

        lea rdi, [rel input_buffer_string_object]
        mov rdi, [rdi + MYSTRING_POINTER_OFF]
        call _add_cmd_into_history

        ; i have to make string look like  : "ls -la\n", 0

        lea rdi, [rel input_buffer_string_object]
        lea rsi, [rel new_line]
        call _append_string_mystring

    .return_success:
        xor rax, rax
        ret

    .error_appending_to_string:
    .error_creating_string_for_input_buffer:
    .return_failure:
        mov rax, -1 
        ret



; TODO: "", empty argumets are ignored
; because its basically NULL followed by NULL in parser
_parse_input:
    push rbp
    mov rbp, rsp
    push r12        ; i don't have to save these registers in my program in this function
    push r13
    push r14
    push r15

    ; this function will also mark r15, weather to print the command or not
    call _expand_double_exclaimation
    test rax, rax
    jl .error_expanding_old_command    ; TODO: change give proper error



    ; PARSER LOGIC FOR
    ; ["./program arg1  arg2 arg3\n"] -> ["./programNULLagr1NULLarg2NULL\n\n"]
    ; copy <space> as '\n'
    ; if '\' before ' ', copy this space instead of '\'
    ; double/single quotes: "Hello" -> Hello, "'hello'" -> 'hello'
    ; in dq/sq, '$' still expands the path var
    ; '$' followed by keywords
    ;           : '$?' -> resolve into the exit status code of last command
    ;           : "$SHELL" -> expanded
    ; '\' -> ignored, '\\' -> '\' and so on
    ; do not copy "", ''
    ; RN -> one command followed by everything as arguments

    ; construct the string object
    lea rax, [rel input_buffer_string_object]
    mov rax, [rax + MYSTRING_SIZE_OFF]
    .create_parsed_string_object:
    lea rcx, [rel parsed_string_object]
    mov qword [rcx + MYSTRING_CAPACITY_OFF], rax
    mov qword [rcx + MYSTRING_SIZE_OFF], 0
    mov qword [rcx + MYSTRING_POINTER_OFF], 0
    mov rdi, rcx
    call _constructor_mystring

    test rax, rax
    jl .error_creating_string_for_parsing


    ;xor r15, r15                        ; weather to print the parsed command or not
    xor r12, r12                        ; length of parse_buffer
    lea r13, [rel parse_buffer]         ; always contains the parse buffer
    xor rsi, rsi                        ; index for dst to copy bytes to
    xor r8, r8                          ; index for line traversal
    lea r9, [rel input_buffer_string_object]
    mov r9, [r9 + MYSTRING_POINTER_OFF]
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
                mov rdx, rsi
                lea rdi, [rel parsed_string_object]
                lea rsi, [rel parse_buffer]
                call _append_bytes_mystring

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
            jnz .copy_byte_and_loop   ; if inside dq, just append this pace
            
            ; else check_if_inside_single_quotes
            test r11, r11
            jnz  .copy_byte_and_loop ; i am inside single quote
            
            ; now i am not inside DQ, or SQ

            ; check if last byte was '\', bec if it was, then allow this space
            test rcx, rcx
            jnz .last_byte_was_front_slash_allow_this_space

            test rdx, rdx                       ; if last byte was also a space/replaced with new line, dont copy another space
            jnz .last_copied_byte_was_new_line

            ; TODO: maybe i don't have enough space for addition
            cmp r12, parse_buffer_capacity - 1   ; always leave 1 byte for null in the end
            je .get_more_size_capacity
            jmp .replace_space_with_null

            .get_more_size_capacity:
                call .copy_buffer_into_string
                test rax, rax
                jl .error_appending_to_string  ; if error when adding, just exit parsing

            .replace_space_with_null:
            mov byte [r13 + rsi], 0
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

                ; if $ is inside single quotes, i do not expland
                test r11, r11
                jnz .copy_byte_and_loop
                ; if not inside sq -> expand

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
                mov rcx, 4                  ; 8*4=32bytes
                rep movsq

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

                lea rdi, [rel parsed_string_object]
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
        inc rsi

        .copy_final_data_into_string:
        mov rdx, rsi
        lea rdi, [rel parsed_string_object]
        lea rsi, [rel parse_buffer]
        call _append_bytes_mystring
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
        mov rdx, rsi
        lea rdi, [rel parsed_string_object]
        lea rsi, [rel parse_buffer]
        call _append_bytes_mystring
        test rax, rax
        jl .error_appending_to_string  ; if error when adding, just exit parsing
        

        jmp .cleanup_and_return

    
    .cleanup_and_return:

        ; DO NOT DEALLOCATE THE STRING RIGHT NOW
        ; DEALLOCATE IT AFTER EXECUTION
        ; or dealllocate it just after failure to parse
        test r15, r15
        jz .no_printing_parsed_command
        call _print_line_before_parsing

        .no_printing_parsed_command:
        ; for now i am deallocating this string object, but maybe in future don't do that to avoid calling malloc and free repeatedly
        ; maybe simply call 'clear' on this string, and reuse the same malloc space
        call _free_input_buffer_string_object
        mov rax, 0
        jmp .return_success



    .error_expanding_old_command:
        call _free_input_buffer_string_object
        jmp .return_failure

    .error_creating_string_for_parsing:
        call _free_input_buffer_string_object
        jmp .return_failure


    .error_appending_to_string:
        call _free_input_buffer_string_object
        call _free_parsed_buffer_string_object
        jmp .return_failure

    .return_success:
        pop r15
        pop r14
        pop r13
        pop r12
        xor rax, rax
        mov rsp, rbp
        pop rbp
        ret


    .return_failure:
        pop r15
        pop r14
        pop r13
        pop r12
        mov rax, -1
        mov rsp, rbp
        pop rbp
        ret

_print_line_before_parsing:
    lea rcx, [rel input_buffer_string_object]
    mov rax, [rcx + MYSTRING_SIZE_OFF]
    mov rdi, 1
    mov rsi, [rcx + MYSTRING_POINTER_OFF]
    call _print
    ret





; The parsed_string 
; for input "echo PATH=$SHELL !! | grep hello", where older command is "ls -la"
;"echo,NULL,PATH=/usr/bash/,NULL,ls,NULL,-la,NULL,|,NULL,grep,NULL,hello,NULL,\n\n,NULL"
_lexer:
    ; type enum
    TYPE_END                    equ 0
    TYPE_WORD                   equ 1
    TYPE_PIPE                   equ 2
    TYPE_REDIRECT_OUT           equ 3
    TYPE_REDIRECT_IN            equ 4
    TYPE_ENV_EXPANSION          equ 5
    TYPE_ENV_ASSSIGNMENT_KEY    equ 6
    TYPE_ENV_ASSSIGNMENT_VALUE  equ 6

    ; token array - > [ ([type][address]), ([type][address]) ]
    ; type is 1 byte, address is 8bytes
    ; if type is END, address is NULL

    lea rax, [rel token_array]
    mov qword [rax + DYNAMICARRAY_CAPACITY_OFF], 10
    mov qword [rax + DYNAMICARRAY_SIZE_OFF], 0
    mov qword [rax + DYNAMICARRAY_ELEMENT_SIZE_OFF], 9 ; 1byte for type, 8bytes for address
    mov qword [rax + DYNAMICARRAY_POINTER_OFF], 0
    mov rdi, rax
    call _default_dynamic_array_constructor

    test rax, rax
    jl .error_initializing_token_array

    ; seperate all tokens with a null balue
    ; identify what type of token it is, and append it's type and address to array



    .error_initializing_token_array:
        jmp .return_failure


    .return_failure:
        mov rax, -1
        ret

    .return_success:
        xor rax, rax
        ret




_free_input_buffer_string_object:
    lea rdi, [rel input_buffer_string_object]
    call _destructor_mystring
    ret

_free_parsed_buffer_string_object:
    lea rdi, [rel parsed_string_object]
    call _default_dynamic_array_destructor
    ret

_free_token_array:
    lea rdi, [rel token_array]
    call _default_dynamic_array_destructor
    ret

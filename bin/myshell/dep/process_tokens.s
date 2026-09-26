%include "./dep/constants.inc"
%include "../dependencies/mystring.inc"
%include "../dependencies/dynamicarray.inc"


section .rodata
    null_qword dq 0
    path db "PATH=", 0



section .text

extern command_argc_dynamic_array_object
extern command_argv_dynamic_array_object

extern _default_dynamic_array_constructor
extern _default_dynamic_array_destructor
extern _dynamic_array_add_element

extern parsed_string_object
extern address_command
extern shell_env_array_object

extern token_array

global _process_tokens

; type enum
TYPE_END                    equ 0
TYPE_WORD                   equ 1
TYPE_PIPE                   equ 2
TYPE_REDIRECT_OUT           equ 3
TYPE_REDIRECT_IN            equ 4
TYPE_ENV_ASSSIGNMENT        equ 5

; 8 bytes for type, 8 bytes for address, total 16 bytes
TOKEN_STRUCT_OBJECT_SIZE    equ 16
TOKEN_STRUCT_TYPE_OFF       equ 0
TOKEN_STRUCT_ADDRESS_OFF    equ 8






_process_tokens:
    mov rax,  -1
    ret


    ; expects ["./program\nagr1\narg2\n\n"]
    ; ["./programNULLagr1NULLarg2NULL\n"]
    ; RN -> 
    ; arg[0] -> command
    ; every other arg is arguments for,entire string is treated as a single line command


    ; create a dynamically growing array for argc, because i am running a single command
    ; i will use a pre defined variabe for this
    lea rax, [rel command_argc_dynamic_array_object]
    mov qword [rax + DYNAMICARRAY_CAPACITY_OFF], 7    ; expect 7 argument, more then enough
    mov qword [rax + DYNAMICARRAY_SIZE_OFF], 0
    mov qword [rax + DYNAMICARRAY_ELEMENT_SIZE_OFF], 8 ; i will be storing pointers to argc
    mov qword [rax + DYNAMICARRAY_POINTER_OFF], 0
    mov rdi, rax
    call _default_dynamic_array_constructor

    test rax, rax
    jl .error_creating_argc_array


    ; build array for envp
    lea rax, [rel command_argv_dynamic_array_object]
    mov qword [rax + DYNAMICARRAY_CAPACITY_OFF], 80    ; expect 80 env variables
    mov qword [rax + DYNAMICARRAY_SIZE_OFF], 0
    mov qword [rax + DYNAMICARRAY_ELEMENT_SIZE_OFF], 8 ; i will be storing pointers to argc
    mov qword [rax + DYNAMICARRAY_POINTER_OFF], 0
    mov rdi, rax
    call _default_dynamic_array_constructor

    test rax, rax
    jl .error_creating_argv_array


    xor r13, r13                      ; idx for looping
    lea r14, [rel parsed_string_object]
    mov r14, [r14 + MYSTRING_POINTER_OFF]
    xor r10, r10                   ; len of token
    xor r12, r12                    ; checks if last byte was \n
    xor r15, r15                    ; to check which arg is command
    .loop_till_double_new_line:

        cmp byte [r14 + r13], 0x0a      ; this means the token has just ended
        je .process_token

    .loopback:
        inc r13                      ; idx for looping
        inc r10                     ; len of token
        xor r12, r12                ; last byte was not \n
        jmp .loop_till_double_new_line

    .process_token:
        add r12, 1

        mov byte [r14 + r13], 0       ; over write the \n with NULL byte

        cmp r12, 2                  ; if 2 consicutive \n, end of line
        je .all_tokens_processed

        ; r10 len of token
        ; address at r13 - len of token = starting address of token

        test r10, r10                           ; len of token
        jz .token_with_no_len
        
        mov rdi, r14
        add rdi, r13
        sub rdi, r10                    ; addres of token

        push r10
        push rdi
        mov rsi, rsp    ; the address of the value is needed, thats why i gave address of rsp
        lea rdi, [rel command_argc_dynamic_array_object]
        call _dynamic_array_add_element
        pop rdi
        pop r10
        test rax, rax
        jl .error_appending_to_argc


        cmp r15, 0
        je .command_expected


        .token_with_no_len:
        inc r13
        xor r10, r10                            ; reset len of token
        jmp .loop_till_double_new_line
    .command_expected:
        ; save address of command
        mov [rel address_command], rdi
        xor r10, r10                            ; reset len of token
        inc r15
        inc r13
        jmp .loop_till_double_new_line

    .all_tokens_processed:
        ; add a NULL in the argc address array, [reusable_buffer user here]

        lea rsi, [rel null_qword]
        lea rdi, [rel command_argc_dynamic_array_object]
        call _dynamic_array_add_element

    .build_envp_array:

        ; build array for envp
        ; go through shell_env_array and add addresses of env that have exported = 1

        xor r12, r12                              ; which env struct am i checking
        lea r13, [rel shell_env_array_object]      ; r13 is the shell array object
        mov r14, [r13 + DYNAMICARRAY_POINTER_OFF]  ; r14 now points to string object array
        .loop_shell_env_array:

        cmp r12, [r13 + DYNAMICARRAY_SIZE_OFF]
        je .done_adding_shell_env_var


        mov rax, r12
        mov rcx, MYSTRING_OBJECT_SIZE
        mul rcx

        ; dont care about the buffer overflow, probably will never happen
        ; rax now has the offset for which string object to check

        mov rcx, [r13 + DYNAMICARRAY_POINTER_OFF]
        lea rsi, [rcx + rax]   ; rsi now points to the string object
        
        lea rsi, [rsi + MYSTRING_POINTER_OFF]
        ; rsi has the address which points to the address of string
        ; i want to copy the address of string inside array. so i need to give the address of address of string
        lea rdi, [rel command_argv_dynamic_array_object]
        call _dynamic_array_add_element

        test rax, rax
        jl .error_appending_to_argv

        
        inc r12
        jmp .loop_shell_env_array


    .done_adding_shell_env_var:
    ; add a null address after them
    ; r13 is shell_env_array_object
    lea rdi, [rel command_argv_dynamic_array_object]
    lea rsi, [rel null_qword]
    call _dynamic_array_add_element

    .return:
        ret

    .error_appending_to_argv:
        lea rdi, [rel command_argv_dynamic_array_object]
        call _default_dynamic_array_destructor

    .error_creating_argv_array:
        ; Destroy argc array and exit 

    .error_appending_to_argc:
        lea rdi, [rel command_argc_dynamic_array_object]
        call _default_dynamic_array_destructor

    .error_creating_argc_array:
        mov rax, -1
        ret


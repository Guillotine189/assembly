%include "./dep/constants.inc"
%include "../dependencies/mystring.inc"
%include "../dependencies/dynamicarray.inc"

global command_array
section .bss
    command_array resb DYNAMICARRAY_SIZE_OFF

section .rodata
    null_qword dq 0
    path db "PATH=", 0



section .text

; error
extern error_code
extern print_error_initializing_command_array
extern print_error_initializing_argv_array
extern print_error_initializing_envp_array
extern print_error_redirect_in_expects_word
extern print_error_redirect_out_expects_word
extern print_error_adding_to_argc
extern print_error_adding_custom_env_var
extern print_error_adding_command_stuct
extern print_error_invalid_token_after_pipe
extern print_error_command_name_not_found_for_last_command
extern print_error_unknow_token


extern token_array

global _process_token_generate_commands
global _cleanup_process_token_generate_commands_on_success

; token type enum
TOKEN_TYPE_END                    equ 0
TOKEN_TYPE_WORD                   equ 1
TOKEN_TYPE_PIPE                   equ 2
TOKEN_TYPE_REDIRECT_OUT           equ 3
TOKEN_TYPE_REDIRECT_IN            equ 4
TOKEN_TYPE_ENV_ASSSIGNMENT        equ 5

; 8 bytes for type, 8 bytes for address
TOKEN_STRUCT_OBJECT_SIZE    equ 16
TOKEN_STRUCT_TYPE_OFF       equ 0
TOKEN_STRUCT_ADDRESS_OFF    equ 8

; > can be a [file, /dev/null, named_pipe, etc] All can be just opened with open(o_wonly, o_create, O_truncate)
REDIRECT_STRUCT_SIZE            equ 16
REDIRECT_STRUCT_TYPE_OFF        equ 0
REDIRECT_STRUCT_ADDRESS_OFF     equ 8

REDIRECT_TYPE_DEFAULT           equ 0
REDIRECT_TYPE_PIPE              equ 1
REDIRECT_TYPE_OTHER             equ 2


COMMAND_STRUCT_SIZE             equ 104
COMMAND_STRUCT_NAME_OFF         equ 0
COMMAND_STRUCT_ARGV_OBJ_OFF     equ 8
COMMAND_STRUCT_ENVP_OBJ_OFF     equ COMMAND_STRUCT_ARGV_OBJ_OFF + DYNAMICARRAY_OBJECT_SIZE
COMMAND_STRUCT_RIN_STRUCT_OFF   equ COMMAND_STRUCT_ENVP_OBJ_OFF + DYNAMICARRAY_OBJECT_SIZE
COMMAND_STRUCT_ROUT_STRUCT_OFF  equ COMMAND_STRUCT_RIN_STRUCT_OFF + REDIRECT_STRUCT_SIZE

; command struct: 
; [address of command name]     8bytes
; [argv_array_object_address]   32bytes
; [envp_array_object_address]   32bytes
; [redirect_in_struct]          16bytes
; [redirect_out_struct]         16bytes
;                        TOTAL: 104bytes

; argv_array_object -> the final argv that needs to be given

; envp_array_object -> only the EXTRA TEMP ENVP PROVIDED DURING EXECUTION.
; That means, i have to add the shell envp into this before giving it to execve

; redirect_struct:
; [TYPE]        : redirect_other, pipe, default
; [LOCATIION]   : if other: address of location, else NULL

; redirection in is alwasys from 1 source so thats fine
; right now only 1 redirection output is allowed, or you will overwrite which to redirect out to

_cleanup_process_token_generate_commands_on_success:
    call _free_command_array
    ret

_process_token_generate_commands:
    push rbp
    mov rbp ,rsp
    push r12
    push r13
    push r14
    push r15

    
    ; initialize the command array object
    lea rdi, [rel command_array]
    mov qword [rdi + DYNAMICARRAY_CAPACITY_OFF], 3          ; ask for space of 3 commmands
    mov qword [rdi + DYNAMICARRAY_SIZE_OFF], 0              ; doesn't matter will be initialzed
    mov qword [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF], COMMAND_STRUCT_SIZE
    mov qword [rdi + DYNAMICARRAY_POINTER_OFF], 0           ; doesn't matter will be initialzed
    call _default_dynamic_array_constructor

    test rax, rax
    jl .error_initializing_command_array
    
    
    ; reserve space for command struct on stack
    sub rsp, COMMAND_STRUCT_SIZE


    ; build argc array object
    lea rdi, [rsp + COMMAND_STRUCT_ARGV_OBJ_OFF]
    mov qword [rdi + DYNAMICARRAY_CAPACITY_OFF], 7    ; expect 7 argument, more then enough
    mov qword [rdi + DYNAMICARRAY_SIZE_OFF], 0
    mov qword [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF], 8 ; i will be storing pointers to argc
    mov qword [rdi + DYNAMICARRAY_POINTER_OFF], 0
    call _default_dynamic_array_constructor

    test rax, rax
    jl .error_initializing_argv_array


    ; build array object for envp
    lea rdi, [rsp + COMMAND_STRUCT_ENVP_OBJ_OFF]
    mov qword [rdi + DYNAMICARRAY_CAPACITY_OFF], 80    ; expect 80 env variables
    mov qword [rdi + DYNAMICARRAY_SIZE_OFF], 0
    mov qword [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF], 8 ; i will be storing pointers to argc
    mov qword [rdi + DYNAMICARRAY_POINTER_OFF], 0
    call _default_dynamic_array_constructor

    test rax, rax
    jl .error_initializing_envp_array


    lea r12, [rel token_array]                          ; the address of token_array_aobject
    mov r12, [r12 + DYNAMICARRAY_POINTER_OFF]           ; r12: has the address of array of tokens
    xor r13, r13                                        ; r13: the index of token being processed
    xor r14, r14                                        ; r14: weather the command was seen or not, 0-> no, 1->yes
    xor r15, r15                                        ; r15: weather redirect out was seen or not
    ; if [ls > output.txt | grep file.txt] -> '>' has precedence over '|'. 
    ; That's why if > is present, redirection through | is ignored.
    ; same with redirect in, "<" take priority over pipe


    ; mark the redirect out and redirect in as default
    lea rax, [rsp + COMMAND_STRUCT_ROUT_STRUCT_OFF]         ; address of redirect out struct
    mov qword [rax + REDIRECT_STRUCT_TYPE_OFF], REDIRECT_TYPE_DEFAULT
    mov qword [rax + REDIRECT_STRUCT_ADDRESS_OFF], 0

    lea rax, [rsp + COMMAND_STRUCT_RIN_STRUCT_OFF]         ; address of redirect in struct
    mov qword [rax + REDIRECT_STRUCT_TYPE_OFF], REDIRECT_TYPE_DEFAULT
    mov qword [rax + REDIRECT_STRUCT_ADDRESS_OFF], 0


    .loop_token_struct:
    ; r12 has the address of array that holds token
    ; r13 the index of token beign processed

    lea rax, TOKEN_STRUCT_OBJECT_SIZE
    mov rcx, r13
    mul rcx

    add rax, r12                            ; rax: the address current of token struct

    mov rcx, [rax + TOKEN_STRUCT_TYPE_OFF]              ; rcx: the type of token

    cmp rcx, TOKEN_TYPE_WORD
    je .handle_word

    cmp rcx, TOKEN_TYPE_END
    je .end_of_tokens

    cmp rcx, TOKEN_TYPE_PIPE
    je .handle_pipe

    cmp rcx, TOKEN_TYPE_REDIRECT_OUT
    je .handle_redirect_out

    cmp rcx, TOKEN_TYPE_REDIRECT_IN
    je .handle_redirect_in

    cmp rcx, TOKEN_TYPE_ENV_ASSSIGNMENT
    je .handle_env_assignment
    ; tODO: ENV ASSIGNAMENT AFTER 1st are wrong

    jmp .error_unknow_token


    .handle_redirect_out:
        ; r13: index for token
        ; rax: the address of current token struct

        ; check if the next token a word, if not, return failure
        lea rdx, [rax + TOKEN_STRUCT_OBJECT_SIZE]     ; rdx : the address of next token struct
        cmp qword [rdx + TOKEN_STRUCT_TYPE_OFF], TOKEN_TYPE_WORD
        jne .error_redirect_out_expects_word

        ; if the next token is a word, add it to REDIRECT_OUT_STRUCT. MARK REDIRECT_SEEN as true
        mov r15, 1                      ; mark redirect seen as true

        ; put the redirect out struct into the command array
        mov rdx, [rdx + TOKEN_STRUCT_ADDRESS_OFF]       ; rdx: value of token(which is address)
        
        ; fill the actual redirect struct part of command struct
        lea rdi, [rsp + COMMAND_STRUCT_ROUT_STRUCT_OFF]        ; rdi: the address of redirect_out struct in command struct
        mov qword [rdi + REDIRECT_STRUCT_TYPE_OFF], REDIRECT_TYPE_OTHER
        mov [rdi + REDIRECT_STRUCT_ADDRESS_OFF], rdx

        ; because i dont have to check next token, increase r13
        inc r13
        jmp .process_next_token


    .handle_redirect_in:
        ; almost same as redirect out

        ; next token must be word
        lea rdx, [rax + TOKEN_STRUCT_OBJECT_SIZE]
        cmp qword [rdx + TOKEN_STRUCT_TYPE_OFF], TOKEN_TYPE_WORD
        jne .error_redirect_in_expects_word

        ; next token's address
        mov rdx, [rdx + TOKEN_STRUCT_ADDRESS_OFF]

        ; command.redirect_in
        lea rdi, [rsp + COMMAND_STRUCT_RIN_STRUCT_OFF]

        mov qword [rdi + REDIRECT_STRUCT_TYPE_OFF], REDIRECT_TYPE_OTHER
        mov qword [rdi + REDIRECT_STRUCT_ADDRESS_OFF], rdx

        inc r13
        jmp .process_next_token


    .handle_word:
        ; r13: index for token
        ; rax: the address of current token struct

        ; else check if command has been seen, if not mark it as command else add as an argument
        test r14, r14
        jne .add_as_argument

        mov r14, 1
        ; add as command
        ; find the address of command
        mov rdx, [rax + TOKEN_STRUCT_ADDRESS_OFF]       ; rdx: the address of command name
        mov [rsp + COMMAND_STRUCT_NAME_OFF], rdx        ; the address of command has been set inside command struct

        ; check if the command is

        .add_as_argument:
        lea rdi, [rsp + COMMAND_STRUCT_ARGV_OBJ_OFF]       ; rdi: the address of argc arr object for current command
        lea rsi, [rax + TOKEN_STRUCT_ADDRESS_OFF]       ; rsi: the address of address of command name
        call _dynamic_array_add_element


        test rax, rax
        jl .error_adding_to_argc
        jmp .process_next_token



    .handle_env_assignment:
        ; rax: the address of current token struct

        ; TODO: CHECK IF THE TOKEN ALREADY EXISTS inside the, eg doo=bar foo=bar 
        ; should result in foo=bar2 not both

        ; add the value inside token to envp array object
        lea rdi, [rsp + COMMAND_STRUCT_ENVP_OBJ_OFF]       ; rdi: address of envp array obj
        lea rsi, [rax + TOKEN_STRUCT_ADDRESS_OFF]       ; rsi: the address of address of value of envp_var
        call _dynamic_array_add_element

        test rax, rax
        jl .error_adding_custom_env_var

        jmp .process_next_token


    .handle_pipe:
        ; rax: the address of current token struct

        ; check if next token exists or not, if not then error
        lea rdi, [rax + TOKEN_STRUCT_OBJECT_SIZE] ; rdi: the address of next8 token struct
        mov rdi, [rdi + TOKEN_STRUCT_TYPE_OFF]

        cmp rdi, TOKEN_TYPE_END
        je .error_invalid_token_after_pipe

        ; mark redirect out as pipe, or not if > already did it
        test r15, r15                               ; weather redirect out was there
        jne .go_to_next_command

        lea rdi, [rsp + COMMAND_STRUCT_ROUT_STRUCT_OFF]  ; rdi: address of redirect out struct
        mov [rdi + REDIRECT_STRUCT_TYPE_OFF], REDIRECT_TYPE_PIPE
        mov qword [rdi + REDIRECT_STRUCT_ADDRESS_OFF], 0       ; for redirect to pipe, address is null
        inc r13
        jmp .go_to_next_command

    .process_next_token:
        inc r13                         ; the index for token
        jmp .loop_token_struct

    .go_to_next_command:
    ; since i encountered a  pipe, i now have to do this all again
    ;but the redirect in for next command starts from REDIRECT_TYPE_PIPE, not REDIRECT_TYPE_DEFAULT

    test r14, r14
    je .error_command_name_not_found_for_last_command

    ; Add aNULL to argc but not to envp array
    lea rdi, [rsp + COMMAND_STRUCT_ARGV_OBJ_OFF]
    lea rsi, [rel null_qword]
    call _dynamic_array_add_element

    ; lea rdi, [rsp + COMMAND_STRUCT_ENVP_OBJ_OFF]
    ; lea rsi, [rel null_qword]
    ; call _dynamic_array_add_element


    ; add_command_struct_into_array
    lea rdi, [rel command_array]
    mov rsi, rsp                    ; rdi : the address of command struct inside stack
    call _dynamic_array_add_element

    test rax, rax
    jl .error_adding_command_stuct

    .build_new_command:

    ; initialize argc array object
    lea rdi, [rsp + COMMAND_STRUCT_ARGV_OBJ_OFF]
    mov qword [rdi + DYNAMICARRAY_CAPACITY_OFF], 7    ; expect 7 argument, more then enough
    mov qword [rdi + DYNAMICARRAY_SIZE_OFF], 0
    mov qword [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF], 8 ; i will be storing pointers to argc
    mov qword [rdi + DYNAMICARRAY_POINTER_OFF], 0
    call _default_dynamic_array_constructor

    test rax, rax
    jl .error_initializing_argv_array


    ; initialize array object for envp
    lea rdi, [rsp + COMMAND_STRUCT_ENVP_OBJ_OFF]
    mov qword [rdi + DYNAMICARRAY_CAPACITY_OFF], 80    ; expect 80 env variables
    mov qword [rdi + DYNAMICARRAY_SIZE_OFF], 0
    mov qword [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF], 8 ; i will be storing pointers to argc
    mov qword [rdi + DYNAMICARRAY_POINTER_OFF], 0
    call _default_dynamic_array_constructor

    test rax, rax
    jl .error_initializing_envp_array

    ;reset all values
    xor r14, r14                                        ; r14: weather the command was seen or not, 0-> no, 1->yes
    xor r15, r15                                        ; r15: weather redirect out was seen or not
    ; if [ls > output.txt | grep file.txt] -> '>' has precedence over '|'. 
    ; That's why if > is present, redirection through | is ignored.
    ; same with redirect in, "<" take priority over pipe


    ;redirect in for next command starts from REDIRECT_TYPE_PIPE, not REDIRECT_TYPE_DEFAULT
    lea rax, [rsp + COMMAND_STRUCT_RIN_STRUCT_OFF]         ; address of redirect in struct
    mov qword [rax + REDIRECT_STRUCT_TYPE_OFF], REDIRECT_TYPE_PIPE
    mov qword [rax + REDIRECT_STRUCT_ADDRESS_OFF], 0

    ; mark the redirect out and redirect in as default
    lea rax, [rsp + COMMAND_STRUCT_ROUT_STRUCT_OFF]         ; address of redirect out struct
    mov qword [rax + REDIRECT_STRUCT_TYPE_OFF], REDIRECT_TYPE_DEFAULT
    mov qword [rax + REDIRECT_STRUCT_ADDRESS_OFF], 0

    jmp .loop_token_struct



    .end_of_tokens:

    test r14, r14
    je .error_command_name_not_found_for_last_command

    ; Add aNULL to argc but not to envp array
    lea rdi, [rsp + COMMAND_STRUCT_ARGV_OBJ_OFF]
    lea rsi, [rel null_qword]
    call _dynamic_array_add_element

    ; lea rdi, [rsp + COMMAND_STRUCT_ENVP_OBJ_OFF]
    ; lea rsi, [rel null_qword]
    ; call _dynamic_array_add_element

    ; add_command_struct_into_array
    lea rdi, [rel command_array]
    mov rsi, rsp                    ; rdi : the address of command struct inside stack
    call _dynamic_array_add_element

    ; remove_from_stack
    add rsp, COMMAND_STRUCT_SIZE                ; remove command struct

    test rax, rax
    jl .error_adding_command_stuct

    ; CHANGE THIS TO RETURN_SUCCESS
    jmp .return_success                     



    .error_initializing_command_array:
        mov [rel error_code], rax
        call print_error_initializing_command_array
        jmp .clean_up_current_stack_and_command_array

    .error_initializing_argv_array:
        mov [rel error_code], rax
        call print_error_initializing_argv_array

        add rsp, COMMAND_STRUCT_SIZE
        call _free_command_array
        jmp .clean_up_current_stack_and_command_array

    .error_initializing_envp_array:

        mov [rel error_code], rax
        call print_error_initializing_envp_array

        lea rdi, [rsp + COMMAND_STRUCT_ARGV_OBJ_OFF]
        call _default_dynamic_array_destructor

        add rsp, COMMAND_STRUCT_SIZE
        call _free_command_array
        jmp .clean_up_current_stack_and_command_array

    .error_redirect_in_expects_word:
        mov [rel error_code], rax
        call print_error_redirect_in_expects_word
        jmp .clean_up_current_stack_and_command_array

    .error_redirect_out_expects_word:
        mov [rel error_code], rax
        call print_error_redirect_out_expects_word
        jmp .clean_up_current_stack_and_command_array

    .error_adding_to_argc:
        mov [rel error_code], rax
        call print_error_adding_to_argc
        jmp .clean_up_current_stack_and_command_array

    .error_adding_custom_env_var:
        mov [rel error_code], rax
        call print_error_adding_custom_env_var
        jmp .clean_up_current_stack_and_command_array

    .error_adding_command_stuct:
        mov [rel error_code], rax
        call print_error_adding_command_stuct
        jmp .clean_up_current_stack_and_command_array

    .error_invalid_token_after_pipe:
        mov [rel error_code], rax
        call print_error_invalid_token_after_pipe
        jmp .clean_up_current_stack_and_command_array

    .error_command_name_not_found_for_last_command:
        mov [rel error_code], rax
        call print_error_command_name_not_found_for_last_command
        jmp .clean_up_current_stack_and_command_array
    .error_unknow_token:
        mov [rel error_code], rax
        call print_error_unknow_token
        jmp .clean_up_current_stack_and_command_array


    .clean_up_current_stack_and_command_array:
        ; clean up the argc array object
        lea rdi, [rsp + COMMAND_STRUCT_ARGV_OBJ_OFF]
        call _default_dynamic_array_destructor

        ; clean up the envp array object
        lea rdi, [rsp + COMMAND_STRUCT_ENVP_OBJ_OFF]
        call _default_dynamic_array_destructor

        ; remove the command struct from stack
        add rsp, COMMAND_STRUCT_SIZE

        ; free all the other commands that were made during this process
        call _free_command_array
        jmp .return_failure

    .return_failure:
        pop r15
        pop r14
        pop r13
        pop r12
        mov rsp, rbp
        pop rbp
        mov rax, -1
        ret

    .return_success:
        pop r15
        pop r14
        pop r13
        pop r12
        mov rsp, rbp
        pop rbp
        xor rax, rax
        ret


; this function frees the array object inside the individual command_struct, then
; free the command array manually by calling default_destructor
_free_command_array:
    push r12
    push r13
    push r14
    push r15
    
    lea r12, [rel command_array]
    mov r13, [r12 + DYNAMICARRAY_POINTER_OFF]           ; r13: the address of 1st command, the beginning of actual array
    mov r12, [r12 + DYNAMICARRAY_SIZE_OFF]              ; r12: commands array size

    xor r14, r14                                        ; r14: idx for looping inside command array

    ; now for every command, i have ; command struct: 
    ; [address of command name]     8bytes          ; do nothing
    ; [argv_array_object_address]   32bytes         ; call destructor on this
    ; [envp_array_object_address]   32bytes         ; call destructor on this
    ; [redirect_in_struct]          16bytes          ; do nothing
    ; [redirect_out_struct]         16bytes          ; do nothing


    .loop_free_inside_objects:
        cmp r14, r12                        ; if idx = size => break
        je .free_command_array

        ; get the next command
        lea rdi, [rel command_array]
        mov rsi, r14
        call _dynamic_array_get_element_address         

        test rax, rax
        jl .error_getting_next_command

        ; rax: has the address of next command struct
        mov r15, rax


        ; free argv array obj for this command
        lea rdi, [r15 + COMMAND_STRUCT_ARGV_OBJ_OFF]
        call _default_dynamic_array_destructor
        ; todo : handle error

        ; free envp array obj for this command
        lea rdi, [r15 + COMMAND_STRUCT_ENVP_OBJ_OFF]
        call _default_dynamic_array_destructor
        ; todo : handle error


        inc r14
        jmp .loop_free_inside_objects



    .free_command_array:
        ; now free the commmand_array itself. 

        ; TODO: in future, don't free this array, reuse it. Only clear it and move on.
        ; No need to allocate, deallocate this again and again when i will be using it for executing commands everytime.


        lea rdi, [rel command_array]
        call _dynamic_array_clear

        lea rdi, [rel command_array]
        call _default_dynamic_array_destructor
        ; todo : handle error

        jmp .return_success


    .error_getting_next_command:
        ; TODO: print proper error
        jmp .return_failure



    .return_success:
        pop r15
        pop r14
        pop r13
        pop r12
        xor rax, rax
        ret

    .return_failure:
        pop r15
        pop r14
        pop r13
        pop r12
        mov rax, -1
        ret

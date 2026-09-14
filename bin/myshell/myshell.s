global error_code
section .data

    myshell_line db "myShell", 0
    myshell_line_len equ $ - myshell_line

    capacity_input_buffer_len dq 4096
    filled_size_input_buffer_len dq 0               ; includes \n

    capacity_parse_buffer_address dq 0              ; DO NOT CHANGE dq 0, i use it in code
    capacity_parse_buffer_len dq 0
    filled_size_parse_buffer_len dq 0


    address_command dq 1
    address_argc_address_array dq 1
    address_envp_address_array dq 1

    og_envp_stack_array_address dq 1

    cursor_position dq 0

    input_interrupted dq 0

    error_input_init_memory db "myShell: Error allocating memory for input buffer",0
    error_input_init_memory_len equ $ - error_input_init_memory

    error_getting_parse_memory db "myShell: Error getting memory for parse line", 0
    error_getting_parse_memory_len equ $ - error_getting_parse_memory

    error_reading_input db "myShell: Error reading input", 0
    error_reading_input_len equ $ - error_reading_input

    error_increasing_input_buffer_mem db "myShell: Error increasing input buffer storage", 0
    error_increasing_input_buffer_mem_len equ $ - error_increasing_input_buffer_mem

    error_getting_cwd db "myShell: Error getting cwd",0
    error_getting_cwd_len equ $ - error_getting_cwd

    error_overriding_custom_handler db "myShell: Error overriding custom handler: ", 0
    error_overriding_custom_handler_len equ $ - error_overriding_custom_handler

    error_forking db "myShell: Error forking",0
    error_forking_len equ $ - error_forking

    error_executing_process db "myShell: Error executing: ", 0
    error_executing_process_len equ $ - error_executing_process


    exit_status_code dq 0
    error_code dq 0
    exit_flag dq 0


    align 8
    sigint_idle_struct:
        dq _sigint_myshell_handler                         ; address of handler
        dq SA_RESTORER                          ; for the flags
        dq _sigint_myshell_restorer                        ; address of restorer
        times 16 dq 0                       ; 16 times dq = 16x8 = 128bytes for maskA

    align 8
    sigtstp_idle_struct:
        dq _sigtstp_myshell_handler                         ; address of handler
        dq SA_RESTORER                         ; for the flags
        dq _sigtstp_myshell_restorer                        ; address of restorer
        times 16 dq 0                       ; 16 times dq = 16x8 = 128bytes for maskA



    ;-------------------------built in commands-----------------------

    cd db "cd",0
    pwd db "pwd",0




section .rodata

    ; modern ANSI/VT-compatible terminal
    ; like GNOME Terminal, Konsole, Kitty, Alacritty

    cursor_home db 0x1b, '[H'          ; move cursor to the left most part of terminal
    cursor_home_len equ $ - cursor_home
    clear_screen db 0x1b, '[2J'      ; clear the screen
    clear_screen_len equ $ - clear_screen
    clear_scrollback db 0x1b, '[3J'   ; clear the scrollable part of the screen as well
    clear_scrollback_len equ $ - clear_scrollback

    semicolon db ":" , 0
    dollar_sign_with_space db "$ ", 0
    new_line db 0x0a

    colour_len equ 5
    colour_reset_len equ 4

    colour_reset    db 27, "[0m", 0
    colour_black    db 27, "[30m", 0     
    colour_red      db 27, "[31m", 0
    colour_green    db 27, "[32m", 0
    colour_yellow   db 27, "[33m", 0
    colour_blue     db 27, "[34m", 0
    colour_magenta  db 27, "[35m", 0
    colour_cyan     db 27, "[36m", 0
    colour_white    db 27, "[37m", 0

    colour_bright_black   db 27, "[90m", 0
    colour_bright_red     db 27, "[91m", 0
    colour_bright_green   db 27, "[92m", 0
    colour_bright_yellow  db 27, "[93m", 0
    colour_bright_blue    db 27, "[94m", 0
    colour_bright_magenta db 27, "[95m", 0
    colour_bright_cyan    db 27, "[96m", 0
    colour_bright_white   db 27, "[97m", 0

    style_reset             db 27, "[0m", 0
    style_bold              db 27, "[1m", 0
    style_italic            db 27, "[3m", 0
    style_underline         db 27, "[4m", 0


global curr_cwd_len
global curr_cwd
section .bss
    input_buffer_address resq 1         ; address from malloc
    reusable_buffer resb 4096

    curr_cwd resb 4096
    curr_cwd_address resb 8                 ;TODO: maybe remove it later
    curr_cwd_len resq 1

    prefix_line resb 4096
    prefix_line_len resq 1

    error_custom_handler_number resq 1




sys_read            equ 0   
sys_write           equ 1   
sys_open            equ 2   
sys_close           equ 3   
sys_stat            equ 4   
sys_rt_sigaction    equ 13  
sys_rt_sigreturn    equ 15  
sys_fork            equ 57
sys_execve          equ 59
sys_wait4           equ 61
sys_getdents        equ 78  
sys_getcwd          equ 79

EINTR equ -4         


SIGABRT     equ  6
SIGALRM     equ  14
SIGBUS      equ 7
SIGCHLD     equ  17
SIGCONT     equ  18
SIGFPE      equ 8
SIGHUP      equ 1
SIGILL      equ 4
SIGINT      equ 2
SIGPOLL     equ  29
SIGIO       equ  SIGPOLL
SIGIOT      equ  SIGABRT
SIGPIPE     equ  13
SIGPROF     equ  27
SIGPWR      equ  30
SIGQUIT     equ  3
SIGSEGV     equ  11
SIGSTKFLT   equ  16
SIGSTKSZ    equ  8192
SIGSYS      equ  31
SIGTERM     equ  15
SIGTRAP     equ  5
SIGTSTP     equ  20
SIGTTIN     equ  21
SIGTTOU     equ  22
SIGURG      equ  23
SIGUSR1     equ  10
SIGUSR2     equ  12
SIGVTALRM   equ  26
SIGWINCH    equ  28
SIGXCPU     equ  24
SIGXFSZ     equ  25

SA_RESTORER equ 0x04000000  ;flag value to tell kernal that restorer function is seperate
SA_RESTART equ 0x10000000   ; if a syscall was in progress, restart that syscall
SA_RESETHAND equ 0x80000000 ; after rec the interrupt once, reset the handler to default.



section .text

extern _print
extern _print_with_new_line
extern _strlen
extern _itoa
extern _mem_copy
extern _malloc
extern _free
extern _print_error_with_new_line
extern _string_copy_including_null
extern _strcmp

extern _builtin_cd
extern _builtin_pwd


global _start



_init:
    call _signal_handling
    call _get_and_set_cwd
    call _set_prefix_line
    call _get_and_set_memory_for_input_buffer
    ret



_sigint_myshell_handler:
    mov rax, sys_write
    mov rdi, 1
    lea rsi, [rel new_line]
    mov rdx, 1
    syscall
    ret


_sigint_myshell_restorer:
    mov rax, sys_rt_sigreturn
    syscall


_sigtstp_myshell_handler:
    mov rax, sys_write
    mov rdi, 1
    lea rsi, [rel new_line]
    mov rdx, 1
    syscall
    ret


_sigtstp_myshell_restorer:
    mov rax, sys_rt_sigreturn
    syscall




_signal_handling:
    
    ; SIGINT for ctrl+c 
    mov rax, sys_rt_sigaction
    mov rdi, SIGINT
    lea rsi, [rel sigint_idle_struct]
    xor rdx, rdx                        ; buffer address for default hanlder, not needed
    mov r10, 8                          ; expects this in x86_64
    syscall

    test rax, rax
    jl .set_error_overriding_custom_handler_SIGINT_and_exit

    ; SIGTSTP for ctrl+z
    mov rax, sys_rt_sigaction
    mov rdi, SIGTSTP
    lea rsi, [rel sigtstp_idle_struct]
    xor rdx, rdx                        ; buffer address for default hanlder, not needed
    mov r10, 8                          ; expects this in x86_64
    syscall

    test rax, rax
    jl .set_error_overriding_custom_handler_SIGTSTP_and_exit
    ret
    

    .set_error_overriding_custom_handler_SIGINT_and_exit:
        mov [rel error_code], rax
        mov [rel error_custom_handler_number], SIGINT
        call _errors.error_overriding_custom_handler
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code


    .set_error_overriding_custom_handler_SIGTSTP_and_exit:
        mov [rel error_code], rax
        mov [rel error_custom_handler_number], SIGTSTP
        call _errors.error_overriding_custom_handler
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code


_get_and_set_memory_for_input_buffer:
    mov rdi, [rel capacity_input_buffer_len]
    call _malloc

    test rax, rax
    jl .handle_init_memory_error_and_exit

    mov [rel input_buffer_address], rax
    ret

    .handle_init_memory_error_and_exit:
        mov [rel error_code], rax
        call _errors.print_error_input_init_memory
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code


_get_and_set_cwd:
    mov rax, sys_getcwd
    lea rdi, [rel curr_cwd]
    mov rsi, 4096
    syscall                  ; ret: len cwd including NULL in rax,and cwd in buffer

    test rax, rax
    jl .set_error_getting_pwd_and_exit          ; sys_getcwd return error with NULL
    dec rax                                     ; og len included NULL, so i removed it
    mov [rel curr_cwd_len], rax                 ; update curr_cwd_len
    ret

    .set_error_getting_pwd_and_exit:
        mov [rel error_code], rax
        call _errors.error_getting_cwd
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code

_set_prefix_line:
    ; 'myshell:[cwd]$'

    lea rdi, [rel prefix_line]

    ; add colour
    lea rsi, [rel colour_bright_red]
    call _string_copy_including_null                ; rdi: address of NULL, \0
    ; add style
    lea rsi, [rel style_bold]
    call _string_copy_including_null                ; rdi: address of NULL, \0

    lea rsi, [rel myshell_line]
    call _string_copy_including_null                ; rdi: address of NULL, \0

    ; reset colour
    lea rsi, [rel colour_reset]
    call _string_copy_including_null                ; rdi: address of NULL, \0
    ; reset style
    lea rsi, [rel style_reset]
    call _string_copy_including_null                ; rdi: address of NULL, \0


    lea rsi, [rel semicolon]
    call _string_copy_including_null                ; rdi: address of NULL, \0


    ; add colour
    lea rsi, [rel colour_bright_cyan]
    call _string_copy_including_null                ; rdi: address of NULL, \0
    ; add style
    lea rsi, [rel style_italic]
    call _string_copy_including_null                ; rdi: address of NULL, \0


    lea rsi, [rel curr_cwd]
    call _string_copy_including_null                ; rdi: address of NULL, \0
    

    ; reset colour
    lea rsi, [rel colour_reset]
    call _string_copy_including_null                ; rdi: address of NULL, \0
    ; reset style
    lea rsi, [rel style_reset]
    call _string_copy_including_null                ; rdi: address of NULL, \0


    lea rsi, [rel dollar_sign_with_space]
    call _string_copy_including_null

    lea rax, [rel prefix_line]
    sub rdi, rax
    mov [rel prefix_line_len], rdi

    ret

_print_prefix_line:
    mov rax, [rel prefix_line_len]
    mov rdi, 1
    lea rsi, [rel prefix_line]
    call _print
    ret


_read_input:
    ; make a read call

    mov qword [rel filled_size_input_buffer_len], 0
    mov qword [rel input_interrupted], 0

    .read_input_loop:
        mov rax, sys_read
        mov rdi, 0                              ; fd 0
        mov rsi, [rel input_buffer_address]     ; addres of buffer
        add rsi, [rel filled_size_input_buffer_len]
        mov rdx, [rel capacity_input_buffer_len]
        sub rdx, [rel filled_size_input_buffer_len]
        syscall 

        cmp rax, EINTR          ; -4, ctrl+c interrupted
        je .interrupted


        test rax, rax
        jl .handle_error_reading_input
        jz  .handle_eof                            ; rax == 0, ctrl+d 

        add [rel filled_size_input_buffer_len], rax

        mov rcx, [rel filled_size_input_buffer_len]
        cmp rcx, [rel capacity_input_buffer_len]
        je .get_more_buffer_size
        ret

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
        ; copy old buffer data into new buffer
        mov rdi, rax                                    ; new address : Dest
        mov rsi, [rel input_buffer_address]             ; old address : Src
        mov rdx, [rel filled_size_input_buffer_len]                ; total bytes to copy
        call _mem_copy

        mov rdi, [rel input_buffer_address]                ; free old address memory
        call _free 

        pop rax
        mov [rel input_buffer_address], rax             ; update input address
        
        ; rn its: old_cap*2
        mov rax, [rel capacity_input_buffer_len]        ; update buffer_capacity
        shl rax, 1
        mov [rel capacity_input_buffer_len], rax

        jmp .read_input_loop


    .handle_error_reading_input:
        mov [rel error_code], rax
        call _errors.print_error_reading_input
        ret

    .handle_error_increasing_input_buffer_and_exit:
        mov [rel error_code], rax
        call _errors.print_error_increasing_input_mem
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

_get_memory_for_parse_buffer:
    push r12
    push r13


    mov rax, [rel filled_size_input_buffer_len]
    add rax, 8                              ; some extra bytes i may need
    mov r12, rax                    ; save allocated size
    cmp [rel capacity_parse_buffer_len], rax
    jge .enough_memory

    ; not anough memory
    mov rdi, rax
    call _malloc

    test rax, rax
    jl .set_error_getting_parse_memory_and_exit

    mov r13, rax                    ; save addres of new memory address

    ; i have to release old memory, but, if this is 1st time, i dont
    cmp qword [rel capacity_parse_buffer_address], 0   ; before first commmand address is zero
    jz .dont_free_memory

    mov rdi, [rel capacity_parse_buffer_address]
    call _free

    .dont_free_memory:
    mov [rel capacity_parse_buffer_address], r13
    mov [rel capacity_parse_buffer_len], r12
    
    .enough_memory:
        pop r13
        pop r12
        ret

    .set_error_getting_parse_memory_and_exit:
        mov [rel error_code], rax
        call _errors.print_error_getting_parse_memory

        mov [rel exit_status_code], 1
        jmp _exit_with_status_code


; TODO: "", empty argumets are ignored
; because its basically NULL followed by NULL in pu parser
_parse_input:

    ; PARSER LOGIC FOR
    ; ["./program arg1  arg2 arg3\n"] -> ["./program\0agr1\0arg2\n"]
    ; copy <space>, <tab> as NULL
    ; do not copy "", ''
    ; RN -> one command followed by everything as arguments

    mov rdi, [rel capacity_parse_buffer_address]
    xor rdx, rdx                        ; weather last byte copied was NULL or not
    xor rsi, rsi                        ; index for dst to copy bytes to
    xor r8, r8                          ; index for line traversal
    mov r9, [rel input_buffer_address]
    xor r10, r10                        ; weather inside double quotes or not
    xor r11, r11                        ; weather inside single quotes or not
    .loop_till_new_line:
        cmp byte [r9 + r8], 0x0a            ; if the byte is \n
        je .buffer_parsed

        cmp byte [r9 + r8], 0x20            ; space
        je .replace_with_null

        cmp byte [r9 + r8], 0x09            ; tabs
        je .replace_with_null

        cmp byte [r9 + r8], 0x22            ; for : double quotes ""
        je .handle_dq
        
        cmp byte [r9 + r8], 0x27            ; for : single quotes ''
        je .handle_sq

        ; if any other char was passed, copy it to dst addr
        .copy_byte_and_loop:

            mov al, [r9 + r8]
            mov [rdi + rsi], al
            inc r8
            inc rsi
            xor rdx, rdx                          ; last byte coped was not NULL
            jmp .loop_till_new_line

        .handle_dq:
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
            
            ; since not inside dq, or sq, i am now inside DQ
            ; dont copy anything
            mov r10, 1
            inc r8
            jmp .loop_till_new_line


        .handle_sq:
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


        .replace_with_null:
            test r10, r10
            jz .check_if_inside_single_quotes   ; if not inside DQ, cehck if inside SQ
            ; if inside DQ, just let this whitespace be
            jmp .copy_byte_and_loop
            

        .check_if_inside_single_quotes:
            test r11, r11
            jnz  .copy_byte_and_loop ; i am inside single quote
            
            ; now i am not inside DQ, or SQ

            test rdx, rdx
            jnz .last_copied_byte_was_null

            mov byte [rdi + rsi], 0
            inc rsi
            inc r8
            mov rdx, 1                          ; last byte coped was NULL
            jmp .loop_till_new_line

        .last_copied_byte_was_null:
            inc r8
            jmp .loop_till_new_line




    .buffer_parsed:
        mov byte [rdi + rsi], 0                 ; add a NULL before \n
        
        inc rsi
        mov al, [r9 + r8]
        mov [rdi + rsi], al                 ; copy the \n as well

        inc rsi
        mov byte [rdi + rsi], 0                 ; add NULL after \n
        
        mov [rel filled_size_parse_buffer_len], rsi        ; update len of parsed buffer
        ret


_process_tokens:
    ; RN -> 
    ; arg[0] -> command
    ; every other arg is arguments for,entire string is treated as a single line command

    xor rdx, rdx                    ; total tokens processed for a line
    xor r8, r8                      ; idx for looping
    mov r9, [rel capacity_parse_buffer_address]
    xor  r10, r10                   ; len of token
    xor r11, r11                    ; counts how many args have passed

    .loop_till_new_line:

        cmp byte [r9 + r8], 0x0a
        je .all_tokens_processed

        cmp byte [r9 + r8], 0      ; this means the token has just ended
        je .process_token

    .loopback:
        inc r8                      ; idx for looping
        inc r10                     ; len of token
        jmp .loop_till_new_line

    .process_token:
        ; r10 len of token
        ; address at r8 - len of token = starting address of token

        mov rdi, [rel capacity_parse_buffer_address]
        add rdi, r8
        sub rdi, r10                    ; addres of token

        lea rax, [rel reusable_buffer]
        mov rcx, rdx
        shl rcx, 3
        add rax, rcx                    ; offset for next address, total token*8
        mov [rax], rdi                      ; move to that address, the addres of token

        cmp rdx, 0
        je .command_expected

        ; else every other token is treated as a argument
        ; assuming total arguments passed are not more than 4096/8 or 512 args,
        ; reusable_buffer will be enough_memory

        inc rdx                                 ; inc parsed token len
        xor r10, r10                            ; reset len of token
        inc r8
        jmp .loop_till_new_line

    .command_expected:
        ; save address of command
        mov [rel address_command], rdi
        inc rdx                                 ; inc parsed token len
        xor r10, r10                            ; reset len of token
        inc r8
        jmp .loop_till_new_line




        cmp r10, 2                                  ; len of command is 2?
        call .check_if_command_is_built_in


    .check_if_command_is_built_in:
        ; address at r8 - len of token + 1 = starting address of token

        ;check for cd
        lea rax, [rel cd]
        mov rdi, [rel capacity_parse_buffer_address]
        add rdi, r8
        sub rdi, r10
        inc rdi
        call _strcmp                            ; returns 0 if equal in rax

        test rax, rax
        jz .cd_function_called
        jmp .check_pwd

        .cd_function_called:
            ret

        .check_pwd:
            ret

    .all_tokens_processed:
        ; add a NULL in the argc address arary, [reusable_buffer user here]
        lea rax, [rel reusable_buffer]
        mov rcx, rdx                    ; add 1st toke, after 0th token
        shl rcx, 3
        add rax, rcx                    ; offset for next address, total token*8
        mov qword [rax], 0                      ; move to that address the addres of token

        lea rcx, [rel reusable_buffer]
        mov [rel address_argc_address_array], rcx

    .build_envp_array:

        ; right now i am sending og envp
        mov rax, [rel og_envp_stack_array_address]
        mov [rel address_envp_address_array], rax

    .return:
        ret


_execute_process:

    mov rax, sys_fork
    syscall  

    test rax, rax
    jl .set_error_forking
    jnz .parent

    ; this is child now

    mov rax, sys_execve
    mov rdi, [rel address_command]
    mov rsi, [rel address_argc_address_array]
    mov rdx, [rel address_envp_address_array]
    syscall


    .set_error_executing_process:
        mov [rel error_code], rax
        call _errors.print_error_executing_process


    mov [rel exit_status_code], 1
    call _exit_with_status_code


    .parent:
        mov rax, sys_wait4   ;syscall number
        mov rdi, -1 
        xor rsi, rsi     ;where to store exit status(For simply waiting, NULL/0 is fine)
        xor rdx, rdx     ;how to wait
        xor r10, r10      ;where to store resource usage
        syscall

        ; TODO: handle error for this

        ret

    .set_error_forking:
        mov [rel error_code], rax
        call _errors.print_error_forking
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code




_handle_input:
    
    ; check if line empty
    mov rax, [rel filled_size_input_buffer_len]
    cmp rax, 1
    je .empty_line

    call _get_memory_for_parse_buffer
    call _parse_input
    call _process_tokens
    call _execute_process


    .empty_line:
    ret

    

_start:
    mov rbp, rsp 

    ; save the address of shells envp variables
    mov rax, [rbp]                      ; total argc
    add rax, 2
    lea rax, [rbp + rax*8]                ; address where the array of address start for envp
    mov [rel og_envp_stack_array_address], rax

    call _init

    .loop_main:
        call _print_prefix_line
        call _read_input

        cmp qword [rel exit_flag], 1
        je _exit

        cmp [rel input_interrupted], 1
        je .loop_main 

        call _handle_input
        jmp .loop_main

    ; TODO: _free_all_memory




_errors:
.print_error_input_init_memory:
    mov rax, error_input_init_memory_len
    mov rdi, 1
    lea rsi, [rel error_input_init_memory]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


.print_error_reading_input:
    mov rax, error_reading_input_len
    mov rdi, 1
    lea rsi, [rel error_reading_input]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

.print_error_getting_parse_memory:
    mov rax, error_getting_parse_memory_len
    mov rdi, 1
    lea rsi, [rel error_getting_parse_memory]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


.print_error_increasing_input_mem:
    mov rax, error_increasing_input_buffer_mem_len    
    mov rdi, 1
    lea rsi , [rel error_increasing_input_buffer_mem]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

.error_getting_cwd:
    mov rax, error_getting_cwd_len
    mov rdi, 1
    lea rsi , [rel error_getting_cwd]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

.error_overriding_custom_handler:
    mov rax, error_overriding_custom_handler_len
    mov rdi, 1
    lea rsi , [rel error_overriding_custom_handler]
    call _print

    mov rax, [rel error_custom_handler_number]
    lea rdi, [rel reusable_buffer]
    call _itoa                          ; rax has len of number in bytes

    mov rdi, 1
    lea rsi, [rel reusable_buffer]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

.print_error_forking:
    mov rax, error_forking_len
    mov rdi, 1
    lea rsi , [rel error_forking]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


.print_error_executing_process:
    mov rax, error_executing_process_len
    mov rdi, 1
    lea rsi , [rel error_executing_process]
    call _print


    mov rdi, [rel address_command]
    call _strlen
    
    mov rdi, 1
    mov rsi, [rel address_command]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret



_exit_with_status_code:
    mov rax, 60
    mov rdi, [rel exit_status_code]
    syscall

_exit:
    mov rax, 60
    mov rdi, 0
    syscall
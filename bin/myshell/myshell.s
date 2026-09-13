global error_code
section .data

    myshell_line db "myShell", 0
    myshell_line_len equ $ - myshell_line

    capacity_input_buffer_len dq 4096
    filled_size_input_buffer_len dq 0


    error_input_init_memory db "Error allocating memory for input buffer",0
    error_input_init_memory_len equ $ - error_input_init_memory

    error_reading_input db "Error reading input", 0
    error_reading_input_len equ $ - error_reading_input

    error_increasing_input_buffer_mem db "Error increasing input buffer storage", 0
    error_increasing_input_buffer_mem_len equ $ - error_increasing_input_buffer_mem

    error_getting_cwd db "Error getting cwd",0
    error_getting_cwd_len equ $ - error_getting_cwd

    error_overriding_custom_handler db "Error overriding custom handler: ", 0
    error_overriding_custom_handler_len equ $ - error_overriding_custom_handler


    exit_status_code dq 0
    error_code dq 0
    exit_flag dq 0


    align 8
    sigint_struct:
        dq _sigint_handler                         ; address of handler
        dq SA_RESTORER                          ; for the flags
        dq _sigint_restorer                        ; address of restorer
        times 16 dq 0                       ; 16 times dq = 16x8 = 128bytes for maskA




    ;-------------------------built in commands-----------------------

    cd db "cd",0
    pwd db "pwd",0




section .rodata

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

extern _builtin_cd
extern _builtin_pwd


global _start



_init:
    call _signal_handling
    call _get_and_set_cwd
    call _set_prefix_line
    call _get_and_set_memory_for_input_buffer
    ret


_sigint_handler:
    ; print new line and return
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel new_line]
    call _print

    ret

_sigint_restorer:
    mov rax, sys_rt_sigreturn
    syscall


_signal_handling:
    
    ; SIGINT for ctrl+c 
    mov rax, sys_rt_sigaction
    mov rdi, SIGINT
    lea rsi, [rel sigint_struct]
    xor rdx, rdx                        ; buffer address for default hanlder, not needed
    mov r10, 8                          ; expects this in x86_64
    syscall

    test rax, rax
    jl .set_error_overriding_custom_handler_and_exit
    ret

    .set_error_overriding_custom_handler_and_exit:
        mov [rel error_code], rax
        mov [rel error_custom_handler_number], SIGINT
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
    sub rdi, rcx
    mov [rel prefix_line_len], rdi

    ret

_print_prefix_line:
    mov rax, prefix_line_len
    mov rdi, 1
    lea rsi, [rel prefix_line]
    call _print
    ret


_read_input:
    ; make a read call

    mov qword [rel filled_size_input_buffer_len], 0

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


_parse_input:
    
    cmp rax, EINTR          ; -4, ctrl+c interrupted
    je .interrupted

    ; check if line empty
    mov rax, [rel filled_size_input_buffer_len]
    cmp rax, 1
    je .empty_line

    ; print the line
    mov rdi, 1
    mov rsi, [rel input_buffer_address]
    call _print

    ; parse the input, "cd ../../" -> "cd\0../../\0"
    ; now arg[0] = "cd\0"
    ; arg[1] = "../../\0"
    ; then compare arg[0] to builtin commands, if it matched, handle it.
    
    ; if not a builtin, i expect the 1st arg to be a path to executable,
    ; like grep will not work, /bin/grep will work

    ; i will try to run it as a process and pass in the rest of the args as argumnets


    .empty_line:
    ret

    .interrupted:
    ret


_start:
    mov rbp, rsp 

    call _init

    .loop_main:
        call _print_prefix_line
        call _read_input
        call _parse_input

        cmp qword [rel exit_flag], 1
        je _exit

        jmp .loop_main



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


_exit_with_status_code:
    mov rax, 60
    mov rdi, [rel exit_status_code]
    syscall

_exit:
    mov rax, 60
    mov rdi, 0
    syscall
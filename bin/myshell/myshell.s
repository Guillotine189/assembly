%include "./dep/constants.inc"

global filled_size_input_buffer_len
global input_interrupted
global input_buffer_address
global capacity_input_buffer_len

global exit_status_code
global exit_flag
global error_custom_handler_number
global address_command

global address_argc_address_array
global address_envp_address_array
global og_envp_stack_array_address
global total_command_aruments
section .data

    myshell_line db "myShell", 0
    myshell_line_len equ $ - myshell_line

    capacity_input_buffer_len dq 4096
    filled_size_input_buffer_len dq 0               ; includes \n
    input_buffer_address dq 0         ; address from malloc

    capacity_parse_buffer_address dq 0              ; DO NOT CHANGE dq 0, i use it in code
    capacity_parse_buffer_len dq 0
    filled_size_parse_buffer_len dq 0


    address_command dq 1
    address_argc_address_array dq 1
    address_envp_address_array dq 1
    total_command_aruments dq 1

    og_envp_stack_array_address dq 1

    cursor_position dq 0

    input_interrupted dq 0

    shell_pgid dq 0
    child_pid dq 0
    child_pgid dq 0

    exit_status_code dq 0
    exit_flag dq 0
    error_custom_handler_number dq 1

    align 8
    reset_action_struct:
        dq 0
        dq 0
        dq 0
        times 16 dq 0

    align 8 
    signal_print_line_struct:
        dq _signal_do_nothing_handler                         ; address of handler
        dq SA_RESTORER                         ; for the flags
        dq _signal_do_nothing_restorer                        ; address of restorer
        times 16 dq 0                       ; 16 times dq = 16x8 = 128bytes for maskA

    align 8
    signal_ignore_struct:
        dq 1                    ; SIG_IGN
        dq 0                    ; sa_flags
        dq 0                    ; sa_restorer
        times 16 dq 0            ; sa_mask






global new_line
section .rodata

    ; modern ANSI/VT-compatible terminal
    ; like GNOME Terminal, Konsole, Kitty, Alacritty

    clear_screen db 0x1b, '[2J'      ; clear the screen
    clear_screen_len equ $ - clear_screen
    clear_scrollback db 0x1b, '[3J'   ; clear the scrollable part of the screen as well
    clear_scrollback_len equ $ - clear_scrollback

    dot db ".",0
    double_dot_slash db "../", 0
    back_slash db "/"
    dot_back_slash db "./", 0
    dash db '-',0
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
global old_cwd
global old_cwd_len

global reusable_buffer
section .bss
    reusable_buffer resb 4096

    curr_cwd resb 4096
    curr_cwd_address resb 8                 ;TODO: maybe remove it later
    curr_cwd_len resq 1

    old_cwd resb 4096
    old_cwd_len resq 1

    prefix_line resb 4096
    prefix_line_len resq 1

    ; for noncanonical_mode
    termios     resb 60
    old_termios resb 60


; variables
extern error_code

; functons
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
extern _cmp_equal_memory

extern print_error_input_init_memory
extern print_error_getting_parse_memory
extern print_error_getting_cwd
extern print_error_overriding_custom_handler
extern print_error_forking
extern print_error_executing_process
extern print_error_setting_non_con_mode
extern print_error_getting_pgid
extern print_error_command_not_found


extern _get_and_set_mem_for_history_array
extern _read_input

extern _check_and_execute_if_built_in
extern _check_if_cmd_is_in_path


section .text


global _start
global _exit_with_status_code
global _exit
global _set_prefix_line

_init:
    call _signal_handling
    call _set_noncanonical_mode
    call _get_and_set_cwd
    call _get_and_set_pgid
    call _get_and_set_mem_for_history_array
    call _set_prefix_line
    call _get_and_set_memory_for_input_buffer
    ret



_signal_do_nothing_handler:
    mov rax, sys_write
    mov rdi, 1
    lea rsi, [rel new_line]
    mov rdx, 1
    syscall
    ret


_signal_do_nothing_restorer:
    mov rax, sys_rt_sigreturn
    syscall





_signal_handling:
    
    ; SIGINT for ctrl+c 
    mov rax, sys_rt_sigaction
    mov rdi, SIGINT
    lea rsi, [rel signal_print_line_struct]
    xor rdx, rdx                        ; buffer address for default hanlder, not needed
    mov r10, 8                          ; expects this in x86_64
    syscall

    test rax, rax
    jl .set_error_overriding_custom_handler_SIGINT_and_exit

    ; SIGTSTP for ctrl+z
    mov rax, sys_rt_sigaction
    mov rdi, SIGTSTP
    lea rsi, [rel signal_print_line_struct]
    xor rdx, rdx                        ; buffer address for default hanlder, not needed
    mov r10, 8                          ; expects this in x86_64
    syscall

    test rax, rax
    jl .set_error_overriding_custom_handler_SIGTSTP_and_exit
    

    ; SIGTTOU: background process group performs a terminal-control/output operation
    ; like when changing gpid for temrinal
    ; when my shell is background, i try to chenge it to be in foreground
    ; that sends a interrupt to my shell as it is a background process.
    ; i will ignore that signal.
    mov rax, sys_rt_sigaction
    mov rdi, SIGTTOU
    lea rsi, [rel signal_ignore_struct]
    xor rdx, rdx                        ; buffer address for default hanlder, not needed
    mov r10, 8                          ; expects this in x86_64
    syscall

    test rax, rax
    jl .set_error_overriding_custom_handler_SIGTTOU_and_exit

    ;  SIGTTIN: background process group attempts to read from controlling terminal
    mov rax, sys_rt_sigaction
    mov rdi, SIGTTIN
    lea rsi, [rel signal_ignore_struct]
    xor rdx, rdx                        ; buffer address for default hanlder, not needed
    mov r10, 8                          ; expects this in x86_64
    syscall

    test rax, rax
    jl .set_error_overriding_custom_handler_SIGTTIN_and_exit
    ret
    

    .set_error_overriding_custom_handler_SIGINT_and_exit:
        mov [rel error_code], rax
        mov [rel error_custom_handler_number], SIGINT
        call print_error_overriding_custom_handler
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code


    .set_error_overriding_custom_handler_SIGTSTP_and_exit:
        mov [rel error_code], rax
        mov [rel error_custom_handler_number], SIGTSTP
        call print_error_overriding_custom_handler
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code


    .set_error_overriding_custom_handler_SIGTTOU_and_exit:
        mov [rel error_code], rax
        mov [rel error_custom_handler_number], SIGTTOU
        call print_error_overriding_custom_handler
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code

    .set_error_overriding_custom_handler_SIGTTIN_and_exit:
        mov [rel error_code], rax
        mov [rel error_custom_handler_number], SIGTTIN
        call print_error_overriding_custom_handler
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code



; rsi = signal number like SIGINT
_reset_signal:
    push rdi

    ; action = SIG_DFL meaning, action is default indicated by 0
    mov qword [rel reset_action_struct], 0

    ; sa_flags set as zero
    mov qword [rel reset_action_struct + 8], 0

    ; sa_restorer set as zero
    mov qword [rel reset_action_struct + 16], 0

    ; sa_mask is 128 bytes, write 128 bytes of zeros
    lea rdi, [rel reset_action_struct + 24]
    xor rax, rax
    mov rcx, 16
    rep stosq

    pop rdi

    mov rax, sys_rt_sigaction
    lea rsi, [rel reset_action_struct]
    xor rdx, rdx            ; oldact = NULL
    mov r10, 8              ; always 8 in x86-64
    syscall

    ret

_set_noncanonical_mode:
    ; get old struct
    mov     rax, sys_ioctl
    mov     rdi, 0
    mov     rsi, TCGETS                     ; get the current config
    lea     rdx, [rel termios]
    syscall

    test rax, rax
    jl .set_error_setting_non_con_mode_and_exit

    ; Copy current settings to old_termios
    lea     rsi, [rel termios]
    lea     rdi, [rel old_termios]
    mov     rcx, 60
    rep     movsb

    ; modify old struct
    mov     eax, [rel termios + C_LFLAG]
    and     eax, ~(0x0002 | 0x0008)
    mov     [rel termios + C_LFLAG], eax

    ; apply new settings
    mov     rax, sys_ioctl
    mov     rdi, 0
    mov     rsi, TCSETS                     ; set the new config
    lea     rdx, [rel termios]
    syscall

    test rax, rax
    jl .set_error_setting_non_con_mode_and_exit

    ret

    .set_error_setting_non_con_mode_and_exit:
        mov [rel error_code], rax
        call print_error_setting_non_con_mode
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code

_set_canonical_mode:

    ; restore old struct, get out of nin canonical mode
    mov     rax, sys_ioctl
    mov     rdi, 0
    mov     rsi, TCSETS
    lea     rdx, [rel old_termios]
    syscall

    ; TODO: handle error 
    ret 


_get_and_set_memory_for_input_buffer:
    mov rdi, [rel capacity_input_buffer_len]
    call _malloc

    test rax, rax
    jl .handle_init_memory_error_and_exit

    mov [rel input_buffer_address], rax
    ret

    .handle_init_memory_error_and_exit:
        mov [rel error_code], rax
        call print_error_input_init_memory
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code


_get_and_set_cwd:
    ; set old pwd to null
    mov qword [rel old_cwd], 0
    mov qword [rel old_cwd_len], 0

    ; get new cwd
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
        call print_error_getting_cwd
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code

_get_and_set_pgid:
    mov rax, sys_getpgrp
    syscall

    test rax, rax
    jl .set_error_getting_pgid_and_exit

    mov [rel shell_pgid], rax

    ret

    .set_error_getting_pgid_and_exit:
        mov [rel error_code], rax
        call print_error_getting_pgid
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
        call print_error_getting_parse_memory

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

    .all_tokens_processed:
        ; add a NULL in the argc address arary, [reusable_buffer user here]
        lea rax, [rel reusable_buffer]
        mov rcx, rdx                    ; add 1st toke, after 0th token
        shl rcx, 3
        add rax, rcx                    ; offset for next address, total token*8
        mov qword [rax], 0                      ; move to that address the addres of token

        lea rcx, [rel reusable_buffer]
        mov [rel address_argc_address_array], rcx

        mov [rel total_command_aruments], rdx

    .build_envp_array:

        ; right now i am sending og envp
        mov rax, [rel og_envp_stack_array_address]
        mov [rel address_envp_address_array], rax

    .return:
        ret


_execute_process:

    ; command starts with ./ or / or ../, this is not a built_in or a command that should
    ; be ran after checking from path env variable

    mov rax, [rel address_command]
    cmp byte [rax], '/'     ; if 1st byte is /, its a absolute path, direct execution
    je .execute_with_og_command

    mov rax, 2
    mov rdi, [rel address_command]
    lea rsi, [rel dot_back_slash]
    call _cmp_equal_memory

    test rax, rax                    ; if starting with ./, then this is a relative path
    jz .execute_with_og_command 


    mov rax, 3
    mov rdi, [rel address_command]
    lea rsi, [rel double_dot_slash]
    call _cmp_equal_memory

    test rax, rax                    ; if starting with ../, then this is a relative path
    jz .execute_with_og_command 

    
    ; now either the command is built in or it is supposed to be inside path variables

    ; check if the command is built in
    call _check_and_execute_if_built_in
    test rax, rax
    jz .return                      ; zero mean it was builtin

    ; check if the command is supposed to run using a path var or not
    call _check_if_cmd_is_in_path
    test rax, rax
    jl .set_error_command_not_found  ; command not inside env_path either -> give error

    ; now the command is actually in env_path

    ; now if path was found i need to change address of command
    mov [rel address_command], rax


    .execute_with_og_command:
    mov rax, sys_fork
    syscall  

    test rax, rax
    jl .set_error_forking
    jnz .parent

    ; this is child now


    ; set the gpid of child to be it's own pid
    mov rax, sys_setpgid
    xor rdi, rdi               ; pid = 0  -> this process
    xor rsi, rsi               ; pgid = 0 -> use this process's PID
    syscall
    test    rax, rax
    jl      .set_error_executing_process

    call _set_canonical_mode                ; terminal is now canonical
    call _reset_child_signals         ; childs signals have been restored to default


    ; TODO: wait for shell signal to execute.
    ; I want this to execute in foreground directly, not sometime after i execve
    mov rax, sys_execve
    mov rdi, [rel address_command]
    mov rsi, [rel address_argc_address_array]
    mov rdx, [rel address_envp_address_array]
    syscall


    .set_error_executing_process:
        mov [rel error_code], rax
        call print_error_executing_process


    mov [rel exit_status_code], 1
    call _exit_with_status_code

    .set_error_command_not_found:
        mov [rel error_code], rax
        call print_error_command_not_found
        ret




    .parent:
        ; child_pid is in rax

        mov [rel child_pid], rax
        mov [rel child_pgid], rax

      ; make sure child is in its own process group. This is done here to avoid race
        mov rax, sys_setpgid
        mov rdi, [rel child_pid]
        mov rsi, [rel child_pid]
        syscall

        ; TODO: handle the error for not begin able to change gpid of child

        ; make child the fg process in terminal 
        mov rax, sys_ioctl
        mov rdi, 0                  ; fd of the temrinal / the controlling terminal
        mov rsi, TIOCSPGRP          ; 0x5410
        lea rdx, [rel child_pgid]
        syscall


        ; TODO: handle error for moving child to foreground

        ; wait for the child to finish
        mov rax, sys_wait4   ;syscall number
        mov rdi, [rel child_pid] 
        xor rsi, rsi     ;where to store exit status(For simply waiting, NULL/0 is fine)
        xor rdx, rdx     ;how to wait
        xor r10, r10      ;where to store resource usage
        syscall

        ; TODO: handle error for waiting

        ; child finished, now take the shell back to foreground
        mov rax, sys_ioctl
        xor rdi, rdi
        mov rsi, TIOCSPGRP
        lea rdx, [rel shell_pgid]
        syscall

        ; TODO: dont reset non-canonical, save the old state and apply it
        call _set_noncanonical_mode

        .return:
        ret

    .set_error_forking:
        mov [rel error_code], rax
        call print_error_forking
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


_reset_child_signals:
    
    mov rsi, SIGINT
    call _reset_signal
    mov rsi, SIGTSTP
    call _reset_signal
    mov rsi, SIGTTOU
    call _reset_signal
    mov rsi, SIGTTIN
    call _reset_signal
    ret

_cleanup:
    
    call _set_canonical_mode
    ret


_exit_with_status_code:
    
    call _cleanup

    mov rax, 60
    mov rdi, [rel exit_status_code]
    syscall


_exit:

    call _cleanup

    mov rax, 60
    mov rdi, 0
    syscall
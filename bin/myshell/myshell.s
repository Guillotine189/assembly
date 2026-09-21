%include "./dep/constants.inc"
%include "../dependencies/mystring.inc"

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

global input_buffer_address
global filled_size_input_buffer_len
section .data

    capacity_input_buffer_len dq 4096
    filled_size_input_buffer_len dq 0               ; includes \n
    input_buffer_address dq 0         ; address from malloc


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
    myshell_line db "MyShell", 0
    myshell_line_len equ $ - myshell_line


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
    new_line db 0x0a, 0

    colour_len equ 5
    colour_reset_len equ 4

    colour_reset    db 27, "[0m", 0
    colour_blue     db 27, "[34m", 0
    colour_black    db 27, "[30m", 0     
    colour_red      db 27, "[31m", 0
    colour_green    db 27, "[32m", 0
    colour_yellow   db 27, "[33m", 0
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

global last_command_exit_code_ascii
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

    pipe_for_command resd 2             ; 2fd:  4bytes each, [read, write]
    pipe_read_buffer_child resb 8

    last_command_exit_code_ascii resb 32


; variables
extern error_code
extern parse_string_object_address

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
extern print_error_getting_cwd
extern print_error_overriding_custom_handler
extern print_error_forking
extern print_error_setting_non_con_mode
extern print_error_getting_pgid
extern print_error_command_not_found
extern print_error_getting_pipes
extern child_print_error_executing_process
extern parent_print_error_closing_read_pipe
extern parent_print_error_setting_gpid_for_child
extern parent_print_error_moving_child_to_fg
extern parent_print_error_synchronizing_with_child
extern parent_print_error_closing_write_pipe


extern _get_and_set_mem_for_history_array
extern _read_input

extern _parse_input

extern _check_and_execute_if_built_in
extern _check_if_cmd_is_in_path

extern _initialize_shell_env_var

section .text


global _start
global _exit_with_status_code
global _exit
global _set_prefix_line
global _print_prefix_line


_init:
    call _signal_handling
    call _set_noncanonical_mode
    call _get_and_set_cwd
    call _get_and_set_pgid
    call _get_and_set_mem_for_history_array
    call _set_prefix_line
    call _get_and_set_memory_for_input_buffer
    call _set_last_command_exit_code
    call _initialize_shell_env_var
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

    lea rsi, [rel semicolon]
    call _string_copy_including_null                ; rdi: address of NULL, \0

    ; add colour
    lea rsi, [rel colour_bright_green]
    call _string_copy_including_null                ; rdi: address of NULL, \0
    lea rsi, [rel style_bold]
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

_set_last_command_exit_code:
    mov rax, 0
    lea rdi, [rel last_command_exit_code_ascii]
    call _itoa
    ret


_print_prefix_line:
    mov rax, [rel prefix_line_len]
    mov rdi, 1
    lea rsi, [rel prefix_line]
    call _print
    ret



_process_tokens:
    ; expects ["./program\nagr1\narg2\n\n"]
    ; ["./programNULLagr1NULLarg2NULL\n"]
    ; RN -> 
    ; arg[0] -> command
    ; every other arg is arguments for,entire string is treated as a single line command

    xor rdx, rdx                    ; total tokens processed for a line
    xor r8, r8                      ; idx for looping
    mov r9, [rel parse_string_object_address]
    mov r9, [r9 + 16]               ; 16: string offset for address of string
    xor r10, r10                   ; len of token
    xor r11, r11                    ; counts how many args have passed
    xor r12, r12                    ; checks if last byte was \n

    .loop_till_double_new_line:

        cmp byte [r9 + r8], 0x0a      ; this means the token has just ended
        je .process_token

    .loopback:
        inc r8                      ; idx for looping
        inc r10                     ; len of token
        xor r12, r12                ; last byte was not \n
        jmp .loop_till_double_new_line

    .process_token:
        add r12, 1

        mov byte [r9 + r8], 0       ; over write the \n with NULL byte

        cmp r12, 2
        je .all_tokens_processed

        ; r10 len of token
        ; address at r8 - len of token = starting address of token

        
        mov rdi, r9
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


        test r10, r10
        jz .token_with_no_len

        inc rdx                                 ; inc parsed token len

        .token_with_no_len:
        xor r10, r10                            ; reset len of token
        inc r8
        jmp .loop_till_double_new_line
    .command_expected:
        ; save address of command
        mov [rel address_command], rdi
        inc rdx                                 ; inc parsed token len
        xor r10, r10                            ; reset len of token
        inc r8
        jmp .loop_till_double_new_line

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

    ; get pipe
    mov rax, sys_pipe
    lea rdi, [rel pipe_for_command]
    syscall 

    test rax, rax
    jl .error_getting_pipe

    ; command starts with ./ or / or ../, this is not a built_in or a command that should
    ; be ran after checking from path env variable

    mov rax, [rel address_command]
    cmp byte [rax], '/'     ; if 1st byte is /, its a absolute path, direct execution
    je .execute_command

    mov rax, 2
    mov rdi, [rel address_command]
    lea rsi, [rel dot_back_slash]
    call _cmp_equal_memory

    test rax, rax                    ; if starting with ./, then this is a relative path
    jz .execute_command 


    mov rax, 3
    mov rdi, [rel address_command]
    lea rsi, [rel double_dot_slash]
    call _cmp_equal_memory

    test rax, rax                    ; if starting with ../, then this is a relative path
    jz .execute_command 

    
    ; now either the command is built in or it is supposed to be inside path variables

    ; check if the command is built in
    call _check_and_execute_if_built_in
    test rax, rax
    jz .close_pipes                      ; zero mean it was builtin

    ; check if the command is supposed to run using a path var or not
    call _check_if_cmd_is_in_path
    test rax, rax
    jl .command_not_found  ; command not inside env_path either -> give error

    ; now the command is actually in env_path

    ; now if path was found i need to change address of command
    mov [rel address_command], rax


    .execute_command:
    mov rax, sys_fork
    syscall  

    test rax, rax
    jl .error_forking
    jnz .parent



    ; this is child now

    ; close the write part of pipe for child, no need
    call .close_write_pipe
    test rax, rax
    jl .child_error_closing_write_pipe

    ; set the gpid of child to be it's own pid
    mov rax, sys_setpgid
    xor rdi, rdi               ; pid = 0  -> change for current process
    xor rsi, rsi               ; gpid = 0 -> use current process's PID as gpid
    syscall

    test rax, rax
    jl .child_error_setting_gpid


    ; now wait for signal from parent before executing
    ; eg : [3,4] for [read, write]
    .try_sync:
        mov rax, sys_read
        mov edi, [rel pipe_for_command]
        lea rsi, [rel pipe_read_buffer_child]
        mov edx, 1
        syscall

        cmp rax, 1
        je .sync_success

        ; if there is an interrupt, this does not mean sync failed
        cmp rax, -EINTR
        je .try_sync

        jmp .child_error_synchronizing

    .sync_success:

    ; now close the read pipe 
    call .close_read_pipe
    test rax, rax
    jl .child_error_closing_read_pipe

    ; setup before executing child process

    call _set_canonical_mode                ; terminal is now canonical
    call _reset_child_signals         ; childs signals have been restored to default


    mov rax, sys_execve
    mov rdi, [rel address_command]
    mov rsi, [rel address_argc_address_array]
    mov rdx, [rel address_envp_address_array]
    syscall

    ; this part only executes when execve failed
    mov [rel exit_status_code], rax
    mov [rel error_code], rax
    call child_print_error_executing_process
    call _exit_with_status_code

    .child_error_setting_gpid:
        mov [rel exit_status_code], rax   ; the og error code why checnging gpid failed
        call .close_read_pipe
        call _exit_with_status_code

    .child_error_closing_write_pipe:
        ; close read pipe and exit
        mov [rel exit_status_code], rax
        call .close_read_pipe
        call _exit_with_status_code

    .child_error_closing_read_pipe:
        ; write pipe is already closed, cannnot close read pipe so exit
        mov [rel exit_status_code], rax
        call _exit_with_status_code
        

    .child_error_synchronizing:
        mov [rel exit_status_code], rax   ; the og error code why checnging gpid failed
        ; close the read pipe, wite pipe already closed
        mov rax, sys_close
        mov edi, [rel pipe_for_command]
        syscall

        call _exit_with_status_code




    .parent:

        mov [rel child_pid], rax
        mov [rel child_pgid], rax

        ; close the read part of the parent
        call .close_read_pipe
        test rax, rax
        jl .parent_error_closing_read_pipe

        ; child_pid is in rax

      ; make sure child is in its own process group. This is done here to avoid race
        mov rax, sys_setpgid
        mov rdi, [rel child_pid]
        mov rsi, [rel child_pid]
        syscall

        test rax, rax
        jl .parent_error_setting_gpid_for_child

        ; make child the fg process in terminal 
        mov rax, sys_ioctl
        mov rdi, 0                  ; fd of the temrinal / the controlling terminal
        mov rsi, TIOCSPGRP          ; 0x5410
        lea rdx, [rel child_pgid]
        syscall
        ; TODO: handle error for moving child to foreground

        test rax, rax
        jl .parent_error_moving_child_to_fg


        ; Now send the signal to child group to continue
        mov rax, sys_write
        mov edi, [rel pipe_for_command + 4]
        lea rsi, [rel dot]
        mov rdx, 1                      ; juts write 1 byte to tell child to start
        syscall
        
        cmp rax, 1
        jne .parent_error_synchronizing_with_child

        ; close the write part of pipe
        call .close_write_pipe
        test rax, rax
        jl .print_parent_error_closing_write_pipe
        jmp .wait_and_reclaim_terminal


        .print_parent_error_closing_write_pipe:
          ; i don't want to kill child process here    
            call .parent_error_closing_write_pipe
        



        .wait_and_reclaim_terminal:
        ; reap child group
        mov rax, sys_wait4   ;syscall number
        mov rdi, [rel child_pgid] 
        neg rdi                 ; -ve pid means i have given it a pgid
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
        ret


    .parent_error_closing_read_pipe:
        mov [rel error_code], rax
        call .close_write_pipe
        call .kill_and_reap_child_process
        call parent_print_error_closing_read_pipe
        ret

    .parent_error_setting_gpid_for_child:
        mov [rel exit_status_code], rax   ; the og error code why checnging gpid failed
        call .close_write_pipe          ; read pipe is already closed
        call .kill_and_reap_child_process
        call parent_print_error_setting_gpid_for_child
        ret

    .parent_error_moving_child_to_fg:
        mov [rel exit_status_code], rax
        call .close_write_pipe
        call .kill_and_reap_child_process
        call parent_print_error_moving_child_to_fg
        ret

    .parent_error_synchronizing_with_child:
        mov [rel exit_status_code], rax
        call .close_write_pipe
        call .kill_and_reap_child_process
        call parent_print_error_synchronizing_with_child
        ret        

    .parent_error_closing_write_pipe:
        mov [rel exit_status_code], rax
        call parent_print_error_closing_write_pipe
        ret        

    .kill_and_reap_child_process:
        ; 0 pid => send this signal to every process in calling process group 
        ; pid is -ve: pid is actually a gpid, send signal to all pid inside pgid

        ; sig : 0 => no SIGNAL is sent, but permission and checks are performed
        ; meaning, i can use this to check if that pid/gpid exists
        ; but there is a race between checking and killing the child
        ; thec hild can disappear in between checking if it exists and killing it
        ; so no point in checking, just kill the child bec i will do it in the end

        ; now send the kill signal to child process group
        mov rax, sys_kill
        mov rdi, [rel child_pgid]  
        neg rdi
        mov rsi, SIGKILL
        syscall

        ; whether kill succeeded or not,
        ; try to reap the child process group.
        mov rax, sys_wait4
        mov rdi, [rel child_pgid]
        neg rdi 
        xor rsi, rsi
        xor rdx, rdx
        xor r10, r10
        syscall

        ret



    .command_not_found:
        mov [rel error_code], rax
        call print_error_command_not_found
        jmp .close_pipes

    .error_forking:
        mov [rel error_code], rax
        call print_error_forking
        jmp .close_pipes

    .close_pipes:
        mov rax, sys_close
        mov edi, [rel pipe_for_command]
        syscall

        mov rax, sys_close
        mov edi, [rel pipe_for_command + 4]
        syscall
        ret

    .close_read_pipe:
        mov rax, sys_close
        mov edi, [rel pipe_for_command]
        syscall
        ret

    .close_write_pipe:
        mov rax, sys_close
        mov edi, [rel pipe_for_command + 4]
        syscall
        ret

    .error_getting_pipe:
        mov [rel error_code], rax
        call print_error_getting_pipes
        ret






_handle_input:
    
    ; check if line empty
    mov rax, [rel filled_size_input_buffer_len]
    cmp rax, 1             ; when enter was presses. "\n" was written in buffer
    je .empty_line

    call _parse_input
    test rax, rax
    jl .error_parsing_input

    call _process_tokens
    call _execute_process

    .empty_line:
    ret


    .error_parsing_input:  ; TODO: print error and exit
        ret
    

_start:
    mov rbp, rsp 

    ; saving the address so that i can initialize them later
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
%include "./dep/constants.inc"
%include "../dependencies/mystring.inc"
%include "../dependencies/dynamicarray.inc"

global filled_size_input_buffer_len
global input_interrupted
global input_buffer_address
global capacity_input_buffer_len

global exit_status_code
global exit_flag
global error_custom_handler_number
global address_command

global og_envp_stack_array_address

global input_buffer_address
global filled_size_input_buffer_len
global shell_pgid
section .data

    capacity_input_buffer_len dq 4096
    filled_size_input_buffer_len dq 0               ; includes \n
    input_buffer_address dq 0         ; address from malloc


    address_command dq 1

    og_envp_stack_array_address dq 1

    input_interrupted dq 0

    shell_pgid dq 0

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
extern parsed_string_object
extern shell_env_array_object


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
extern print_error_setting_non_con_mode
extern print_error_getting_pgid

extern _initialize_shell_env_array

extern _get_and_set_mem_for_history_array
extern _read_input

extern _generate_tokens
extern _process_token_generate_commands
extern _execute_commands
extern _set_last_command_exit_code




extern _default_dynamic_array_constructor
extern _default_dynamic_array_destructor
extern _dynamic_array_add_element


extern _constructor_mystring
extern _destructor_mystring
extern _append_string_mystring



section .text


global _start
global _exit_with_status_code
global _exit
global _set_prefix_line
global _print_prefix_line
global _set_canonical_mode
global _set_noncanonical_mode
global _reset_signal


_init:
    call _signal_handling
    call _set_noncanonical_mode
    call _get_and_set_cwd
    call _get_and_set_pgid
    call _get_and_set_mem_for_history_array
    call _set_prefix_line
    call _get_and_set_memory_for_input_buffer
    call _set_last_command_exit_code
    call _initialize_shell_env_array
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



_print_prefix_line:
    mov rax, [rel prefix_line_len]
    mov rdi, 1
    lea rsi, [rel prefix_line]
    call _print
    ret




_handle_input:
    
    ; check if line empty
    mov rax, [rel filled_size_input_buffer_len]
    cmp rax, 1             ; when enter was presses. "\n" was written in buffer
    je .empty_line

    call _generate_tokens
    test rax, rax
    jl .error_parsing_input

    call _process_token_generate_commands
    test rax, rax
    jl .error_parocessing_token

    call _execute_commands


    ; DEALLOCATE THE parsed_string_object
    lea rdi, [rel parsed_string_object]
    call _destructor_mystring

    ret

    .empty_line:
    .error_parocessing_token:
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

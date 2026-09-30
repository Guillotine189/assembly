%include "./dep/constants.inc"
%include "../dependencies/mystring.inc"
%include "../dependencies/dynamicarray.inc"



section .data
    
        

section .rodata

    
    dot db ".",0
    double_dot_slash db "../", 0
    back_slash db "/"
    dot_back_slash db "./", 0
    dash db '-',0
    semicolon db ":" , 0
    dollar_sign_with_space db "$ ", 0
    new_line db 0x0a, 0
    null_qword dq 0




global command_argc_dynamic_array_object
global command_argv_dynamic_array_object
global last_command_exit_code_ascii
section .bss
    
    child_pid resq 0
    child_pgid resq 0

    pipe_for_command resd 2             ; 2fd:  4bytes each, [read, write]
    pipe_read_buffer_child resb 8

    pipe_array resb DYNAMICARRAY_OBJECT_SIZE

    last_command_exit_code_ascii resb 32

    command_argc_dynamic_array_object resb DYNAMICARRAY_OBJECT_SIZE
    command_argv_dynamic_array_object resb DYNAMICARRAY_OBJECT_SIZE

    address_command resb 8


extern shell_pgid
extern last_command_exit_code_ascii
extern exit_status_code
extern error_code
extern _exit_with_status_code

extern _itoa
extern _cmp_equal_memory

extern print_error_command_not_found
extern print_error_getting_pipes
extern print_error_forking
extern child_print_error_executing_process
extern parent_print_error_closing_read_pipe
extern parent_print_error_setting_gpid_for_child
extern parent_print_error_moving_child_to_fg
extern parent_print_error_synchronizing_with_child
extern parent_print_error_closing_write_pipe


extern _check_and_execute_if_built_in
extern _check_if_cmd_is_in_path

extern _set_noncanonical_mode
extern _set_canonical_mode
extern _reset_signal


section .text
global _execute_commands

global _set_last_command_exit_code
_set_last_command_exit_code:
    ; write to exit code ascii, 0
    mov rax, 0
    lea rdi, [rel last_command_exit_code_ascii]
    call _itoa
    ret










_execute_commands:
    mov rax, -1
    ret

    ; create 1 pipe for group syncing
    ; create a envp_array from shell_env, a general envp array for commands to inherit

    ; parent_loop
    ; loop through command array
    ; if the command index is 'n'
    ; if all commands done: go to start_execution
    ; close the both pipe at n-2 index o pipe_array if exists
    ; check redirect_out struct
    ;       : if type_pipe      : create a new pipe, and add it to pipe_array

    ;fork()
    ; parent: set/change pgid for child
    ; parent_loop

    ; child
    ; TODO: change the env functions to not rely on predefined variables, expect addresses to come from parameters
    ; change pgid
    ; close parents sync-pipe write-end
    ; restore signal handling
    ; check if the env_array has any extra env variable
    ;           : if it's len > 0: add the shell env variables from general array created above. including null
    ;           ; if len = 0: continue
    ; 
    ; check redirect_in struct
    ;       : if type_pipe: access pipe_array[n-1][0], Use dup2 to change fd 0 to that. close [n-1][1]
    ;       ; if type_other: check if i can open(o_ronly). Error->exit, else change fd1 to the fd of that.
    ;       ; if type_default: continue
    ; check redirect_out
    ;       ; if type_pipe: access pipe_array[n][1] and dup2 to point fd 1 to that. close [n][0]
    ;       ; if type_other: check if i can open(o_wonly, o_create, O_truncate). Error->exit, else change fd1 to the fd of that.
    ;       ; if type_default: continue
    ; Setup envp_array for execve
    ; env_array from process token
    ;           : if it's len > 0: that means i added some extra env var. Use this in execve
    ;           ; if len = 0: use the default env_arr created above
    ; wait for sync signal(read 1 byte)
    ; execve(argc_address, argv_array, envp_array)

    ; start_execution
    ; close last pipe couple.
    ; put pgid in fg
    ; release children through sync pipe, write a total of N bytes, one per child.
    ; close parents sync-pipe write end
    ; wait4 all childs to finish
    ; cleanup
    ; put shell in fg

    ; why use a synchronization pipe?
    ; ans: if the child reaches execve before it's put into fg, and if it tries to access terminal settings/read/write, then the terminal will send it stop signal to it.
    ; and because i have resetted the signals, it will stop the process immediately, most probably if it hasn't set the signal again.

    ; sync_pipe question:
    ; Q) A parent can send a signal to pgid and all the childs inside that pgid that are listening will recv it
    ; but if the child has yet to call read(), and the parent closes the pipe after writing, what will happen?
    ; Ans: because the pipe data still exists (closing pipe from parent's end does not mean data from pipe buffer is lost),
    ; the child will still be able to read the data.



_execute_commands_old:

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
    lea rsi, [rel command_argc_dynamic_array_object]
    mov rsi, [rsi + DYNAMICARRAY_POINTER_OFF]
    lea rdx, [rel command_argv_dynamic_array_object]
    mov rdx, [rdx + DYNAMICARRAY_POINTER_OFF]
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
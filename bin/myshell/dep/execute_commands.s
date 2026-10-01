%include "./dep/constants.inc"
%include "../dependencies/mystring.inc"
%include "../dependencies/dynamicarray.inc"



section .data

    pipe_for_sync dq 0        ; to start all child at same time
    pgid_commands dq 0

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
global last_command_exit_code_ascii_len
section .bss
    
    child_pid resq 0
    child_pgid resq 0

    pipe_for_command resd 2             ; 2fd:  4bytes each, [read, write]
    pipe_read_buffer_child resb 8


    last_command_exit_code_ascii resb 32
    last_command_exit_code_ascii_len resq 1

    command_argc_dynamic_array_object resb DYNAMICARRAY_OBJECT_SIZE
    command_argv_dynamic_array_object resb DYNAMICARRAY_OBJECT_SIZE

    address_command resb 8

    ; ------------
    pipe_array resb DYNAMICARRAY_OBJECT_SIZE      ; the array that contain info about redirection
    temp_pipe_buffer resd 2
    common_shell_env_var_array_object resb DYNAMICARRAY_OBJECT_SIZE

    sync_pipe_buffer resb 10

extern shell_pgid
extern last_command_exit_code_ascii
extern exit_status_code
extern error_code
extern _exit_with_status_code

extern shell_env_array_object

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


extern _execute_if_built_in
extern _check_if_cmd_is_in_path
extern _check_if_cmd_is_built_in

extern _set_noncanonical_mode
extern _set_old_termios
extern _reset_signal
extern _exit

extern command_array




section .text
global _execute_commands

global _update_last_command_exit_code
global _set_last_command_exit_code

; rdi: the command exit code
_update_last_command_exit_code:
    mov rax, rdi
    lea rdi, [rel last_command_exit_code_ascii]
    call _itoa
    mov qword [rel last_command_exit_code_ascii_len], rax
    ret

_set_last_command_exit_code:
    ; write to exit code ascii, 0
    mov rax, 0
    lea rdi, [rel last_command_exit_code_ascii]
    call _itoa
    mov qword [rel last_command_exit_code_ascii_len], 1
    ret


_reset_child_signals:
    
    mov rdi, SIGINT
    call _reset_signal
    mov rdi, SIGTSTP
    call _reset_signal
    mov rdi, SIGTTOU
    call _reset_signal
    mov rdi, SIGTTIN
    call _reset_signal
    ret






    ; check if it's a single bic command: if yes -> setup common env, process env extra, execute
    ; create 1 pipe for group syncing
    ; create a envp_array from shell_env, a general envp array for commands to inherit
    ; initialize pipe array

    ; set old termios
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
    ; set pgid 
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
    ; restore signal handling
    ; wait for sync signal(read 1 byte)
    ; close the both sync pipe read
    ; final check: if the command is built in or not, or if it can be found in path
    ; execve(argc_address, argv_array, envp_array)
    ; handle error execve


    ; start_execution
    ; close last pipe couple.
    ; put pgid in fg
    ; release children through sync pipe, write a total of N bytes, one per child.
    ; close parents sync-pipe write end
    ; wait4 all childs to finish (n chidren = n wait4 calls)
    ; cleanup (change the procee group id to 0)
    ; set non canonical mode
    ; put shell in fg

    ; why use a synchronization pipe?
    ; ans: if the child reaches execve before it's put into fg, and if it tries to access terminal settings/read/write, then the terminal will send it stop signal to it.
    ; and because i have reset the signals, it will stop the process immediately, most probably if it hasn't set the signal again.

    ; sync_pipe question:
    ; Q) A parent can send a signal to pgid and all the childs inside that pgid that are listening will recv it
    ; but if the child has yet to call read(), and the parent closes the pipe after writing, what will happen?
    ; Ans: because the pipe data still exists (closing pipe from parent's end does not mean data from pipe buffer is lost),
    ; the child will still be able to read the data.


_execute_commands:
    mov qword [rel pgid_commands], 0
    mov qword [rel pipe_for_sync], 0     ; i know it's 8 bytes long
    
    ; build_common_envp_array 
    xor r12, r12                              ; which env struct am i checking
    lea r13, [rel shell_env_array_object]      ; r13 is the shell array object
    mov r14, [r13 + DYNAMICARRAY_POINTER_OFF]  ; r14 now points to string object array

    ; go through shell_env_array and add addresses of env that have exported = 1

    lea rdi, [rel common_shell_env_var_array_object]
    mov rax, [r13 + DYNAMICARRAY_SIZE_OFF]
    add rax, 5                      ; asking for space for 5 more now so it won't ask malloc again
    mov qword [rdi + DYNAMICARRAY_CAPACITY_OFF], rax
    mov qword [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF], 8      ; storing addresses in this 
    mov qword [rdi + DYNAMICARRAY_POINTER_OFF], 0
    mov qword [rdi + DYNAMICARRAY_SIZE_OFF], 0
    call _default_dynamic_array_constructor

    test rax,  rax
    jl .error_initializing_common_env_array

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
        lea rdi, [rel common_shell_env_var_array_object]
        call _dynamic_array_add_element
        ; todo: handld error

        inc r12
        jmp .loop_shell_env_array

    .done_adding_shell_env_var:
    ; add a null address after them
    ; r13 is shell_env_array_object
    lea rdi, [rel common_shell_env_var_array_object]
    lea rsi, [rel null_qword]
    call _dynamic_array_add_element
    ;todo: handle error


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



    lea r12, [rel command_array]              ; r12: commmand array object address


    ; check if i only have to execute 1 command
    cmp [r12 + DYNAMICARRAY_SIZE_OFF], 1    ; if only 1 command and builtin
    jne .continue

    ; check if it's built in
    mov rdi, [r12 + DYNAMICARRAY_POINTER_OFF]  ; this will be the 1st command struct address
    call _check_if_cmd_is_built_in   ; this will exit if 
    test rax, rax
    je .execute_single_bic_command


    .continue:
    ; get pipe
    mov rax, sys_pipe
    lea rdi, [rel pipe_for_sync]
    syscall 

    test rax, rax
    jl .error_getting_sync_pipe


    ; now initialize pipe array

    lea rdi, [rel pipe_array]
    mov qword [rdi + DYNAMICARRAY_CAPACITY_OFF], 4          ; 4 pipe pair are more than enough
    mov qword [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF], 8      ; storing pipe pair that are 8bytes a pair
    mov qword [rdi + DYNAMICARRAY_POINTER_OFF], 0
    mov qword [rdi + DYNAMICARRAY_SIZE_OFF], 0
    call _default_dynamic_array_constructor
    ;todo: handle error

    call _set_old_termios



    xor r13, r13                              ; r13: idx for looping through command structs
    .loop_parent_setup_child:

        mov rax, [r12 + DYNAMICARRAY_SIZE_OFF]
        cmp rax, r13               ; compare size of command array with idx of current command
        je .all_commands_ready_for_execution

        mov rax, r13
        sub rax, 2
        test rax, rax
        jl .no_pipe_pair_to_close

        ; else close the old pipe pair that are no longer needed
        lea rdi, [rel pipe_array]
        mov rsi, rax
        call _dynamic_array_get_element_address             ; get the pipe pair for this index
        ; todo: handle error

        mov r14, rax                                   ; save element address is r14

        mov edi, [r14]              ; the read end of pipe pair
        mov rax, sys_close
        syscall

        mov edi, [r14 + 4]          ; the write end of the pipe, [4bytes for each pipe]
        mov rax, sys_close
        syscall

        .no_pipe_pair_to_close:
        ; now check the redirect_out for this command

        mov rdi, r12                                    ; r12: address of command_arr_obj
        mov rsi, r13                                    ; r13: idx of current command
        call _dynamic_array_get_element_address         ; get the current command address struct in rax
        ; todo: handle error

        lea rax, [rax + COMMAND_STRUCT_ROUT_STRUCT_OFF]    ; rax: the address of redirect struct
        mov rax, [rax + REDIRECT_STRUCT_TYPE_OFF]          ; rax: the type of redirect out

        cmp rax, REDIRECT_TYPE_PIPE
        jne .no_pipe_needed

        ; else i need to create a pipe for this command to send output to
        lea rdi, [rel temp_pipe_buffer]     ; i will temporarily get pipes in this array, the add this to the pipe array
        mov rax, sys_pipe
        syscall

        test rax, rax
        jl .error_getting_pipe

        ; add the pipes into pipe array
        lea rdi, [rel pipe_array]
        lea rsi, [rel temp_pipe_buffer]
        call _dynamic_array_add_element
        ; todo: handle error

        .no_pipe_needed:

        mov rax, sys_fork
        syscall

        test rax, rax
        je .child
        jl .error_forking

        ; change pgid for group if first child
        ; rax: has the pid of child process
        mov rcx, [rel pgid_commands]

        test rcx, rcx
        jnz .pgid_already_set

        ; else make the pgid equal to this 1st child's process
        mov [rel pgid_commands], rax

        .pgid_already_set:


        ; make sure child is in the process group. This is done here to avoid race
        mov rdi, rax                    ; the pid who you want to add
        mov rsi, [rel pgid_commands]    ; the pgid you want to be added in
        mov rax, sys_setpgid
        syscall
        ; todo: handle error


        inc r13
        jmp .loop_parent_setup_child


    .all_commands_ready_for_execution:

    lea rax, [rel pipe_array]
    mov rax, [rax + DYNAMICARRAY_SIZE_OFF]
    dec rax

    test rax, rax
    jl .no_pipe_to_close

    lea rdi, [rel pipe_array]
    mov rsi, rax
    call _dynamic_array_get_element_address         ; get the 2 pipes
    ; todo: handle error

    mov r13, rax                        ; r13: save address of pipes 
    mov rax, sys_close
    mov edi, [r13]
    syscall

    mov rax, sys_close
    mov edi, [r13 + 4]
    syscall

    .no_pipe_to_close:

    ; make child the fg process in terminal 
    mov rax, sys_ioctl
    mov rdi, 0                  ; fd of the temrinal / the controlling terminal
    mov rsi, TIOCSPGRP          ; 0x5410
    lea rdx, [rel pgid_commands]
    syscall
    ; TODO: handle error for moving child to foreground


    lea r13, [rel command_array]
    mov r13, [r13 + DYNAMICARRAY_SIZE_OFF]
    .loop_put_bytes_into_write_sync_pipe:

        test r13, r13
        je .done_writing_in_pipe

        mov rax, sys_write
        mov rdi, [rel pipe_for_sync + 4]
        lea rsi, [rel dot]
        mov rdx, 1                  ; write 1 bytes '.' for every command
        syscall 

        ; todo: error writing to pipe

        dec r13
        jmp .loop_put_bytes_into_write_sync_pipe

    .done_writing_in_pipe:
    call .close_read_sync_pipe
    call .close_write_sync_pipe
    ; todo: error

    lea r13, [rel command_array]
    mov r13, [r13 + DYNAMICARRAY_SIZE_OFF]
    
    .loop_reap_all_children:
        test r13, r13
        je .all_children_exited

        ; reap child group
        mov rax, sys_wait4   ;syscall number
        mov rdi, [rel pgid_commands] 
        neg rdi                 ; -ve pid means i have given it a pgid
        xor rsi, rsi     ;where to store exit status(For simply waiting, NULL/0 is fine)
        xor rdx, rdx     ;how to wait
        xor r10, r10      ;where to store resource usage
        syscall

        dec r13
        jmp .loop_reap_all_children

    .all_children_exited:
    ; TODO: handle error for waiting

    ; child finished, now take the shell back to foreground
    mov rax, sys_ioctl
    xor rdi, rdi
    mov rsi, TIOCSPGRP
    lea rdx, [rel shell_pgid]
    syscall

    ; TODO: dont reset non-canonical, save the old state and apply it
    call _set_noncanonical_mode
    call .cleanup
    ret


    .cleanup:
        mov qword [rel pgid_commands], 0
        mov qword [rel pipe_for_sync], 0     ; i know it's 8 bytes long
        lea rdi, [rel common_shell_env_var_array_object]
        call _dynamic_array_clear
        ret



    .error_getting_sync_pipe:
        mov [rel error_code], rax
        call print_error_getting_pipes  ;TODO: change error to say sync pipe
        ret

    .error_initializing_common_env_array:
        ; TODO: PROPER ERROR HANDLING
        mov rax, -1
        ret

    .error_getting_pipe:
        ; TODO: PROPER ERROR
        mov [rel error_code], rax
        call print_error_getting_pipes
        ret
        
    .error_forking:
        ; TODO: proper error handling
        mov [rel error_code], rax
        call print_error_forking
        ret



    .execute_single_bic_command:

        ; if it's len > 0: add the shell env variables from general array created above. including null
        ; if len = 0: continue

        mov r13, [r12 + DYNAMICARRAY_POINTER_OFF]        ; r14: address of current command struct

        ; add the common shell env inside the command struct envp onject

        xor r12, r12                                        ; which string am i checking
        lea r15, [r13 + COMMAND_STRUCT_ENVP_OBJ_OFF]        ; r15: the address of envp array inside command struct
        lea r14, [rel common_shell_env_var_array_object]    ; r14 is the common envp array object

        ; go through common shell_env_array and add everythign into this envp array

        .loop_shell_env_array3:

            cmp r12, [r14 + DYNAMICARRAY_SIZE_OFF]
            je .done_adding             ; the common one already includes a NULL qword

            mov rax, r12
            mov rcx, [r14 + DYNAMICARRAY_ELEMENT_SIZE_OFF]
            mul rcx

            ; dont care about the buffer overflow, probably will never happen
            ; rax now has the offset for which string object to check
            mov rcx, [r14 + DYNAMICARRAY_POINTER_OFF]
            lea rsi, [rcx + rax]   ; rsi now points to the string object
            
            ; rsi has the address which points to the address of string
            ; i want to copy the address of string inside array. so i need to give the address of address of string
            mov rdi, r15
            call _dynamic_array_add_element
            ; todo: handle error

            inc r12
            jmp .loop_shell_env_array3

        .done_adding:
        mov rdi, r13
        call _execute_if_built_in   ; i know it's built in
        call .cleanup
        ret






    ; r13 has the idx number for command
    .child:

        ; close the write part of pipe for child, no need
        call .close_write_sync_pipe
        test rax, rax
        jl .child_error_closing_write_pipe

        ; change pgid
        mov rax, [rel pgid_commands]

        test rax, rax           ; if pgid is already set, 
        jnz .use_already_set_pgid

        ; else set the gpid of child to be it's own pid
        mov rax, sys_setpgid
        xor rdi, rdi               ; pid = 0  -> change pgid for current process
        xor rsi, rsi               ; gpid = 0 -> use current process's PID as gpid
        syscall

        test rax, rax
        jl .child_error_setting_gpid
        jmp .check_redirect_in

        .use_already_set_pgid:

        mov rax, sys_setpgid
        xor rdi, rdi                    ; pid = 0  -> change pgid for current process
        mov rsi, [rel pgid_commands]    ; gpid i want to set
        syscall

        test rax, rax
        jl .child_error_setting_gpid

        .check_redirect_in:
        ; check redirect in struct
        ; r13 has idx for current command


        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address
        ; todo: handle error

        mov r14, rax                        ; r14: the address of current command struct

        lea rax, [r14 + COMMAND_STRUCT_RIN_STRUCT_OFF]
        mov rax, [rax + REDIRECT_STRUCT_TYPE_OFF]   ; rax: type of redirect

        cmp rax, REDIRECT_TYPE_PIPE
        je .handle_redirect_in_pipe

        cmp rax, REDIRECT_TYPE_OTHER
        je .handle_redirect_in_other

        ; if redirect_in is default, continue
        jmp .check_redirect_out

        .handle_redirect_in_pipe:
        ; if type_pipe: access pipe_array[n-1][0], Use dup2 to change fd 0 to that. close [n-1][1]
        ; dup2 the read end of pipe pair, and close the write end basically
        ; r13: idx or n

        lea rdi, [rel pipe_array]
        mov rsi, r13
        dec rsi         ; only command with idx > 0 will have type_pipe, so i can safely subtract 1
        call _dynamic_array_get_element_address
        ; todo: error handling

        ; rax has the address of pipe_Array[n-1]
        mov r14, rax                                    ; save this address of pipe_array[n-1]

        ; Make pipe_read become stdin
        mov rax, sys_dup2
        mov edi, [r14]        ; oldfd/the one you want to change = pipe_read
        mov rsi, 0            ; newfd/the one you want to become = stdin
        syscall
        ; todo: handle error

        ; close both pipes, RN: fd0 points to same object the pipe pointed to. I can close the pipes
        mov edi, [r14 + 4]               ; a pipe is 4 bytes long, so pipe write is 4 bytes ahead
        mov rax, sys_close
        syscall
        mov edi, [r14]
        mov rax, sys_close
        syscall

        ; todo: handle error
        jmp .check_redirect_out

        .handle_redirect_in_other:
        ; r14 has current command struct address
        ; if type_other: check if i can open(o_ronly). Error->exit, else change fd0 to the fd of that.

        mov rax, sys_open
        mov rdi, [r14 + COMMAND_STRUCT_RIN_STRUCT_OFF + REDIRECT_STRUCT_ADDRESS_OFF]
        mov rsi, O_RDONLY
        syscall
        ; todo: give error if i cannot open this and exit

        mov r15, rax

        mov rdi, r15                ; old fd: the one i want new fd to point to
        mov rsi, 0                  ; new fd: the one that will point to old fd
        mov rax, sys_dup2
        syscall
        ; todo: error handling and exit

        ; close the fd of file
        mov rax, sys_close
        mov rdi, r15
        syscall

        ; todo: error handling and exit
        jmp .check_redirect_out

        .check_redirect_out:
        ; if type_pipe: access pipe_array[n][1] and dup2 to point fd 1 to that. close [n][0]
        ; r13: idx or n

        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address
        ; todo: handle error

        mov r14, rax                        ; r14: the address of current command struct

        mov rax, [r14 + COMMAND_STRUCT_ROUT_STRUCT_OFF + REDIRECT_STRUCT_TYPE_OFF]
        ; rax: type of redirect out

        cmp rax, REDIRECT_TYPE_PIPE
        je .handle_redirect_out_pipe

        cmp rax, REDIRECT_TYPE_OTHER
        je .handle_redirect_out_other

        ; if type_default, continue
        jmp .setup_env_array

        .handle_redirect_out_pipe:
        ; if type_pipe: access pipe_array[n][1] and dup2 to point fd 1 to that. close [n][0]
        ; r13: idx or n

        lea rdi, [rel pipe_array]
        mov rsi, r13
        call _dynamic_array_get_element_address
        ; todo: error handling

        ; rax has the address of pipe_Array[n]
        mov r14, rax                                    ; save this address of pipe_array[n-1]

        ; Make pipe_read become stdin
        mov rax, sys_dup2
        mov edi, [r14 + 4]        ; oldfd/the one you want to change = pipe_read
        mov rsi, 1            ; newfd/the one that will point to the same object as old = stdout
        syscall
        ; todo: handle error

        ; close both pipes, RN: fd1 points to same object the pipe pointed to. I can close the pipes
        mov edi, [r14 + 4]               ; a pipe is 4 bytes long, so pipe write is 4 bytes ahead
        mov rax, sys_close
        syscall

        mov edi, [r14]               ; a pipe is 4 bytes long, so pipe write is 4 bytes ahead
        mov rax, sys_close
        syscall
        ; todo: handle error
        jmp .setup_env_array


        .handle_redirect_out_other:
        ; if type_other: check if i can open(o_wonly, o_create, O_truncate). Error->exit, else change fd1 to the fd of that.
        mov rax, sys_open
        mov rdi, [r14 + COMMAND_STRUCT_ROUT_STRUCT_OFF + REDIRECT_STRUCT_ADDRESS_OFF]
        mov rsi, O_WRONLY | O_TRUNC | O_CREAT
        mov rdx, 0666q                    ; read+write
        syscall
        ; todo: give error if i cannot create this and exit

        mov rdi, rax                ; old fd: the one i want to become
        mov rsi, 1            ; newfd/the one that will point to the same object as old = stdout
        mov rax, sys_dup2
        syscall
        ; todo: error handling and exit
        jmp .setup_env_array

        .setup_env_array:
        ; if it's len > 0: add the shell env variables from general array created above. including null
        ; if len = 0: continue
        ; r13: idx of command

        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address
        ; todo: handle error

        mov r14, rax                            ; r14: address of current command struct

        lea rax, [r14 + COMMAND_STRUCT_ENVP_OBJ_OFF]
        mov rax, [rax + DYNAMICARRAY_SIZE_OFF]  ; rax: size of envp array

        test rax, rax
        je .no_change_in_envp_array

        ; else i have added a temp env into the array, i now need to add the common envp array into this array

        xor r12, r12                                        ; which env struct am i checking
        lea r15, [r14 + COMMAND_STRUCT_ENVP_OBJ_OFF]        ; r15: the address of envp array object i want to add into
        lea r14, [rel common_shell_env_var_array_object]    ; r14 is the shell array object i an adding from

        ; go through common shell_env_array and add everythign into this envp array

        .loop_shell_env_array2:

            cmp r12, [r14 + DYNAMICARRAY_SIZE_OFF]
            je .no_change_in_envp_array             ; the common one already includes a NULL qword

            mov rax, r12
            mov rcx, [r14 + DYNAMICARRAY_ELEMENT_SIZE_OFF]
            mul rcx

            ; dont care about the buffer overflow, probably will never happen
            ; rax now has the offset for which string object to check
            mov rcx, [r14 + DYNAMICARRAY_POINTER_OFF]
            lea rsi, [rcx + rax]   ; rsi now points to the string object
            
            ; rsi has the address which points to the address of string
            ; i want to copy the address of string inside array. so i need to give the address of address of string
            mov rdi, r15
            call _dynamic_array_add_element
            ; todo: handle error

            inc r12
            jmp .loop_shell_env_array2

        .no_change_in_envp_array:

        ; restore signal handling
        call _reset_child_signals         ; childs signals have been restored to default

        ; wait for signal from shell
        ; it will put the pgid into fg before i do anything

        mov rax, sys_read
        mov edi, [rel pipe_for_sync]
        lea rsi, [rel sync_pipe_buffer]
        mov rdx, 1                  ; only read 1 byte
        syscall

        ; close the read sync pipe
        call .close_read_sync_pipe
        ; todo: handle error



        ; now i can execve, but i have to decide which envp array to use
        ; the common one or the specialized one
        ; r13: the idx of current command

        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address
        ;todo: handle errror
        ; rax: the address of current command struct
        mov r12, rax

        ; final check: if command it can be found in $PATH
        mov rdi, r12
        call _execute_if_built_in
        ; if it's builtin, it will directly execute and exit, so part after of this doesn't matter

        test rax, rax
        je _exit

        mov rdi, [r12 + COMMAND_STRUCT_NAME_OFF]
        call _check_if_cmd_is_in_path

        test rax, rax
        jl .final_command_construction

        ; else the final command was inside PATH
        mov [r12 + COMMAND_STRUCT_NAME_OFF], rax

        .final_command_construction:

        lea r8, [r12 + COMMAND_STRUCT_ENVP_OBJ_OFF] ; r8: the address of envp array object 
        mov rcx, [r8 + DYNAMICARRAY_SIZE_OFF]  ; rcx: the size of envp array

        test rcx, rcx
        je .use_common_env_array

        mov rdx, [r8 + DYNAMICARRAY_POINTER_OFF] ; rdx: the address of array of edited envp pointers
        jmp .run_command

        .use_common_env_array:
        lea rdx, [rel common_shell_env_var_array_object]
        mov rdx, [rdx + DYNAMICARRAY_POINTER_OFF]   ; rsi: the address of array or common envp pointers

        .run_command:

        .execve:
        mov rdi, [r12 + COMMAND_STRUCT_NAME_OFF]        ; this conatins the addres of command name
        lea rsi, [r12 + COMMAND_STRUCT_ARGV_OBJ_OFF]
        mov rsi, [rsi + DYNAMICARRAY_POINTER_OFF]       ; rsi: the address containing argv array
        mov rax, sys_execve
        syscall


        ;--------------------------------------
        ; explicitly end for testing
        mov rax, 60
        mov rdi, -2
        syscall
        ;--------------------------------------

        ; anything after this is error
        ; todo: handle


    .close_sync_pipes:
        mov rax, sys_close
        mov edi, [rel pipe_for_sync]
        syscall

        mov rax, sys_close
        mov edi, [rel pipe_for_sync + 4]
        syscall
        ret


    .close_read_sync_pipe:
        mov rax, sys_close
        mov edi, [rel pipe_for_sync]
        syscall
        ret

    .close_write_sync_pipe:
        mov rax, sys_close
        mov edi, [rel pipe_for_sync + 4]
        syscall
        ret




    .child_error_closing_write_pipe:
        ; TODO: PROPER ERROR
        mov [rel exit_status_code], rax
        call .close_read_sync_pipe
        ret


    .child_error_setting_gpid:
        ; TODO : ERROR proper
        mov [rel exit_status_code], rax   ; the og error code why checnging gpid failed
        call .close_read_sync_pipe
        ret











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
    call _execute_if_built_in
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

    call _set_old_termios                ; terminal is now canonical
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


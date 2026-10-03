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
    export_command db "export", 0
    underscore_equals_to_word db "_=", 0


global last_command_exit_code_ascii
global last_command_exit_code_ascii_len
section .bss

    pipe_array resb DYNAMICARRAY_OBJECT_SIZE      ; the array that contain info about redirection
    temp_pipe_buffer resd 2
    common_shell_env_var_array_object resb DYNAMICARRAY_OBJECT_SIZE

    sync_pipe_buffer resb 8
    last_child_exit_mask resb 4         ; wait4 write 4bytes of value into exit code variable

    last_command_exit_code_ascii resb 32
    last_command_exit_code_ascii_len resq 1

    reusable_buffer_execute_command resb 512

extern shell_pgid
extern exit_status_code
extern error_code
extern _exit_with_status_code

extern shell_env_array_object

extern _itoa
extern _cmp_equal_memory
extern _strcmp
extern _string_copy_including_null

extern print_error_initializing_common_env_array_obj
extern print_error_initializing_pipe_array
extern print_error_adding_to_common_env_array
extern print_error_getting_sync_pipes
extern print_error_getting_redirection_pipe
extern print_error_getting_pipe_array_element
extern print_error_appending_pipe_array
extern print_error_changing_child_pgid
extern print_error_forking
extern print_error_moving_child_to_fg
extern print_error_writing_to_pipe_for_syncing
extern print_error_putting_shell_into_fg


extern print_child_error_closing_write_pipe
extern print_child_error_setting_gpid
extern print_child_error_getting_command_array_element
extern print_child_error_getting_pipe_array_element
extern print_child_error_changing_redirect_in_fd
extern print_child_error_opening_redirect_in_dest
extern print_child_error_changing_redirect_out_fd
extern print_child_error_opening_redirect_out_dest
extern print_child_error_adding_shell_env_var_to_arr
extern child_print_error_executing_process

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
    ; Make sure the code returned here is a 64bit value
    ; eg: os returns 4byte value, make it compatible with 8byte register

    ; i know last_child_exit_mask has the value (not always like if single command and bic), but i use this var in other part of program
    mov [rel exit_status_code], rdi

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
    mov qword [rel last_command_exit_code_ascii_len], rax
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
    jl .error_initializing_common_env_array_obj

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

        test rax, rax
        js .error_adding_common_env_array

        inc r12
        jmp .loop_shell_env_array


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


    .done_adding_shell_env_var:

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
    ; get sync pipe
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
    
    test rax, rax
    jl .error_initializing_pipe_array

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
        
        test rax, rax
        jl .error_getting_pipe_array_element

        mov r14, rax                                   ; save element address is r14

        mov edi, [r14]              ; the read end of pipe pair
        mov rax, sys_close
        syscall

        mov dword [r14], -1         ; mark them as closed

        mov edi, [r14 + 4]          ; the write end of the pipe, [4bytes for each pipe]
        mov rax, sys_close
        syscall

        mov dword [r14 + 4], -1         ; mark them as closed

        .no_pipe_pair_to_close:
        ; now check the redirect_out for this command

        mov rdi, r12                                    ; r12: address of command_arr_obj
        mov rsi, r13                                    ; r13: idx of current command
        call _dynamic_array_get_element_address         ; get the current command address struct in rax

        test rax, rax
        jl .error_getting_pipe_array_element


        ; check if current command is the last command, else create a pipe
        lea rax, [rel command_array]
        mov rax, [rax + DYNAMICARRAY_SIZE_OFF]          ; rax: total commands
        dec rax                                         ; rax: total commands - 1

        cmp r13, rax
        je .no_pipe_needed

        ; else i need to create a pipe for this command to send output to
        lea rdi, [rel temp_pipe_buffer]     ; i will temporarily get pipes in this array, the add this to the pipe array
        mov rax, sys_pipe
        syscall

        test rax, rax
        jl .error_getting_redirection_pipe

        ; add the pipes into pipe array
        lea rdi, [rel pipe_array]
        lea rsi, [rel temp_pipe_buffer]
        call _dynamic_array_add_element
        
        test rax, rax
        jl .error_appending_pipe_array

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
    
        test rax, rax
        jl .error_changing_child_pgid

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
    
    test rax, rax
    jl .error_getting_pipe_array_element

    mov r13, rax                        ; r13: save address of pipes 
    mov rax, sys_close
    mov edi, [r13]
    syscall

    mov dword [r13], -1

    mov rax, sys_close
    mov edi, [r13 + 4]
    syscall

    mov dword [r13 + 4], -1

    .no_pipe_to_close:

    ; make child the fg process in terminal 
    mov rax, sys_ioctl
    mov rdi, 0                  ; fd of the temrinal / the controlling terminal
    mov rsi, TIOCSPGRP          ; 0x5410
    lea rdx, [rel pgid_commands]
    syscall
    
    test rax, rax
    jl .error_moving_child_to_fg


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

        test rax, rax
        jl .error_writing_to_pipe_for_syncing

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
        lea rsi, [rel last_child_exit_mask]     ;where to store exit status, 1byte will be written to this address
        xor rdx, rdx     ;how to wait
        xor r10, r10      ;where to store resource usage
        syscall

        test rax, rax               ; if rax >= 0 -> child successfully reaped
        jns .loopback

        cmp rax, -EINTR             ; if wait4 was interrupted, retry
        je .loop_reap_all_children

        cmp rax, -ECHILD            ; if no child process, it sends ECHILD. This is a defensive approach. I don't really need it.
        je .all_child_process_reaped

        ; TODO: if there is an error reaping child, exit probably, or retry sometimes
        ; jmp .error_reaping_child

    .loopback:
        dec r13
        jmp .loop_reap_all_children

    .all_children_exited:
    
    ; only care about exit code of last child reaped
    ; update command wants exit code to be 8byte value
    ; the code inside last_child_exit_mask is only 1 byte and if -ve, i need to make it compatible with rdi
    ; 4bytes in last_child_exit_mask: [irrelevant_2_bytes | exit_code_1_byte | irrelevant_1_byte]

    mov eax, [rel last_child_exit_mask]

    ; if the child was terminated by a signal
    mov edx, eax
    and edx, 0x7f
    jnz .child_exited_because_of_signal

    ; normal exit
    shr eax, 8                          ; the code has 1byte of padding/irrelevant data at end, then it has 1byte for exit code, then 2 bytes of irrelevant data
    and eax, 0xff                       ; i only need the first 1 byte of eax register which has exit code
    mov edi, eax
    call _update_last_command_exit_code
    jmp .retry_shell_fg

    .child_exited_because_of_signal:
    ; eax contains the raw wait status
    and eax, 0x7f          ; signal number
    add eax, 128           ; Bash-style $? = 128 + signal
    mov edi, eax
    call _update_last_command_exit_code
    jmp .retry_shell_fg


    ; child finished, now take the shell back to foreground
    .retry_shell_fg:
        
        mov rax, sys_ioctl
        xor rdi, rdi
        mov rsi, TIOCSPGRP
        lea rdx, [rel shell_pgid]
        syscall

        cmp rax, -EINTR
        je .retry_shell_fg

        test rax, rax
        js .error_putting_shell_into_fg


    ; TODO: dont reset non-canonical, save the old state and apply it
    call _set_noncanonical_mode
    call .cleanup
    call .reset
    ret

    .cleanup:
        call _free_common_env_var_array_object
        call .close_both_sync_pipes
        call _free_pipe_array_object
        ret


    .reset:
        mov qword [rel pgid_commands], 0
        mov qword [rel pipe_for_sync], 0     ; i know it's 8 bytes long
        ret

    .error_initializing_common_env_array_obj:
        mov [rel error_code], rax
        call print_error_initializing_common_env_array_obj
        jmp .return_failure

    .error_adding_common_env_array:
        mov [rel error_code], rax
        call print_error_adding_to_common_env_array
        call _free_common_env_var_array_object
        jmp .return_failure

    .error_getting_sync_pipe:
        mov [rel error_code], rax
        call print_error_getting_sync_pipes  ;TODO: change error to say sync pipe
        call _free_common_env_var_array_object
        jmp .return_failure

    .error_initializing_pipe_array:
        mov [rel error_code], rax
        call print_error_initializing_pipe_array
        call _free_common_env_var_array_object
        call .close_both_sync_pipes
        jmp .return_failure

    .error_getting_pipe_array_element:
        mov [rel error_code], rax
        call print_error_getting_pipe_array_element
        call .kill_and_reap_child_processes
        call _free_common_env_var_array_object
        call .close_both_sync_pipes
        call _free_pipe_array_object
        jmp .return_failure

    .error_appending_pipe_array:
        mov [rel error_code], rax
        call print_error_appending_pipe_array
        call .kill_and_reap_child_processes
        call _free_common_env_var_array_object
        call .close_both_sync_pipes
        call _free_pipe_array_object
        jmp .return_failure


    .error_getting_redirection_pipe:
        mov [rel error_code], rax
        call print_error_getting_redirection_pipe
        call .kill_and_reap_child_processes
        call _free_common_env_var_array_object
        call .close_both_sync_pipes
        call _free_pipe_array_object
        jmp .return_failure

    .error_changing_child_pgid:
        mov [rel error_code], rax
        call print_error_changing_child_pgid
        call .kill_and_reap_child_processes
        call _free_common_env_var_array_object
        call .close_both_sync_pipes
        call _free_pipe_array_object
        jmp .return_failure

    .error_forking:
        ; r13: the idx of command which failed
        mov [rel error_code], rax
        call print_error_forking
        call .kill_and_reap_child_processes
        call _free_common_env_var_array_object
        call .close_both_sync_pipes
        call _free_pipe_array_object
        jmp .return_failure

    .error_moving_child_to_fg:
        mov [rel error_code], rax
        call print_error_moving_child_to_fg
        call .kill_and_reap_child_processes
        call _free_common_env_var_array_object
        call .close_both_sync_pipes
        call _free_pipe_array_object
        jmp .return_failure

    .error_writing_to_pipe_for_syncing:
        mov [rel error_code], rax
        call print_error_writing_to_pipe_for_syncing

        ; kill_and_reap expects r13 to contains the total child forked and needs to be reaped
        lea r13, [rel command_array]
        mov r13, [r13 + DYNAMICARRAY_SIZE_OFF]
        call .kill_and_reap_child_processes

        call _free_common_env_var_array_object
        call .close_both_sync_pipes
        call _free_pipe_array_object
        jmp .return_failure

    .error_putting_shell_into_fg:
        mov [rel error_code], rax
        call print_error_putting_shell_into_fg
        ; at this point i must exit
        mov [rel exit_status_code], 1
        call _exit_with_status_code
    
    .kill_and_reap_child_processes:
        ; r13: already has the idx of commmand which failed
        ; kill and reap all the child processes
        mov rax, [rel pgid_commands]
        test rax, rax                          ; if pgid not set, no child process exists
        je .all_child_process_reaped
        ; else i must kill the pgid, and reap all childrens

        mov rax, sys_kill
        mov rdi, [rel pgid_commands]  
        neg rdi
        mov rsi, SIGKILL
        syscall

        ; whether kill succeeded or not,  doesn't matter
        ; try to reap all the child processes.

        ; r13: already has the idx of commmand which failed
        .loop_reap_all_children2:
            test r13, r13
            je .all_child_process_reaped   ; all child process reaped

            ; reap child group
            mov rax, sys_wait4   ;syscall number
            mov rdi, [rel pgid_commands] 
            neg rdi                 ; -ve pid means i have given it a pgid
            lea rsi, [rel last_child_exit_mask]     ;where to store exit status, 4bytes will be written to this address
            xor rdx, rdx     ;how to wait
            xor r10, r10      ;where to store resource usage
            syscall

            test rax, rax               ; if rax > 0 -> child successfully reaped
            jns .child_reaped

            cmp rax, -EINTR             ; if wait4 was interrupted, retry
            je .loop_reap_all_children2

            cmp rax, -ECHILD            ; if no child process, it sends ECHILD. This is a defensive approach. I don't really need it.
            je .all_child_process_reaped

            ; TODO: if there is an error reaping child, exit probably, or retry sometimes
            ; jmp .error_reaping_child

        .child_reaped:
            dec r13
            jmp .loop_reap_all_children2

        .all_child_process_reaped:
            ret



    .execute_single_bic_command:
        ; if bic is 'export'
        ; they need the "foo=bar" as a argument, not as envp_var
        ; so as a special case, i will only pass the env variables provided by user in envp_Array
        ; the bic function will iterate through all the envp_var given by user and update them in shell env

        mov r13, [r12 + DYNAMICARRAY_POINTER_OFF]        ; r13: address of current command struct

        mov rax, [r13 + COMMAND_STRUCT_NAME_OFF]        ; rcx has name for command
        lea rdi, [rel export_command]
        call _strcmp
        test rax, rax   ; if it is export, dont add the shell env 
        je .done_adding

        ; if it's len > 0: add the shell env variables from general array created above. including null
        ; if len = 0: continue


        ; add the common shell env inside the command struct envp onject

        xor r12, r12                                        ; which string am i checking
        lea r15, [r13 + COMMAND_STRUCT_ENVP_OBJ_OFF]        ; r15: the address of envp array inside command struct
        lea r14, [rel common_shell_env_var_array_object]    ; r14 is the common envp array object

        ; go through common shell_env_array and add everythign into this envp array, common does not contain NULL
        .loop_shell_env_array3:
            cmp r12, [r14 + DYNAMICARRAY_SIZE_OFF]
            je .add_underscore_env_var             ; the common one already includes a NULL qword

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

            test rax, rax
            js .error_adding_common_env_array

            inc r12
            jmp .loop_shell_env_array3

        .add_underscore_env_var:
        ; i need to add the _=command_name into env var

        ; buffer = [_=./program,NULL,ADDRESS_8_BYTES]
        ;           | address of this 
        ; copy "_=" into buffer, then append the command name and add this as env var
        lea rdi, [rel reusable_buffer_execute_command]
        lea rsi, [rel underscore_equals_to_word]
        mov rcx, 2
        rep movsb

        ; rdi is at next address
        mov rsi, [r13 + COMMAND_STRUCT_NAME_OFF]        ; r12: the address of name of command
        call _string_copy_including_null

        inc rdi
        lea rsi, [rel reusable_buffer_execute_command]
        mov [rdi], rsi

        mov rsi, rdi
        mov rdi, r15
        call _dynamic_array_add_element

        mov rdi, r15
        lea rsi, [rel null_qword]
        call _dynamic_array_add_element

        .done_adding:
        mov rdi, r13
        call _execute_if_built_in   ; i know it's built in
        call _free_common_env_var_array_object
        call .reset
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
        
        test rax, rax
        jl .child_error_getting_command_array_element

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
        test rax, rax
        jl .child_error_getting_pipe_array_element


        ; rax has the address of pipe_Array[n-1]
        mov r14, rax                                    ; save this address of pipe_array[n-1]

        ; Make pipe_read become stdin
        mov rax, sys_dup2
        mov edi, [r14]        ; oldfd/the one you want to change = pipe_read
        mov rsi, 0            ; newfd/the one you want to become = stdin
        syscall
        
        test rax, rax
        jl .child_error_changing_redirect_in_fd

        ; close both pipes, RN: fd0 points to same object the pipe pointed to. I can close the pipes
        mov edi, [r14 + 4]               ; a pipe is 4 bytes long, so pipe write is 4 bytes ahead
        mov rax, sys_close
        syscall
        mov edi, [r14]
        mov rax, sys_close
        syscall

        jmp .check_redirect_out

        .handle_redirect_in_other:
        ; r14 has current command struct address
        ; if type_other: check if i can open(o_ronly). Error->exit, else change fd0 to the fd of that.

        mov rax, sys_open
        mov rdi, [r14 + COMMAND_STRUCT_RIN_STRUCT_OFF + REDIRECT_STRUCT_ADDRESS_OFF]
        mov rsi, O_RDONLY
        syscall
        
        test rax, rax
        jl .child_error_opening_redirect_in_dest

        mov r15, rax

        mov rdi, r15                ; old fd: the one i want new fd to point to
        mov rsi, 0                  ; new fd: the one that will point to old fd
        mov rax, sys_dup2
        syscall
        
        test rax, rax
        jl .child_error_changing_redirect_in_fd

        ; close the fd of file
        mov rax, sys_close
        mov rdi, r15
        syscall

        jmp .check_redirect_out

        .check_redirect_out:
        ; if type_pipe: access pipe_array[n][1] and dup2 to point fd 1 to that. close [n][0]
        ; r13: idx or n

        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address
        test rax, rax
        jl .child_error_getting_command_array_element

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
        test rax, rax
        jl .child_error_getting_pipe_array_element

        ; rax has the address of pipe_Array[n]
        mov r14, rax                                    ; save this address of pipe_array[n-1]

        ; Make pipe_read become stdin
        mov rax, sys_dup2
        mov edi, [r14 + 4]        ; oldfd/the one you want to change = pipe_read
        mov rsi, 1            ; newfd/the one that will point to the same object as old = stdout
        syscall
        test rax, rax
        jl .child_error_changing_redirect_out_fd

        ; close both pipes, RN: fd1 points to same object the pipe pointed to. I can close the pipes
        mov edi, [r14 + 4]               ; a pipe is 4 bytes long, so pipe write is 4 bytes ahead
        mov rax, sys_close
        syscall

        mov edi, [r14]               ; a pipe is 4 bytes long, so pipe write is 4 bytes ahead
        mov rax, sys_close
        syscall

        jmp .setup_env_array


        .handle_redirect_out_other:
        ; if type_other: check if i can open(o_wonly, o_create, O_truncate). Error->exit, else change fd1 to the fd of that.
        mov rax, sys_open
        mov rdi, [r14 + COMMAND_STRUCT_ROUT_STRUCT_OFF + REDIRECT_STRUCT_ADDRESS_OFF]
        mov rsi, O_WRONLY | O_TRUNC | O_CREAT
        mov rdx, 0666q                    ; read+write
        syscall
        test rax, rax
        jl .child_error_opening_redirect_out_dest

        mov rdi, rax                ; old fd: the one i want to become
        mov rsi, 1            ; newfd/the one that will point to the same object as old = stdout
        mov rax, sys_dup2
        syscall
        test rax, rax
        jl .child_error_changing_redirect_out_fd

        jmp .setup_env_array

        .setup_env_array:
        ; if it's len > 0: add the shell env variables from general array created above. including null
        ; if len = 0: continue
        ; r13: idx of command

        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address
        test rax, rax
        jl .child_error_getting_command_array_element

        mov rbx, rax                            ; rbx: address of current command struct

        lea rax, [rbx + COMMAND_STRUCT_ENVP_OBJ_OFF]
        mov rax, [rax + DYNAMICARRAY_SIZE_OFF]  ; rax: size of envp array

        test rax, rax
        je .use_commmon_envp_array

        ; else i have added a temp env into the array, i now need to add the common envp array into this array

        xor r12, r12                                        ; which env struct am i checking
        lea r15, [rbx + COMMAND_STRUCT_ENVP_OBJ_OFF]        ; r15: the address of envp array object i want to add into
        lea r14, [rel common_shell_env_var_array_object]    ; r14 is the shell array object i an adding from

        ; go through common shell_env_array and add everythign into this envp array

        .loop_shell_env_array2:

            cmp r12, [r14 + DYNAMICARRAY_SIZE_OFF]
            je .add_underscore_env_var_and_null             ; the common one dos not includes a NULL qword

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
            test rax, rax
            jl .child_error_adding_shell_env_var_to_arr

            inc r12
            jmp .loop_shell_env_array2

        .add_underscore_env_var_and_null:
        lea rdi, [rel reusable_buffer_execute_command]
        lea rsi, [rel underscore_equals_to_word]
        mov rcx, 2
        rep movsb

        ; rdi is at next address
        mov rsi, [rbx + COMMAND_STRUCT_NAME_OFF]        ; rsi: the address of name of command
        call _string_copy_including_null

        inc rdi
        lea rsi, [rel reusable_buffer_execute_command]
        mov [rdi], rsi

        mov rsi, rdi
        mov rdi, r15
        call _dynamic_array_add_element
        test rax, rax
        jl .child_error_adding_shell_env_var_to_arr

        mov rdi, r15
        lea rsi, [rel null_qword]
        call _dynamic_array_add_element
        test rax, rax
        jl .child_error_adding_shell_env_var_to_arr

        jmp .wait_for_signal

        .use_commmon_envp_array:

        lea rdi, [rel reusable_buffer_execute_command]
        lea rsi, [rel underscore_equals_to_word]
        mov rcx, 2
        rep movsb

        ; rdi is at next address
        mov rsi, [rbx + COMMAND_STRUCT_NAME_OFF]        ; rsi: the address of name of command
        call _string_copy_including_null

        inc rdi
        lea rsi, [rel reusable_buffer_execute_command]
        mov [rdi], rsi

        mov rsi, rdi
        lea rdi, [rel common_shell_env_var_array_object]
        call _dynamic_array_add_element
        test rax, rax
        jl .child_error_adding_shell_env_var_to_arr

        lea rdi, [rel common_shell_env_var_array_object]
        lea rsi, [rel null_qword]
        call _dynamic_array_add_element
        test rax, rax
        jl .child_error_adding_shell_env_var_to_arr


        .wait_for_signal:

        ; wait for signal from shell
        ; it will put the pgid into fg before i do anything

        mov rax, sys_read
        mov edi, [rel pipe_for_sync]
        lea rsi, [rel sync_pipe_buffer]
        mov rdx, 1                  ; only read 1 byte
        syscall

        ; close the read sync pipe
        call .close_read_sync_pipe

        ; now i can execve, but i have to decide which envp array to use
        ; the common one or the specialized one
        ; r13: the idx of current command

        ; i am not in the foreground, so now i can safely reset the signal
        ; restore signal handling
        call _reset_child_signals         ; childs signals have been restored to default

        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address
        test rax, rax
        jl .child_error_getting_command_array_element

        ; rax: the address of current command struct
        mov r12, rax

        ; final check: if command it can be found in $PATH
        mov rdi, r12
        call _execute_if_built_in
        ; if it's builtin, it will directly execute and send signal if it 

        test rax, rax
        jne .check_if_cmd_in_path_env_var

        mov rdi, [rel exit_status_code]
        call _exit_with_status_code

        .check_if_cmd_in_path_env_var:
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

        ; this part only executes when execve fails inside child process

        ; here the exit code is returned in rax not in al, so -1 is 1111111...1110
        mov [rel error_code], rax
        mov rdi, [r12 + COMMAND_STRUCT_NAME_OFF]
        call child_print_error_executing_process

        ; map the error code from execve to exit code that will be displayed by my shell
        ; rn i am using bash like mapping

        mov rax, [rel error_code]

        ; 2   ENOENT   No such file/directory   127
        ; 13  EACCES   Permission denied        126
        ; 8   ENOEXEC  Exec format error        126
        ; 21  EISDIR   Is a directory           126
        ; 20  ENOTDIR  Not a directory          126
        ; 40  ELOOP    Too many symbolic links  126
        ; 36  ENAMETOOLONG  Filename too long   126
        ; 12  ENOMEM   Cannot allocate memory   126
        ; 7   E2BIG    Argument list too long   126
        ; 14  EFAULT   Bad address              126
        ; 26  ETXTBSY  Text file busy           126

        cmp rax, -ENOENT
        je .exit_code_127

        mov [rel exit_status_code], 126
        jmp .exit_

        .exit_code_127:
            mov [rel exit_status_code], 127
            jmp .exit_


        .exit_:
        mov rax, 60
        mov rdi, [rel exit_status_code]
        syscall




    .close_both_sync_pipes:
        call .close_read_sync_pipe
        call .close_write_sync_pipe
        ret


    .close_read_sync_pipe:
        mov edi, [rel pipe_for_sync]
        test edi, edi
        jl .read_already_closed

        mov rax, sys_close
        syscall
        mov dword [rel pipe_for_sync], -1   ; mark this as closed

        .read_already_closed:
        ret

    .close_write_sync_pipe:
        lea r8, [rel pipe_for_sync]
        mov edi, [r8 + 4]
        test edi, edi
        jl .write_already_closed

        mov rax, sys_close
        syscall

        mov dword [r8 + 4], -1   ; mark this as closed
        .write_already_closed:
        ret




    .child_error_closing_write_pipe:
        ; r13: has idx for command struct in array
        mov [rel error_code], rax
        mov [rel exit_status_code], 1
            
        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address

        test rax, rax
        jl _exit_with_status_code  ; if i fail to get this just exit child forcefully

        mov rdi, [rax + COMMAND_STRUCT_NAME_OFF]
        call print_child_error_closing_write_pipe

        call .close_read_sync_pipe
        call _exit_with_status_code


    .child_error_setting_gpid:
        mov [rel error_code], rax
        mov [rel exit_status_code], 1
        
        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address

        test rax, rax
        jl _exit_with_status_code  ; if i fail to get this just exit child forcefully

        mov rdi, [rax + COMMAND_STRUCT_NAME_OFF]
        call print_child_error_setting_gpid

        call .close_read_sync_pipe
        call _exit_with_status_code


    .child_error_getting_command_array_element:
        ; r13: has idx for command struct in array
        mov [rel error_code], rax
        mov [rel exit_status_code], 1
        
        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address

        test rax, rax
        jl _exit_with_status_code  ; if i fail to get this just exit child forcefully

        mov rdi, [rax + COMMAND_STRUCT_NAME_OFF]
        call print_child_error_getting_command_array_element

        call .close_read_sync_pipe
        call _exit_with_status_code

    .child_error_getting_pipe_array_element:

        mov [rel error_code], rax
        mov [rel exit_status_code], 1
        
        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address

        test rax, rax
        jl _exit_with_status_code  ; if i fail to get this just exit child forcefully

        mov rdi, [rax + COMMAND_STRUCT_NAME_OFF]
        call print_child_error_getting_pipe_array_element

        call .close_read_sync_pipe
        call _exit_with_status_code

    .child_error_changing_redirect_in_fd:
        ; r13: has idx for command struct in array
        mov [rel error_code], rax
        mov [rel exit_status_code], 1
        
        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address

        test rax, rax
        jl _exit_with_status_code  ; if i fail to get this just exit child forcefully

        mov rdi, [rax + COMMAND_STRUCT_NAME_OFF]
        call print_child_error_changing_redirect_in_fd

        call .close_read_sync_pipe
        call _exit_with_status_code

    .child_error_opening_redirect_in_dest:
        ; r13: has idx for command struct in array
        mov [rel error_code], rax
        mov [rel exit_status_code], 1
        
        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address

        test rax, rax
        jl _exit_with_status_code  ; if i fail to get this just exit child forcefully

        mov rdi, [rax + COMMAND_STRUCT_NAME_OFF]
        lea rsi, [rax + COMMAND_STRUCT_RIN_STRUCT_OFF]
        mov rsi, [rsi + REDIRECT_STRUCT_ADDRESS_OFF]
        call print_child_error_opening_redirect_in_dest

        call .close_read_sync_pipe
        call _exit_with_status_code


    .child_error_changing_redirect_out_fd:
        ; r13: has idx for command struct in array
        mov [rel error_code], rax
        mov [rel exit_status_code], 1
        
        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address

        test rax, rax
        jl _exit_with_status_code  ; if i fail to get this just exit child forcefully

        mov rdi, [rax + COMMAND_STRUCT_NAME_OFF]
        call print_child_error_changing_redirect_out_fd

        call .close_read_sync_pipe
        call _exit_with_status_code

    .child_error_opening_redirect_out_dest:
        ; r13: has idx for command struct in array
        mov [rel error_code], rax
        mov [rel exit_status_code], 1
        
        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address

        test rax, rax
        jl _exit_with_status_code  ; if i fail to get this just exit child forcefully

        mov rdi, [rax + COMMAND_STRUCT_NAME_OFF]
        lea rsi, [rax + COMMAND_STRUCT_ROUT_STRUCT_OFF]
        mov rsi, [rsi + REDIRECT_STRUCT_ADDRESS_OFF]
        call print_child_error_opening_redirect_out_dest

        call .close_read_sync_pipe
        call _exit_with_status_code

    .child_error_adding_shell_env_var_to_arr:
        ; r13: has idx for command struct in array
        mov [rel error_code], rax
        mov [rel exit_status_code], 1
        
        lea rdi, [rel command_array]
        mov rsi, r13
        call _dynamic_array_get_element_address

        test rax, rax
        jl _exit_with_status_code  ; if i fail to get this just exit child forcefully

        mov rdi, [rax + COMMAND_STRUCT_NAME_OFF]
        call print_child_error_adding_shell_env_var_to_arr

        call .close_read_sync_pipe
        call _exit_with_status_code



    .return_success:
        xor rax, rax
        ret

    .return_failure:
        mov rax, -1
        ret

_free_common_env_var_array_object:
    lea rdi, [rel common_shell_env_var_array_object]
    call _default_dynamic_array_destructor
    ret

_free_pipe_array_object:
    ; i have to close all the pipes inside this array, (it's ok it some are already closed)

    lea r15, [rel pipe_array]

    mov r12, [r15 + DYNAMICARRAY_SIZE_OFF]
    mov r13, [r15 + DYNAMICARRAY_POINTER_OFF]
    xor r14, r14                ; idx for getting element
    .loop_close_pipes_inside_pipe_array:
        cmp r14, r12
        je .free_pipe_array_object

        mov rdi, r15
        mov rsi, r14
        call _dynamic_array_get_element_address     ; rax willl have the pipes [read, write]
        ; todo: what to do if this gives error

        mov r8, rax

        mov edi, [r8]
        test edi, edi
        js .close_write      ; if it's -ve, i have already close it 
        ;[i usually close both pipes together(above) so i can actually go to .loopback here, but maybe in future i might change it, so this is a safety net]

        mov rax, sys_close
        syscall

        .close_write:
        
        mov edi, [r8 + 4]
        test edi, edi
        js .loopback      ; if it's -ve, i have already close it

        mov rax, sys_close
        syscall

    .loopback:
        inc r14
        jmp .loop_close_pipes_inside_pipe_array

    .free_pipe_array_object:
    lea rdi, [rel pipe_array]
    call _default_dynamic_array_destructor
    ret

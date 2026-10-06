%include "./dep/constants.inc"
%include "../dependencies/dynamicarray.inc"

section .data
	error_changing_dir db "MyShell: cd: Error changing directory: ", 0
	error_changing_dir_len equ $ - error_changing_dir

	error_cd_too_many_args db "MyShell: cd: Error changing directory: too many arguments provided.",0
	error_cd_too_many_args_len equ $ - error_cd_too_many_args

	error_home_env_not_set db "MyShell: cd: Error 'HOME' env variable is not present.", 0
	error_home_env_not_set_len equ $ - error_home_env_not_set

	error_adding_path_var db "Error exporting path variable: ", 0
	error_adding_path_var_len equ  $ - error_adding_path_var


section .rodata
	
	cursor_clear_screen db 27, "[2J", 27, "[3J", 27, "[H", 0
	cursor_clear_screen_len equ $ - cursor_clear_screen
	; ESC[2J     erase entire visible screen
	; ESC[3J     erase scrollback buffer
	; ESC[H      move cursor to home


	dot db ".",0
	back_slash db "/"
	dot_back_slash db "./", 0
	dash db '-',0
	space_byte db " ", 0

    home_env_var db "HOME", 0

    cd_ 			db "cd",0
    pwd_ 			db "pwd",0
    export_ 		db "export", 0
    unset_  		db "unset", 0
    clear_ 			db "clear", 0
    exit_ 			db "exit",0
    history_ 		db "history", 0


section .bss
	reusable_buffer_bif resb 4096

section .text

; funcs
extern _print
extern _print_with_new_line
extern _string_copy_including_null
extern _print_error_with_new_line
extern _strcmp
extern _cmp_equal_memory
extern _strlen
extern _mem_copy
extern _memcpy_with_end_char
extern _itoa

extern _set_prefix_line

; var
extern error_code
extern curr_cwd
extern curr_cwd_len
extern old_cwd
extern old_cwd_len

extern _exit_with_status_code


extern _find_var_in_shell_env
extern _update_var_in_shell_env
extern _unset_var_in_shell_env
extern _print_env_from_object

extern _print_history

extern _update_last_command_exit_code

extern _exit

sys_chdir           equ 80


global _execute_if_built_in
global _check_and_return_command_if_bic
global _check_if_cmd_is_built_in

; rdi: the address of command struct
_execute_if_built_in:
	push r12
	push r13
	push r14
	push r15


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


	mov r13, rdi
	mov r12, [r13 + COMMAND_STRUCT_NAME_OFF] 		; r12 has the address for name of command
	lea r15, [r13 + COMMAND_STRUCT_ARGV_OBJ_OFF]    ; r15:object for argc includes null
	lea r14, [r13 + COMMAND_STRUCT_ENVP_OBJ_OFF]     ; r14: the object argv array address

    mov rax, r12
    lea rdi, [rel cd_]
    call _strcmp
    test rax, rax
    je .check_and_execute_cd

    mov rax, r12
    lea rdi, [rel pwd_]
    call _strcmp
    test rax, rax
    je .check_and_execute_pwd

    mov rax, r12
    lea rdi, [rel clear_]
    call _strcmp
    test rax, rax
    je .clear_screen

    mov rax, r12
    lea rdi, [rel history_]
    call _strcmp
    test rax, rax
    je .print_history_and_ret

    mov rax, r12
    lea rdi, [rel export_]
    call _strcmp
    test rax, rax
    je .update_shell_env

    mov rax, r12
    lea rdi, [rel unset_]
    call _strcmp
    test rax, rax
    je .unset_shel_env

    mov rax, r12
    lea rdi, [rel exit_]
    call _strcmp

    test rax, rax
    je _exit

    .not_built_in:
    	pop r15
    	pop r14
    	pop r13
    	pop r12
	    ret


    .check_and_execute_cd:

        mov rdi, r15   ; 2nd argument is the path name
        ; cd path arg > 2 -> not valid, but There is a NULL as argument in end
        cmp qword [rdi + DYNAMICARRAY_SIZE_OFF], 3
        jg .error_cd_too_many_args
        jl .move_to_home_dir

        mov rdi, [rdi + DYNAMICARRAY_POINTER_OFF]
        add rdi, 8
        mov rdi, [rdi]
        push rdi

        ; check if the argument is '-'
        lea rax, [rel dash] 				; cehck if '-'0 same as argument
        call _strcmp
        test rax, rax
        je .go_to_old_pwd

        lea rax, [rel space_byte] 				; cehck if argument is ' '
        call _strcmp
        test rax, rax
        je .move_to_home_dir

        pop rdi
        call _builtin_cd
        test rax, rax
    	jl .error_changing_dir0

    	xor rdi, rdi
    	call _update_last_command_exit_code
    	jmp .return_built_in

    	.error_changing_dir0:
    	mov rdi, 1
    	call _update_last_command_exit_code
        jmp .return_built_in


        .go_to_old_pwd:
        	pop rdi
        	cmp qword [rel old_cwd], 0
        	je .return_built_in 		; if old does not exists, return

        	lea rdi, [rel old_cwd] 
        	call _builtin_cd
        	test rax, rax
        	jl .error_changing_dir

        	xor rdi, rdi
        	call _update_last_command_exit_code
        	jmp .success_changin_dir

        	.error_changing_dir:
        	mov rdi, 1
        	call _update_last_command_exit_code

        	.success_changin_dir:
        	jmp .return_built_in
            
        .move_to_home_dir:

        	lea rdi, [rel home_env_var]     ; which env var i want to search
        	mov rsi, 4  					; len of home env
        	call _find_var_in_shell_env  		; returns address of home env var, after "HOME="
        	test rax, rax
        	jl .error_home_env_not_set

        	mov rdi, rax
        	call _builtin_cd
        	test rax, rax
        	jl .error_changing_dir2

        	xor rdi, rdi
        	call _update_last_command_exit_code
        	jmp .success_changin_dir2

        	.error_changing_dir2:
        	mov rdi, 1
        	call _update_last_command_exit_code

        	.success_changin_dir2:
			jmp .return_built_in


        .error_cd_too_many_args:

        	mov rax, error_cd_too_many_args_len
		    mov rdi, 2
		    lea rsi, [rel error_cd_too_many_args]
		    call _print_with_new_line

		    mov rdi, 2
		    call _update_last_command_exit_code
		    jmp .return_built_in

		.error_home_env_not_set:
			mov rax, error_home_env_not_set_len
		    mov rdi, 2
		    lea rsi, [rel error_home_env_not_set]
		    call _print_with_new_line

		    mov rdi, 2
		    call _update_last_command_exit_code
		    jmp .return_built_in
		    
        
    .check_and_execute_pwd:
        call _builtin_pwd

	    xor rdi, rdi
	    call _update_last_command_exit_code
        jmp .return_built_in

    .clear_screen:
	    mov rax, sys_write              ; sys
		mov rdi, 1              ; fd 1
		lea rsi, [rel cursor_clear_screen]
		mov rdx, cursor_clear_screen_len
		syscall

	    xor rdi, rdi
	    call _update_last_command_exit_code
		jmp .return_built_in

	.print_history_and_ret:
		call _print_history

	    xor rdi, rdi
	    call _update_last_command_exit_code
		jmp .return_built_in


	.update_shell_env:
		; r14: the address of envp array object
		; the array conains a NULL as an argument
		mov r13, r14   
        mov r13, [r13 + DYNAMICARRAY_POINTER_OFF]
        mov r15, [r14 + DYNAMICARRAY_SIZE_OFF]
        ; the env variables are stored in env array, all the ones user provided
        ; followed by null, no other env variables are present in this case
     	mov r14, 0
		.loop_set_env_vars:
	        cmp r14, r15  				; if idx = size
			je .done2

			mov rdi, [r13]
			call _update_var_in_shell_env
			test rax, rax
			jl .error_invalid_var

			add r13, 8 					; move check the next address

		    xor rdi, rdi
		    call _update_last_command_exit_code

		.loopback:
			inc r14
			jmp .loop_set_env_vars

		.error_invalid_var:
			; TODO: print invaid env supplied

			mov rax, error_adding_path_var_len
			mov rdi, 2
			lea rsi, [rel error_adding_path_var]
			call _print

			mov rdi, r12
			call _strlen

			mov rdi, 2
			mov rsi, r12
			call _print_with_new_line

		    mov rdi, 2
		    call _update_last_command_exit_code
			jmp .loopback

	.unset_shel_env:

		; the array conains a NULL as an argument
		mov r13, r15   ; 2nd argument is the path name
        mov r13, [r13 + DYNAMICARRAY_POINTER_OFF]

        ; 0th argument is command name, last argument is NULL
     	mov r14, 1
		.loop_unset_env_vars:
	        mov r12, [r13 + r14*8] 					; read the actual argument address
			cmp r12, 0  				; if i have reached the null arg
			je .done2

			mov rdi, r12
			call _unset_var_in_shell_env

			inc r14
			jmp .loop_unset_env_vars

        .done2:
        xor rdi, rdi
        call _update_last_command_exit_code
		jmp .return_built_in


    .return_built_in:
    	pop r15
    	pop r14
    	pop r13
    	pop r12
    	xor rax, rax
    	ret



; rdi: new location address
; r15: the address of argv array object
_builtin_cd:
	mov rax, sys_chdir
	syscall

	test rax, rax
	jl .error_changing_dir

	; TODO: this is a hack, [get cwd and update it], instead normalize path yourself.
	mov rax, sys_getcwd
    lea rdi, [rel reusable_buffer_bif]
    mov rsi, 4096
    syscall                  ; ret: len cwd including NULL in rax,and cwd in buffer

    


    ; move current cwd into old cwd
    lea rdi, [rel curr_cwd]
    call _strlen

    mov [rel old_cwd_len], rax

    lea rdi, [rel old_cwd] 				; destination
    lea rsi, [rel curr_cwd] 				; source
    mov rdx, 0
    mov r8, 1  						; copies 0 at end
    call _memcpy_with_end_char  					; now my cur is old

    ; update current

    lea rdi, [rel reusable_buffer_bif]
    call _strlen

    mov [rel curr_cwd_len], rax

    lea rdi, [rel curr_cwd]
	lea rsi, [rel reusable_buffer_bif] 				; source
    mov rdx, 0
    mov r8, 1  						; copies 0 at end
    call _memcpy_with_end_char  					; now my cur is old

	call _set_prefix_line

	xor rax, rax
	ret

	.error_changing_dir:
		mov [rel error_code], rax
		mov rax, error_changing_dir_len
		mov rdi, 2
		lea rsi, [rel error_changing_dir]
		call _print

		mov rdi, r15
		mov rdi, [rdi + DYNAMICARRAY_POINTER_OFF]
		add rdi, 8    				; offset of arg1 address
		mov rdi, [rdi]
		call _strlen

		mov rdi, 2
		mov rsi, r15
		mov rsi, [rsi + DYNAMICARRAY_POINTER_OFF]
		add rsi, 8
		mov rsi, [rsi]
		call _print

		mov rdi, [rel error_code]
		call _print_error_with_new_line
		mov rax, -1
		ret

	

_builtin_pwd:
	mov rax, [rel curr_cwd_len]
	mov rdi, 1
	lea rsi, [rel curr_cwd]
	call _print_with_new_line
	ret



; rdi: address of string
; rsi: len of string
; checks is if the string matches any built in commnads, if it does returns the command address
_check_and_return_command_if_bic:
	push r12
	push r13

	mov r12, rdi 					; r12: address of command
	mov r13, rsi 					; r13: len of memory to compare

	mov rax, r13
    lea rdi, [rel cd_]
    mov rsi, r12
    call _cmp_equal_memory

    test rax, rax
    je .return_cd

    mov rax, r13
    lea rdi, [rel pwd_]
    mov rsi, r12
    call _cmp_equal_memory

    test rax, rax
    je .return_pwd

    mov rax, r13
    lea rdi, [rel clear_]
    mov rsi, r12
    call _cmp_equal_memory

    test rax, rax
    je .return_clear

    mov rax, r13
    lea rdi, [rel history_]
    mov rsi, r12
    call _cmp_equal_memory

    test rax, rax
    je .return_his

    mov rax, r13
    lea rdi, [rel export_]
    mov rsi, r12
    call _cmp_equal_memory

    test rax, rax
    je .return_export


    mov rax, r13
    lea rdi, [rel unset_]
    mov rsi, r12
    call _cmp_equal_memory

    test rax, rax
    je .return_unset


    mov rax, r13
    lea rdi, [rel exit_]
    mov rsi, r12
    call _cmp_equal_memory

    test rax, rax
    je .return_exit

    .not_built_in:
	    mov rax, -1
	    jmp .return

	.return_cd:
		lea rax, [rel cd_]
		jmp .return

	.return_pwd:
		lea rax, [rel pwd_]
		jmp .return

	.return_his:
		lea rax, [rel history_]
		jmp .return

	.return_clear:
		lea rax, [rel clear_]
		jmp .return

	.return_export:
		lea rax, [rel export_]
		jmp .return

	.return_unset:
		lea rax, [rel unset_]
		jmp .return

	.return_exit:
		lea rax, [rel exit_]
		jmp .return

	.return:
		pop r13
		pop r12
		ret


; rdi: the address of command struct
; returns: rax: 0 if command is a built in
; 		      :  -ve if not
_check_if_cmd_is_built_in:
	push r12

	mov r12, [rdi + COMMAND_STRUCT_NAME_OFF] 		; r12 has the address for name of command

    mov rax, r12
    lea rdi, [rel cd_]
    call _strcmp
    test rax, rax
    je .built_in

    mov rax, r12
    lea rdi, [rel pwd_]
    call _strcmp
    test rax, rax
    je .built_in

    mov rax, r12
    lea rdi, [rel clear_]
    call _strcmp
    test rax, rax
    je .built_in

    mov rax, r12
    lea rdi, [rel history_]
    call _strcmp
    test rax, rax
    je .built_in

    mov rax, r12
    lea rdi, [rel export_]
    call _strcmp
    test rax, rax
    je .built_in

    mov rax, r12
    lea rdi, [rel unset_]
    call _strcmp
    test rax, rax
    je .built_in

    mov rax, r12
    lea rdi, [rel exit_]
    call _strcmp
    test rax, rax
    je .built_in

    .not_built_in:
    	pop r12
    	mov rax, -1
	    ret

	.built_in:
		pop r12
		xor rax, rax
		ret
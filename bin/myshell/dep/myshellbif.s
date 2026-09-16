%include "./dep/constants.inc"

section .data
	error_changing_dir db "Error changing directory: ", 0
	error_changing_dir_len equ $ - error_changing_dir

	error_cd_too_many_args db "Error changing directory: too many arguments provided.",0
	error_cd_too_many_args_len equ $ - error_cd_too_many_args

	error_home_env_not_set db "Error 'HOME' env variable is not present.", 0
	error_home_env_not_set_len equ $ - error_home_env_not_set


section .rodata
	
	cursor_clear_screen db 27, "[2J", 27, "[H", 0
	cursor_clear_screen_len equ $ - cursor_clear_screen
	; ESC [ 2 J    -> clear entire screen
	; ESC [ H      -> move cursor [1,1]


	dot db ".",0
	back_slash db "/"
	dot_back_slash db "./", 0
	dash db '-',0

    cd db "cd",0
    pwd db "pwd",0
    clear db "clear", 0
    exit db "exit",0
    history db "history", 0
    home_env_var db "HOME", 0

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

extern _set_prefix_line

; var
extern error_code
extern curr_cwd
extern curr_cwd_len
extern old_cwd
extern old_cwd_len

extern address_argc_address_array
extern address_envp_address_array
extern address_command
extern total_command_aruments

extern _print_history

extern _exit

sys_chdir           equ 80


global _check_and_execute_if_built_in




; returns rax : address of home env variable
_find_home_env_variable:
	xor r8 ,r8 							; this will store which env var i am checking

	.check_next_env_var:
		mov rax, [rel address_envp_address_array]
		mov rdx, r8
		shl rdx, 3
		add rax, rdx
		; rax = [address_envp_address_array + r8*8]
		
		mov rcx, [rax]			; rcx now stores the address of env variable

		cmp rcx, 0 		  	; if the value is NULL, i have reached the end of envp variba
		je .home_not_found

		xor r9, r9 				; idx for going over the env var
	.check_this_address:

		cmp byte [rcx + r9], '='
		je .check_len_and_home
		inc r9

		cmp r9, 4 						; HOME is 4 in len
		jg .check_next_var
		jmp .check_this_address


	.check_len_and_home:
		cmp r9, 4
		jne .check_next_var

		push rcx
		push r8

		mov rax, 4
		lea rdi, [rel home_env_var]
		mov rsi, rcx
		call _cmp_equal_memory

		pop r8
		pop rcx

		test rax, rax
		je .home_found
		jmp .check_next_var


	.check_next_var:
		inc r8
		jmp .check_next_env_var

	.home_found:
		mov rax, rcx
		ret

	.home_not_found:
		mov rax, -1
		ret

_check_and_execute_if_built_in:

    mov rax, [rel address_command]
    lea rdi, [rel cd]
    call _strcmp

    test rax, rax
    je .check_and_execute_cd

    mov rax, [rel address_command]
    lea rdi, [rel pwd]
    call _strcmp

    test rax, rax
    je .check_and_execute_pwd


    mov rax, [rel address_command]
    lea rdi, [rel clear]
    call _strcmp

    test rax, rax
    je .clear_screen

    mov rax, [rel address_command]
    lea rdi, [rel history]
    call _strcmp

    test rax, rax
    je .print_history_and_ret



    mov rax, [rel address_command]
    lea rdi, [rel exit]
    call _strcmp

    test rax, rax
    je _exit

    .not_built_in:
	    mov rax, 1
	    ret


    .check_and_execute_cd:

        cmp [rel total_command_aruments], 2             ; cd path parg3 -> not valid
        jg .error_cd_too_many_args
        jl .move_to_home_dir

        ; TODO: set location of directory
        mov rdi, [rel address_argc_address_array]   ; 2nd argument is the path name
        add rdi, 8
        mov rdi, [rdi]
        push rdi

        ; check if the argument is '-'
        lea rax, [rel dash] 				; cehck if '-'0 same as argument
        call _strcmp
        test rax, rax
        je .go_to_old_pwd

        pop rdi
        call _builtin_cd
        jmp .return_built_in


        .go_to_old_pwd:
        	pop rdi
        	cmp qword [rel old_cwd], 0
        	je .return_built_in 		; if old does not exists, return

        	lea rdi, [rel old_cwd] 
        	call _builtin_cd
        	jmp .return_built_in
            
        .move_to_home_dir:

        	call _find_home_env_variable  		; returns address of home env var
        	test rax, rax
        	jl .error_home_env_not_set

        	mov rdi, rax
        	add rdi, 5
        	call _builtin_cd
			jmp .return_built_in


        .error_cd_too_many_args:

        	mov rax, error_cd_too_many_args_len
		    mov rdi, 1
		    lea rsi, [rel error_cd_too_many_args]
		    call _print_with_new_line
		    jmp .return_built_in

		.error_home_env_not_set:
			mov rax, error_home_env_not_set_len
		    mov rdi, 1
		    lea rsi, [rel error_home_env_not_set]
		    call _print_with_new_line
		    jmp .return_built_in
		    
        
    .check_and_execute_pwd:
        call _builtin_pwd
        jmp .return_built_in

    .clear_screen:
	    mov rax, sys_write              ; sys
		mov rdi, 1              ; fd 1
		lea rsi, [rel cursor_clear_screen]
		mov rdx, cursor_clear_screen_len
		syscall

		jmp .return_built_in

	.print_history_and_ret:
		call _print_history
		jmp .return_built_in

    .return_built_in:
        mov rax, 0
        ret











; rdi: new location address
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

	ret

	.error_changing_dir:
		mov [rel error_code], rax
		mov rax, error_changing_dir_len
		mov rdi, 1
		lea rsi, [rel error_changing_dir]
		call _print

		mov rdi, [rel address_argc_address_array]
		add rdi, 8
		mov rdi, [rdi]
		call _strlen

		mov rdi, 1
		mov rsi, [rel address_argc_address_array]
		add rsi, 8
		mov rsi, [rsi]
		call _print

		mov rax, [rel error_code]
		call _print_error_with_new_line
		mov rax, -1
		ret

	

_builtin_pwd:
	mov rax, [rel curr_cwd_len]
	mov rdi, 1
	lea rsi, [rel curr_cwd]
	call _print_with_new_line
	ret
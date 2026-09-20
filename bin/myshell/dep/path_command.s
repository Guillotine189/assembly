%include "./dep/constants.inc"

section .data
	path_address dq 0
	last_path_flag dq 0



section .rodata	
	error_path_env_not_found db "Error: 'PATH; env variable not present.", 0
	error_path_env_not_found_len equ $ - error_path_env_not_found

	dot db ".",0
	back_slash db "/"
	dot_back_slash db "./", 0
	dash db '-',0
	path_env_var db "PATH", 0


section .bss
	reusable_buffer_path resb 4096
	struct_for_stat resb 144

extern _print
extern _print_with_new_line
extern _string_copy_including_null
extern _print_error_with_new_line
extern _strcmp
extern _cmp_equal_memory
extern _strlen
extern _mem_copy
extern _memcpy_with_end_char


extern og_envp_stack_array_address
extern error_code
extern curr_cwd
extern curr_cwd_len
extern old_cwd
extern old_cwd_len

extern address_argc_address_array
extern address_envp_address_array
extern address_command
extern total_command_aruments


global _check_if_cmd_is_in_path
global _find_var_in_env_var

section .text


; rdi: address of the variable to check if it's in env or not
; rsi: len of the varible
; returns rax : address of env path variable if it exists
; 		      : -ve number on failure
; CHECKS the og_envp_stack_array_address weather the env variable exists or not

_find_var_in_env_var:
	test rsi, rsi
	je .path_not_found

	xor r8 ,r8 							; this will store which env var i am checking

	.check_next_env_var:
		mov rax, [rel og_envp_stack_array_address]
		mov rdx, r8
		shl rdx, 3
		add rax, rdx
		; rax = [og_envp_stack_array_address + r8*8]
		
		mov rcx, [rax]			; rcx now stores the address of env variable

		cmp rcx, 0 		  	; if the value is NULL, i have reached the end of envp variba
		je .path_not_found

		xor r9, r9 				; idx for going over the env var
	.check_this_address:

		cmp r9, rsi    			; r9 is index, rsi is length.
		je .check_if_env_name_ends_here

		mov al, byte [rcx + r9] 		; "PATH=usr/:"
		cmp byte [rdi + r9], al    ; compare byte of asking variable with current envp var
		jne .check_next_var

		inc r9
		jmp .check_this_address


	.check_next_var:
		inc r8
		jmp .check_next_env_var

	.check_if_env_name_ends_here:
		cmp byte [rcx + r9], '=' 		; if the next byte in my og_env_var is '=' 
		je .path_found

		jmp .check_next_var


	.path_found:
		mov rax, rcx
		ret

	.path_not_found:
		mov rax, -1
		ret





; returns address in rax, if exists or -1 if not
_check_if_cmd_is_in_path:

	lea rdi, [rel path_env_var]
	mov rsi, 4
	call _find_var_in_env_var

	test rax, rax
	jl .error_path_env_not_found

	mov [rel path_address], rax
	call _parse_path_and_check_if_command_in_path

	test rax, rax
	jl .not_inside_path

	; rax already has address
	jmp .inside_path

	.error_path_env_not_found:
		mov rax, error_path_env_not_found_len
		mov rdi, 1
		lea rsi, [rel error_path_env_not_found]
		call _print_with_new_line

		jmp .not_inside_path


	.not_inside_path:
		mov rax, -1
		ret

	.inside_path:
		ret


; returns: rax : -1 -> if not exists, address of constructed path if exists
_parse_path_and_check_if_command_in_path:

	mov rax, [rel path_address]
	add rax, 5 							; 'PATH=' skipped

	mov r12, 5 					; idx for starting of new path 
	mov r13, 5 					; idx for total looping inside path var

	mov qword [rel last_path_flag], 0

	.loop_init:
		mov rax, [rel path_address]

	.loop_find_semi_colon_or_end:

		cmp byte [rax + r13], ':'
		je .end_of_path_found

		cmp byte [rax + r13], 0
		je .last_path

		inc r13
		jmp .loop_find_semi_colon_or_end

	.last_path:
		mov qword [rel last_path_flag], 1

	; r12 is start of path
	; r13 is at end of path + 1
	.end_of_path_found: 
		dec r13 					; r13 at end of path

		; two cases when to use curr dir as base path
		; 1) case when empty env variable,  "::", nothing in between semi-colons
		; 2) case when variable is ":.:", a dot in between 2 semi-colons

		;case 1
		cmp r13, r12
		je .add_current_dir 				; len = 0, add curr dir

		; case2
		mov rax, 13
		sub rax, r12
		inc rax

		cmp rax, 1
		jne .add_env_path 					; len not 1, add regular path

		cmp byte [rax], '.'
		je .add_current_dir 	; if len = 1, and path is '.' -> add curr working

		
		jmp .add_env_path

		.add_current_dir:
		mov rax, r13
		sub rax, r12  			
		inc rax  					; bec r12 r13 are 0 indexed, inc 1 for lenght
		lea rdi, [rel reusable_buffer_path]
		lea rsi, [rel curr_cwd]
		add rsi, r12
		mov rdx, '/'
		mov r8, 1
		call _memcpy_with_end_char 				; rax has address of next byte
		push rax
		jmp .add_command

		.add_env_path:
		mov rax, r13
		sub rax, r12  			
		inc rax  					; bec r12 r13 are 0 indexed, inc 1 for lenght
		lea rdi, [rel reusable_buffer_path]
		mov rsi, [rel path_address]
		add rsi, r12
		mov rdx, '/'
		mov r8, 1
		call _memcpy_with_end_char 				; rax has address of next byte
		push rax

		.add_command:
		mov rdi, [rel address_command]
		call _strlen
		pop rdi
		mov rsi, [rel address_command]
		mov rdx, 0
		mov r8, 1
		call _memcpy_with_end_char 
		; now i have constructed '/path/commandNULL'

		; find if this file exists

		mov rax, sys_stat
		lea rdi, [rel reusable_buffer_path]
		lea rsi, [rel struct_for_stat]
		syscall

		test rax, rax 						; if file doesn't exists, check next path
		jl .check_next_path
		jmp .in_path



	.check_next_path:
		cmp qword [rel last_path_flag], 1
		je .not_in_path

		add r13, 2
		mov r12, r13
		jmp .loop_init


	.not_in_path:
		mov rax, -1
		ret

	.in_path:
		lea rax, [rel reusable_buffer_path]
		ret

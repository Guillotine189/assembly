section .data
	error_changing_dir db "Error changing directory", 0
	error_changing_dir_len equ $ - error_changing_dir

section .text

; funcs
extern _print
extern _print_with_new_line
extern _string_copy_including_null
extern _print_error_with_new_line
extern _string_copy_including_null

; var
extern error_code
extern curr_cwd
extern curr_cwd_len

global _builtin_cd
global _builtin_pwd

sys_chdir           equ 80


; rdi: new location address
_builtin_cd:
	mov rax, sys_chdir
	syscall

	test rax, rax
	jl .error_changing_dir

	;change the current cwd variable
	mov rsi, rdi 						; src is the address of new path name provided
	lea rdi, [rel curr_cwd] 			; destination is old cwd address		
	call _string_copy_including_null 	; rax has len

	; change the len of cur_cwd	
	mov [rel curr_cwd_len], rax

	ret

	.error_changing_dir:
		mov [rel error_code], rax
		mov rax, error_changing_dir_len
		mov rdi, 1
		lea rsi, [rel error_changing_dir]

		mov rax, [rel error_code]
		call _print_error_with_new_line
		mov rax, -1
		ret

	



; rdi : address of cwd
; rsi : len of cwd
_builtin_pwd:
	mov rax, [rel curr_cwd_len]
	mov rdi, 1
	lea rdi, [rel curr_cwd]
	call _print_with_new_line
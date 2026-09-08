section .data
	usage_line0 db "Usage: ", 0
	usage_line0_len equ $ - usage_line0
	usage_line1 db " <pattern> <filename>", 0
	usage_line1_len equ $ - usage_line1

	error_opening_file_line db "Error opening file: ", 0
	error_opening_file_line_len equ $ - error_opening_file_line

	error_reading_file_line db "Error reading file: ", 0
	error_reading_file_line_len equ $ - error_reading_file_line


	error_search_path_arg_is_not_a_file_and_exit0 db "Error: '", 0
	error_search_path_arg_is_not_a_file_and_exit0_len equ $ - error_search_path_arg_is_not_a_file_and_exit0
	error_search_path_arg_is_not_a_file_and_exit1 db "' is not a regular file.", 0
	error_search_path_arg_is_not_a_file_and_exit1_len equ $ - error_search_path_arg_is_not_a_file_and_exit1


section .bss

	search_file_address resb 8
	search_file_fd resb 8

	resusable_stat_buffer resb 144

	error_opening_file_name_address resb 8
	error_opening_file_name_len resb 8

	error_reading_file_address resb 8
	error_reading_file_len resb 8

	error_search_file_is_not_a_reg_file_address resb 8
	error_search_file_is_not_a_reg_file_len resb 8

	exit_status_code resb 8


	; macros 
	S_IFMT  equ 0o170000			; masks for st_mode
	S_IFREG equ 0o100000			; value file when : mask AND eax 
	S_IFDIR equ 0o040000			; value dir  when : mask AND eax 

	DT_REG equ 8    ; regular file
	DT_DIR equ 4    ; directory
	DT_LNK equ 10


section .text

extern _print
extern _print_with_new_line
extern _strlen

global _start



_start:
	mov rbp, rsp 									; i want rbp to start here
	

	; first how many args passsed, rn i only support 3, "./mygrep" "pattern" "file"
	cmp QWORD [rsp], 3 									; compare args passed to 3
	jne _usage 										; if 3 args not passed show usage





	; get address of search file which is last argument
	mov rax, [rbp]              					; rax = argc
	mov rdx, [rbp + rax*8]      					; rdx = argv[last_one]
	mov [rel search_file_address], rdx


	mov rax, 4 										; stat syscall numebr
	mov rdi, [rel search_file_address]					; address of search file
	lea rsi, [rel resusable_stat_buffer]
	syscall 

	cmp rax, 0
	jl .set_error_getting_og_file_info_and_exit 	; if 3rd arg not does not exists
	jmp .og_file_exists_check_og_file_is_a_reg_file

	.set_error_getting_og_file_info_and_exit:
		mov rdi, [rel search_file_address]
		mov [rel error_opening_file_name_address], rdi

		; find length of 3rd arg 
		call _strlen 					

		mov [rel error_opening_file_name_len], rax
		jmp .error_opening_file_and_exit

	.og_file_exists_check_og_file_is_a_reg_file:
	mov eax, [rel resusable_stat_buffer + 24]	; st_mode address, read 4bytes
	and eax, S_IFMT

	; if arg is a file
	cmp eax, S_IFREG
	je .open_search_file

	;else give error and exit
	.set_error_search_path_arg_is_not_a_file_and_exit:
		mov rdi, [rel search_file_address]					; address for search file
		mov [rel error_search_file_is_not_a_reg_file_address], rdi

		; find length of 3rd arg 
		call _strlen 					

		mov [rel error_search_file_is_not_a_reg_file_len], rax
		jmp .error_search_path_arg_is_not_a_file_and_exit


	.open_search_file:

	mov rax, 2
	mov rdi, [rel search_file_address]					; address of search file
	mov rsi, 0 										; 0 -> readonly
	syscall

	cmp rax, 0
	jl .set_error_reading_og_file_and_exit
	jmp .start_finding_pattern

	.set_error_reading_og_file_and_exit:

		mov rdi, [rel search_file_address]			 ; address of search file
		mov [rel error_reading_file_address], rdi

		call _strlen

		mov [rel error_reading_file_len], rax
		jmp .error_reading_file_and_exit


	.start_finding_pattern:
	mov [rel search_file_fd], rax












	call _close_search_file
	call _exit 				; TODO: placeholder remove later




.error_opening_file_and_exit:
	mov rax, error_opening_file_line_len
	mov rdi, 1 									;fd
	lea rsi, [rel error_opening_file_line]	
	call _print

	mov rax, [rel error_opening_file_name_len]
	mov rdi, 1
	mov rsi, [rel error_opening_file_name_address]
	call _print_with_new_line

	mov [rel exit_status_code], 1
	jmp _exit_with_status_code


.error_reading_file_and_exit:
	mov rax, error_reading_file_line_len
	mov rdi, 1 									;fd
	lea rsi, [rel error_reading_file_line]	
	call _print

	mov rax, [rel error_reading_file_len]
	mov rdi, 1
	mov rsi, [rel error_reading_file_address]
	call _print_with_new_line

	mov [rel exit_status_code], 1
	jmp _exit_with_status_code
	



.error_search_path_arg_is_not_a_file_and_exit:
	mov rax, error_search_path_arg_is_not_a_file_and_exit0_len
	mov rdi, 1 									;fd
	lea rsi, [rel error_search_path_arg_is_not_a_file_and_exit0]	
	call _print

	mov rax, [rel error_search_file_is_not_a_reg_file_len]
	mov rdi, 1
	mov rsi, [rel error_search_file_is_not_a_reg_file_address]
	call _print

	mov rax, error_search_path_arg_is_not_a_file_and_exit1_len
	mov rdi, 1
	lea rsi, [rel error_search_path_arg_is_not_a_file_and_exit1]
	call _print_with_new_line

	mov [rel exit_status_code], 1
	jmp _exit_with_status_code


_close_search_file:
	mov rax, 3
	mov rdi, [rel search_file_fd]
	sycall
	ret


_usage:

	mov rax, usage_line0_len
	mov rdi, 1
	lea rsi, [rel usage_line0]
	call _print

	; find length of arg0 
	mov rdi, [rbp + 8] 							; address of arg[0]
	call _strlen 								; rx has len excluding \0

	mov rdi, 1
	mov rsi, [rbp + 8]
	call _print

	mov rax, usage_line1_len
	mov rdi, 1
	lea rsi, [rel usage_line1]
	call _print_with_new_line
	jmp _exit

_exit_with_status_code:
	mov rax, 60
	mov rdi, [rel exit_status_code]
	syscall

_exit:
	mov rax, 60
	mov rdi, 0
	syscall
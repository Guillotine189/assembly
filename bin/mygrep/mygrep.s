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

	search_file_address resq 1
	search_file_fd resq 1

	resusable_stat_buffer resb 144
	resusable_read_data_buffer resb 4096

	error_opening_file_name_address resq 1
	error_opening_file_name_len resq 1

	error_reading_file_address resq 1
	error_reading_file_len resq 1

	error_search_file_is_not_a_reg_file_address resq 1
	error_search_file_is_not_a_reg_file_len resq 1

	exit_code_status resq 1


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
	jl .set_error_opening_og_file_and_exit
	jmp .start_finding_pattern

	.set_error_opening_og_file_and_exit:

		mov rdi, [rel search_file_address]			 ; address of search file
		mov [rel error_opening_file_name_address], rdi

		call _strlen

		mov [rel error_opening_file_name_len], rax
		jmp .error_opening_file_and_exit


	.start_finding_pattern:
	mov [rel search_file_fd], rax



	; rn -> 1 pattern and every line less than 4096 bytes
	; TODO: add multiple pattern support
	; TODO: add supoort for line > 4096 bytes



	call .find_patterns_on_file





	call _close_search_file
	call _exit


; stack after init
; 		| 			address of file name 				| -56 bytes
; 		| 	local_offset_ending_new_line_in_buffer		| -48 bytes 
; 		| 	local_offset_starting_new_line_in_buffer	| -40 bytes 
; 		| 			local size of buffer 		 		| -32 bytes
; 		| 	total_offset_of_starting_byte_in_buffer		| -24 bytes 
; 		| 			number of patterns to match 		| -16 bytes
; 		| 					  fd 						| -8 bytes
; 		| 					old rbp 					| +0 bytes -> current tbp

; stack recv
;  rsp  | 					return address 				| +8 bytes
;  	    | 					pattern1_len 				| +16 bytes
;  	    | 				pattern1_ending_with_\0 		| +24 bytes
;  	    | 					pattern2_len 				| +x bytes
;  	    | 				pattern2_ending_with_\0 		| +x+8 bytes
;  	    | 					pattern3_len 				| +y bytes
;  	    | 				pattern3_ending_with_\0 		| +y+8 bytes
; --------------------------and so on

; rax: fd of file
; rdi: number of patterns to match
; rsi : address of file name
; stack : all the patterns
; expects file line to be < 4096bytes
; expects file name to be 
.find_patterns_on_file:
	ret

	.init:
		push rbp
		mov rbp, rsp

		push rax
		push rdi

		mov rax, 0
		push rax
		push rax
		push rax
		mov rax, -1 		; local offset ending of a line is -1 bec it adds 1 at start
		push rax

		push rsi

	.loop_reading_file:
	; copy data into buffer

	mov rax, 8
	mov rdi, [rbp - 8]	
	mov rsi, [rbp - 24] 					; total starting offset from beginning
	add rsi, [rbp - 40] 					; add the offset of new start position
	mov rdx, 0 								; all this offset from beginning
	syscall 								; move pointer to this new location

	mov rax, 0 													; read syscall
	mov rdi, [rbp - 8] 											;fd
	lea rsi, [rel resusable_read_data_buffer]
	mov rdx, 4096 												; buffer size
	syscall 

	cmp rax, 0
	jl .print_error_reading_from_file_and_return
	je .process_last_line 								; TODO

	mov [rbp - 32], rax 						; store how much local data is there

	.get_new_line:

	; move the start pointer to end pointer + 2 (old_line\nNew_line\nNew_line)
	; 											 |o 	|e
	; 1st pointer will then point to 1st char of new line

	mov rax, [rbp - 48]							; position of 2nd pointer
	inc rax
	mov [rbp - 40], rax 						; position of 1st pointer = 2nd + 2

	; check if local buffer is over or not
	; eg "older_line\nLine_just_processed\n"
	mov rax, [rbp - 40]
	cmp rax, [rbp - 32] 						; if starting offset >= size
	jge .loop_reading_file

	; check if next line is not fully in the buffer
	; check if from starting offset till end of buffer size you encounter

	xor rax, rax
	mov rax, [rbp - 48] 				; local ending offset
	.loop:
		cmp rax, [rbp - 32] 			; if ending offset >= size
		jge .loop_reading_file

		cmp [rel resusable_read_data_buffer + rax], '\n'
		je .loop_for_multiple_patterns

		inc rax
		mov [rbp - 48], rax
		jmp .loop



	.loop_for_multiple_patterns:

	; start offset has position of beginninig of new byte
	; now my end pointer offset is pointing to \n
	xor r12, r12 						; stores how many patterns have been checked

	.loop_for_single_pattern:


	; 	->check for pattern within the offsets provided



	; 	-> if found the pattern, record the starting offset and end offset for the pattern
	; print line if pattern exist, print in red colour the pattern
	; loop for other pattern


	.print_error_reading_from_file_and_return:
		mov rdi, [rbp - 56]						 ; address of file
		mov [rel error_reading_file_address], rdi

		call _strlen

		mov [rel error_reading_file_len], rax
		call .error_reading_file
		jmp .return

	.return:
		mov rsp, rbp
		pop rbp
		ret





.error_opening_file_and_exit:
	mov rax, error_opening_file_line_len
	mov rdi, 1 									;fd
	lea rsi, [rel error_opening_file_line]	
	call _print

	mov rax, [rel error_opening_file_name_len]
	mov rdi, 1
	mov rsi, [rel error_opening_file_name_address]
	call _print_with_new_line

	mov [rel exit_code_status], 1
	jmp _exit_with_status_code

.error_reading_file:
	mov rax, error_reading_file_line_len
	mov rdi, 1 									;fd
	lea rsi, [rel error_reading_file_line]	
	call _print

	mov rax, [rel error_reading_file_len]
	mov rdi, 1
	mov rsi, [rel error_reading_file_address]
	call _print_with_new_line
	ret

.error_reading_file_and_exit:
	mov rax, error_reading_file_line_len
	mov rdi, 1 									;fd
	lea rsi, [rel error_reading_file_line]	
	call _print

	mov rax, [rel error_reading_file_len]
	mov rdi, 1
	mov rsi, [rel error_reading_file_address]
	call _print_with_new_line

	mov [rel exit_code_status], 1
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

	mov [rel exit_code_status], 1
	jmp _exit_with_status_code


_close_search_file:
	mov rax, 3
	mov rdi, [rel search_file_fd]
	syscall
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
	mov rdi, [rel exit_code_status]
	syscall

_exit:
	mov rax, 60
	mov rdi, 0
	syscall
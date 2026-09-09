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
extern _print_error_with_new_line

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
		mov [rel exit_code_status], rax
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
		mov [rel exit_code_status], rax
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



	; prepare stack

	;  	    | 					pattern1_len 				| +16 bytes
	;  	    | 				pattern1_ending_with_\0 		| +24 bytes
	;  	    | 					pattern2_len 				| +x bytes
	;  	    | 				pattern2_ending_with_\0 		| +x+8 bytes
	;  	    | 					pattern3_len 				| +y bytes
	;  	    | 				pattern3_ending_with_\0 		| +y+8 bytes
	; --------------------------and so on




	; prepare registers

	; rax: fd of file
	; rdi: number of patterns to match
	; rsi : address of file name



	.before_call:

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
	je .process_last_line

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

		lea rcx, [rel resusable_read_data_buffer]
		add rcx, rax
		cmp byte [rcx], 0x0a 						; cmpare with \n
		je .loop_for_multiple_patterns

		inc rax
		mov [rbp - 48], rax
		jmp .loop



	.loop_for_multiple_patterns:

	; start offset has position of beginninig of new byte
	; now my end pointer offset is pointing to \n
	xor r12, r12 						; which pattern am i checking
	mov rax, 0 			 				; 
	push rax 				;rbp - 64 stores the len of all patterns processed
						; update rbp - 64, once the pattern has been processed

	.init_for_next_pattern:
	inc r12

	cmp r12, [rbp - 16] 				; once all pattern matched
	jg .init_new_line 					; get new line when all patterns are checked
	jmp .cont_patterns

	.init_new_line:
		pop rax
		jmp .get_new_line
	

	.cont_patterns:
	; add the len of next pattern to total len of pattern processed
	; currently i am processing 1st pattern (1 indexing)


	mov r13, [rbp - 40] 		; inner_loop_start_offset=local_offset_starting_new_line
	mov r14, [rbp - 40] 		; inner_loop_end_offset=local_offset_starting_new_line
	xor r15, r15 						; inner_loop_bytes_same_as_pettern
	
	.loop_for_single_pattern:


	cmp r14, [rbp - 48] 		; if local end pointer is > line end 
	jg .check_next_pattern 	; check for next pattern

	; [rbp + 8 + r12*8 + [rbp - 64]] 			; address of current pattern
	; [rbp + 8 + (r12-1)*8 + [rbp - 64]] 		; len of current pattern

	; cmp byte of loop_end_offset with pattern's nth byte
	lea rax, [rel resusable_read_data_buffer]
	add rax, r14 							; at the address of the byte am comparing

	mov rcx, [rbp - 64] 					; total len of all prev pattern processed
	mov rcx, r12
	shl rcx, 3  		; the bytes of total pattern including current ones address, r12*8
	lea rcx , [rbp + 8 + rcx] 		; the address of current pattern
	add rcx, r15 					; address which byte of pattern am i comparing

	mov al, byte [rax]
	cmp byte al, [rcx]
	je .equal_byte
	jne .not_equal_byte

	.equal_byte:
		inc r15 						; now check the next byte of pattern
		inc r14 						; inc end offset

		.check_if_pattern_is_matched:
			; comapre len of pattern with (offset_end - offset_start + 1)
			mov rax, [rbp - 64] 		
			mov rcx, r12
			shl rcx, 3
			add rax, rcx
			sub rax, 8 			
			mov rax, [rbp + 8 + rax] 	; now rax has len of current pattern
			mov rcx, r14
			sub rcx, r15
			inc rcx
			cmp rax, rcx
			je .pattern_matched

		jmp .loop_for_single_pattern

	.not_equal_byte:
		xor r15, r15 					
		inc r14
		mov r13, r14 					; move start offet to end offset
		jmp .check_next_pattern


	.pattern_matched:
		; todo: print the current line
		mov rax, [rbp - 48] 			; local line ending offset
		sub rax, [rbp - 40]				; sub local line ending 
		inc rax 						; rax has len
		mov rdi, 1
		lea rsi, [rel resusable_read_data_buffer]
		add rsi, [rbp - 24] 			; address of buffer where the line starts
		call _print_with_new_line

		xor r15, r15 					
		inc r14
		mov r13, r14 					; move start offet to end offset
		jmp .check_next_pattern


	.check_next_pattern:
		; add the len of currnet pattern to len of total pattern processed
		; [rbp + 8 + (r12-1)*8 + [rbp - 64]] 			; len of current pattern
		mov rax, [rbp - 64] 					; total len of all prev pattern processed
		mov rcx, r12
		shl rcx, 3
		add rax, rcx 	; the bytes of total pattern including current ones address
		sub rax, 8 			
		; now i am at the offset from rbp after ret addr, where cur len is located

		mov rax, [rbp + 8 + rax] 	; now rax has len of current pattern
		add [rbp - 64], rax 		; update the total len of pattern processed
		jmp .init_for_next_pattern



	; TODO: 
	; "line1\nline2\nLine3"  This is final buffer, 
	;				 |L	 -> my starting pointer is at "L", now find pattern in last line
	.process_last_line:
		jmp .return


	.print_error_reading_from_file_and_return:
		mov [rel exit_code_status], rax
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
	call _print

	mov rax, [rel exit_code_status]
	call _print_error_with_new_line

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
	call _print

	mov rax, [rel exit_code_status]
	call _print_error_with_new_line
	ret

.error_reading_file_and_exit:
	mov rax, error_reading_file_line_len
	mov rdi, 1 									;fd
	lea rsi, [rel error_reading_file_line]	
	call _print

	mov rax, [rel error_reading_file_len]
	mov rdi, 1
	mov rsi, [rel error_reading_file_address]
	call _print

	mov rax, [rel exit_code_status]
	call _print_error_with_new_line

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
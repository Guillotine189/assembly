section .data
	usage_line0 db "Usage: ", 0
	usage_line0_len equ $ - usage_line0
	usage_line1 db " <patterns>... <filename>", 0
	usage_line1_len equ $ - usage_line1

	error_opening_file_line db "Error opening file: ", 0
	error_opening_file_line_len equ $ - error_opening_file_line

	error_reading_file_line db "Error reading file: ", 0
	error_reading_file_line_len equ $ - error_reading_file_line


	error_search_path_arg_is_not_a_file_and_exit0 db "Error: '", 0
	error_search_path_arg_is_not_a_file_and_exit0_len equ $ - error_search_path_arg_is_not_a_file_and_exit0
	error_search_path_arg_is_not_a_file_and_exit1 db "' is not a regular file.", 0
	error_search_path_arg_is_not_a_file_and_exit1_len equ $ - error_search_path_arg_is_not_a_file_and_exit1

	error_allocating_heap_memory db "Error allocating memory in heap.",0
	error_allocating_heap_memory_len equ $ - error_allocating_heap_memory

	eof_reached dq 0

section .bss

	search_file_address resq 1
	search_file_fd resq 1

	buffer_size equ 16384
	resusable_stat_buffer resb 144
	resusable_read_data_buffer resb buffer_size


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
extern _malloc
extern _free

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
	jmp .prepare_stack_reg_for_call

	.set_error_opening_og_file_and_exit:
		mov [rel exit_code_status], rax
		mov rdi, [rel search_file_address]			 ; address of search file
		mov [rel error_opening_file_name_address], rdi

		call _strlen

		mov [rel error_opening_file_name_len], rax
		jmp .error_opening_file_and_exit


	.prepare_stack_reg_for_call:
	mov [rel search_file_fd], rax 					; fd of file is already set

	; TODO: add multiple pattern support
	; TODO: add supoort for line > buffer_size bytes

	   ;prepare stack
	   ;| 	  address of array_of_pattern_addresses  	| -16bytes 
	   ;| 		address of array_of_pattern_len			| -8bytes


	; first the array of len of all patterns
	; find how many bytes to allocate		
	mov rax, [rbp] 										; argc value
	sub rax, 2 											; 1 arg is program,another is file
	shl rax, 3 				; rax = rax*8 = bytes for addresses of all the patterns

	mov rdi, rax
	call _malloc

	test rax, rax
	jl .set_error_allocating_heap_memory_and_exit

	push rax 						; push to stack the array of addresses address

	.prepare_other_memory_region:	

	xor r8, r8 							; counts how many patterns len i have added
	mov rbx, [rbp] 						; total argc
	sub rbx, 2 							; total patterns in rax

	mov rdx, [rbp - 8] 				; address of array of len of pattern

	.fill_len_memory_loop:

		cmp r8, rbx
		je .push_address_of_pattern_addresses

		mov rdi, [rbp + 16 + r8*8] 			; address of pattern
		call _strlen

		mov [rdx + r8*8], rax
		inc r8
		jmp .fill_len_memory_loop

	.push_address_of_pattern_addresses:
	; address where the addresses of all patterns live is address of argv[1]
	lea rax, [rbp+16]
	push rax

	.prepare_registers:

	; rax: fd of file
	; rdi: number of patterns to match
	; rsi : address of file name

	mov rax, [rel search_file_fd]
	mov rdi, [rbp] 							; argc
	sub rdi, 2  							; -2 for mygrep and filename
	mov rsi, [rel search_file_address] 

	.before_call:

	call .find_patterns_on_file

	mov rdi, [rbp - 8]
	call _free

	call _close_search_file
	call _exit


	.set_error_allocating_heap_memory_and_exit:
		mov [rel exit_code_status], rax
		jmp .error_allocating_heap_memory_and_exit



; stack after init
; 		| 			address of file name 				| -56 bytes
; 		| 			local_ending_new_line_in_buffer		| -48 bytes 
; 		| 			local_starting_new_line_in_buffer	| -40 bytes 
; 		| 			local size of buffer 		 		| -32 bytes
; 		| 	total_offset_of_starting_byte_in_buffer		| -24 bytes 
; 		| 			number of patterns to match 		| -16 bytes
; 		| 					  fd 						| -8 bytes
; 		| 					old rbp 					| +0 bytes -> current tbp

; stack recv
;  rsp  | 					return address 				| +8 bytes
;  	    | 	  address of array_of_pattern_addresses  	| +16 bytes
;  	    | 		address of array_of_pattern_len			| +24 bytes


; rax: fd of file
; rdi: number of patterns to match
; rsi : address of file name

; expects file line to be < buffer_sizebytes

.find_patterns_on_file:
	

	.init:
		push rbp
		mov rbp, rsp

		push rax
		push rdi

		mov rax, 0
		push rax
		push rax
		push rax
		mov rax, -1 		; local ending of a line is -1 bec it adds 1 at start
		push rax

		push rsi

	.loop_reading_file:
	; copy data into buffer

	mov rax, [rbp - 24]
	add rax, [rbp - 40]
	mov [rbp - 24], rax

	mov rax, 8 								; lseek
	mov rdi, [rbp - 8]	
	mov rsi, [rbp - 24] 					; total bytes read before this buffer
	mov rdx, 0 								; all this offset from beginning
	syscall 								; move pointer to this new location

	mov qword [rbp - 40], 0 				; index of local line start 
	mov qword [rbp - 48], 0 				; index of local line end

	mov rax, 0 													; read syscall
	mov rdi, [rbp - 8] 											;fd
	lea rsi, [rel resusable_read_data_buffer]
	mov rdx, buffer_size 												; buffer size
	syscall 

	cmp rax, 0
	jl .print_error_reading_from_file_and_return
	je .process_last_line
	jmp .cont_normal

	.process_last_line:
		mov rax, [rel eof_reached]
		test rax, rax
		je .first_time_seeing_eof

		jmp .return

		.first_time_seeing_eof:
			mov [rel eof_reached], 1
			jmp .loop_for_multiple_patterns


	.cont_normal:
	mov [rbp - 32], rax 						; store how much local data is there

	.get_new_line:

	; move the start pointer to end pointer + 1 (old_line\nNew_line\nNew_line)
	; 											 |o 	 |\n
	; 1st pointer will then point to 1st char of new line

	mov rax, [rbp - 48]							; offset of 2nd pointer
	inc rax
	mov [rbp - 40], rax 						; position of start line = 2nd + 1 = "N"
	mov [rbp - 48], rax 						; position of end line = "N"

	; check if local buffer is over or not
	; eg "older_line\nLine_just_processed\n"
	
	cmp rax, [rbp - 32] 						; if starting offset >= size
	jge .loop_reading_file

	; check if next line is not fully in the buffer
	; check if from starting offset till end of buffer size you encounter

	mov rax, [rbp - 48] 				; local ending position
	.loop:
		cmp rax, [rbp - 32] 			; if ending offset >= size
		jge .check_if_eof_or_more_data_needed

		lea rcx, [rel resusable_read_data_buffer]
		add rcx, rax
		cmp byte [rcx], 0x0a 						; cmpare with \n
		je .save_and_loop_for_multiple_patterns

		inc rax
		mov [rbp - 48], rax
		jmp .loop

	.check_if_eof_or_more_data_needed:
		cmp qword [rbp - 32], buffer_size

		jl .set_and_process_last_line
		jmp .loop_reading_file
		.set_and_process_last_line:
			mov [rbp - 48], rax 			; only local loop end offset needs
			jmp .process_last_line


	.save_and_loop_for_multiple_patterns:
		mov [rbp - 48], rax 			; only local loop end offset needs to be updated
		jmp .loop_for_multiple_patterns

	.loop_for_multiple_patterns:

	; start offset has position of beginninig of new byte
	; now my end pointer offset is pointing to \n
	xor r12, r12 						; which pattern am i checking

	.init_for_next_pattern:

	cmp qword r12, [rbp - 16] 				; once all pattern matched
	jge .get_new_line 					; get new line when all patterns are checked
	jmp .cont_patterns

	

	.cont_patterns:
	
	mov r14, [rbp - 40] 		; index_line_loop = local_starting_new_line
	xor r15, r15 						; inner_loop_bytes_same_as_pettern
	
	.loop_for_single_pattern:


	cmp r14, [rbp - 48] 		; if index_line_loop  is >= line end offset(\n)
	jge .check_next_pattern 	; check for next pattern

	;mov rax, [rbp + 16] ->  mov rax, [rax + r12*8]  	; address_of_curr_pattern
	;mov rax, [rbp + 24] -> mov rax, [rax + r12*8] 		; len of current pattern

	; cmp byte of loop_end_offset with pattern's nth byte
	lea rax, [rel resusable_read_data_buffer]
	add rax, r14 							; at the address of the byte am comparing

	mov rcx, [rbp + 16] 				; address of array
	mov rdi, r12
	shl rdi, 3
	add rcx, rdi 				; address of which pattern am i matching
	mov rcx, [rcx] 				; rcx has the pattern now
	add rcx, r15 					; address of which byte of the battern am i matching

	mov al, byte [rax]
	cmp byte al, [rcx]
	je .equal_byte
	jne .not_equal_byte

	.equal_byte:
		inc r15 						; now check the next byte of pattern
		inc r14 						; inc the loop ptr

		.check_if_pattern_is_matched:
			; comapre len of pattern with (offset_end - offset_start + 1)
			mov rax, [rbp + 24]
			mov rax, [rax + r12*8] 		; now rax has len of current pattern

			cmp rax, r15
			je .pattern_matched

		jmp .loop_for_single_pattern

	.not_equal_byte:
		; if "raxraxo" , check "raxo"
		; raxr will should go back and detect r again

		test r15, r15 	; if i was inside a partia match, and last byte not a match
		jnz .check_this_byte_again

		inc r14 						; line_loop_off inc

		.check_this_byte_again:
		sub r14, r15
		inc r14
		xor r15, r15 					; total len of matched bytes
		jmp .loop_for_single_pattern


	.pattern_matched:
		; rax has lenght already

		mov rcx, [rbp - 40] 					; line offset start 
		mov rdi, [rbp - 48] 					; line offset end
		sub rdi, rcx

		mov rax, rdi 							; rax has len of line now
		mov rdi, 1
		lea rsi, [rel resusable_read_data_buffer]
		add rsi, [rbp - 40] 					; the line start index of buffer
		call _print_with_new_line

		; string -> "patterpatterp", pattern "patterp"
		; after first "oro", dont move forward, start checking check last byte 

		xor r15, r15
		; inc r14  -> not done here, because last byte may start pattern again
		jmp .loop_for_single_pattern


	.check_next_pattern:
		inc r12 						; patterns checked
		jmp .init_for_next_pattern

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


.error_allocating_heap_memory_and_exit:
	mov rax, error_allocating_heap_memory_len
	mov rdi, 1 									;fd
	lea rsi, [rel error_allocating_heap_memory]	
	call _print
	
	mov rax, [rel exit_code_status]
	call _print_error_with_new_line

	call _close_search_file

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
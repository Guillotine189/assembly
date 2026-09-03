; expects a file, counts characters, words, lines

section .data
	arg_error db "Usage: ./mycat <filePath>",0 			; 10: ascii for \n
	file_open_error db "Error opening file",0
	reading_error db "Error reading file",0

	char_count_line DB "Characters: ", 0 					; 12bytes
	word_count_line DB "Words: ", 0 						; 7bytes
	line_count_line DB "Lines: ", 0 						; 7bytes


section .bss
	buffer resb 16384
	count_buffer resb 20		;18,446,744,073,709,551,615 max val in 64bit(20bytes)

extern _print
extern _itoa

section .text


global _start

; r12 = file descriptor
; r13 = total bytes
; r14 = total words
; r15 = total lines
; r8b = inside_word
; r9  = buffer index
; r10 = bytes read this iteration
; r11b = current byte


_start:


	;check for args passed
	mov rax, [rsp]
	cmp rax, 2
	jne .error_args_provided


	; read file

	; step 1: open file and check if it was opened or not

	;TODO: rn it's 1 file so this is fine
	mov rax, 2
	mov rdi, [rsp+16]					;cpoy the address where the arg lives 
	mov rsi, 0 							; 0 > read only
	syscall								; returns -1 on error, or fdno in rax

	mov r12, rax						; r12 now always contains fd of file

	xor r8, r8						; this will tell weather i am inside a word
	; if r8 is 1 -> i am inside word

	xor r13, r13						; total char
	xor r14, r14						; total words
	xor r15, r15						; total lines


	cmp rax, 0
	jl .error_opening_file

	; step 3: read data

	.loop:

		; try to read 8192 bytes
		mov rax, 0
		mov rdi, r12
		mov rsi, buffer
		mov rdx, 16384
		syscall 					; rax has amount of bytes read 

		test rax, rax
		je .done
		jl .error_reading_file

		add r13, rax				; total char add
		xor r10, r10				; index for bytes parsed
		xor r9, r9 					; register used to store individual byte for comp

	.parse_bytes:

		cmp r10, rax
		je .loop

		mov r9b, [buffer + r10]		; read 1 bye from buffer

		cmp r9b, 32
		je .is_a_white_space

		cmp r9b, 10 					; after \n, was i part of a word before this?
		je .is_a_white_space

		; check if thi sbyte is a tab
		cmp r9b, 9	
		je .is_a_white_space

		.is_a_char:
			mov r8, 1
			jmp .loopback

		.is_a_white_space:

			cmp r8, 1 				; check if i was part of a word before
			jne .already_outside_word
			inc r14					; now i have another word

		.already_outside_word:
			xor r8, r8
			; find weather this white space was for \n or not
			cmp r9b, 10
			jne .loopback

		.inc_new_line:
			inc r15


		.loopback:
			inc r10						; inc index how how much i have parsed
			jmp .parse_bytes

	.error_args_provided:
		mov rdi, arg_error					; use this address for data
		mov rsi, 26							; print 26 bytes
		call _print
		jmp _exit

	.error_opening_file:
		mov rdi, file_open_error
		mov rsi, 19
		call _print
		jmp _exit_error

	.error_reading_file:
		mov rdi, reading_error
		mov rsi, 19
		call _print

		mov rax, r12 				; TODO FIX HOW TO PASS FD
		call _close_fd
		jmp _exit_error


	.done:
		; at eof, if i was part of a word, then add 1 to word count
		cmp r8b, 1
		jne .print_result
		inc r14

	.print_result:

		; print the default line first
		mov rdi, char_count_line
		mov rsi, 12
		call _print

		; convert the answer to ascii
		mov rax, r13						; r13: char count
		mov rdi, count_buffer
		call _itoa							; rax: len of data, rcx address of buffer

		mov rdi, count_buffer
		mov rsi, rax
		call _print						; prints the number

		

		; print the default line first
		mov rdi, word_count_line
		mov rsi, 7
		call _print

		; convert the answer to ascii
		mov rax, r14						; r13: char count
		mov rdi, count_buffer
		call _itoa							; rax: len of data, rcx address of buffer

		mov rdi, count_buffer
		mov rsi, rax
		call _print						; prints the number



		; print the default line first
		mov rdi, line_count_line
		mov rsi, 7
		call _print

		; convert the answer to ascii
		mov rax, r15						; r13: char count
		mov rdi, count_buffer
		call _itoa							; rax: len of data, rcx address of buffer

		mov rdi, count_buffer
		mov rsi, rax
		call _print						; prints the number



	.finish:
		mov rax, r12
		call _close_fd
		jmp _exit


_close_fd:
	mov rdi, rax
	mov rax, 3
	syscall


_exit_error:
	mov rax, 60
	mov rdi, 1
	syscall



_exit:
	mov rax, 60
	mov rdi, 0
	syscall
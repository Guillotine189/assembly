; this file only reads one file, thats in 1st argument

section .data
	arg_error db "Usage: ./mycat <filePath>",10,0 			; 10: ascii for \n
	file_open_error db "Error opening file",10,0
	reading_error db "Error reading file",10,0

section .bss
	buffer resb 8192


extern _print

section .text
global _start


_start:
	
	; check if i was even supplied with a argument
	
	mov rax, [rsp]
	cmp rax, 2 							; if argc != 2, error
	jne .error_args_provided

	; step 1: open file and check if it was opened or not

	;TODO: rn it's 1 file so this is fine
	mov rax, 2
	mov rdi, [rsp+16]					;cpoy the address where the arg lives 
	mov rsi, 0 							; 0 > read only
	syscall								; returns -1 on error, or fdno in rax

	mov r12, rax							; r12 now always contains fd of file

	cmp rax, 0
	jl .error_opening_file

	; step 2: read data into buffer, and print

	.loop:

		mov rax, 0 							; read syscall
		mov rdi, r12
		mov rsi, buffer
		mov rdx, 8192
		syscall

		test rax, rax
		jl .error_reading_file	
		jz .done							; if byes to read is 0 -> EOF

		; TODO : handle errror while printing
		mov rdi, buffer
		mov rsi, rax
		call _print							; amount of printed data in rax

		jmp .loop


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
		call _close_fd
		jmp _exit_error


	.done:

		mov rax, 3 								; close fd
		mov rdi, r12
		syscall

		jmp _exit


_close_fd:
	mov rax, 3 								; close fd
	mov rdi, r12
	syscall
	ret

_exit_error:

	mov rax, 60
	mov rdi, 1
	syscall


_exit:
	mov rax, 60
	mov rdi, 0
	syscall
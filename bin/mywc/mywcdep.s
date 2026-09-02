section .text

global _print
global _itoa


; rdi: address of string 
; rsi: number of bytes to print 
; prints to fd1
; does not return anything
_print:

	mov rax, 0x0a
	push rax


	.print_argument:

		mov rax, rsi

		mov rsi, rdi 					; buffer in rsi
		mov rdi, 1						; rdi : fd nuber
		mov rdx, rax					; rsi total bytes
		mov rax, 1
		syscall

		; print new line
		mov rax, 1
		mov rdi, 1 						; fd
		mov rsi, rsp 					; buffer address
		mov rdx, 1 						; bytes to print
		syscall

	.cleanup:
		pop rax
		ret


; rax : the number
; rdi : address of buffer
; return address of buffer in rcx
; length of number in rax
_itoa:
	push rbp
	mov rbp, rsp

	xor r8, r8								; index when writing from stack
	xor r9, r9								; count of digits
	xor rsi, rsi							; holds count of digits
	mov r10, 10 							; constant divisor
	
	.loop:
		; check if i have to process anohter number
		test rax, rax
		je .move_data_to_buffer

		; find last digit 
		xor rdx, rdx						; clear rdx before division
		div r10
		add rdx, 48

		; push 1 byte to stack
		sub rsp, 1
		mov [rsp], dl

		inc r9
		inc rsi
		jmp .loop

	.move_data_to_buffer:
		cmp r9, 0
		je .done

		; read 1 byte from stack
		mov al, [rsp]
		add rsp, 1
		
		mov [rdi + r8], al
		inc r8
		sub r9, 1
		jmp .move_data_to_buffer


	.done:
		mov [rdi + r8], 0

		pop rbp
		mov rcx, rdi
		mov rax, rsi
		ret

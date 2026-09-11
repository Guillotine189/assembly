section .text


global _print
global _print_with_new_line
global _strlen
global _itoa


; rax: number of bytes to print 
; rdi: fd to write to
; rsi: address of string 
; returns bytes printed rax
_print:

	mov rdx, rax					; rdx total bytes
	mov rax, 1 						; write syscall
	syscall
	ret

; rax: number of bytes to print 
; rdi: fd to write to
; rsi: address of string 
; returns bytes printed rax
_print_with_new_line:

	mov rdx, rax					; rdx total bytes
	mov rax, 1 						; write syscall
	syscall

	; print new line
	mov rax, 10
	push rax

	mov rax, 1
	mov rdi, 1 						; fd
	mov rsi, rsp 					; buffer address
	mov rdx, 1 						; bytes to print
	syscall

	.cleanup:
	pop rax
	ret


; address of string in rdi
; return: len stored in rax
_strlen:

	.intialize:
		xor rax, rax				; rax will store string length

	.loop:

		cmp byte [rdi + rax], 0 			; move byte inside rcx
		je .finish

		inc rax
		jmp .loop

	.finish:
		ret

; rax : the number
; rdi : address of buffer
; return address of buffer in rax
_itoa:
	push rbp
	mov rbp, rsp

	xor r8, r8								; index when writing from stack
	xor r9, r9								; count of digits
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
		mov rax, rdi
		ret
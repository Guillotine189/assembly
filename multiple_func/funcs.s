section .text

global _strlen
global _print


; address of string in rdi
; return stored in rax
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
		mov rdx, rax					; rdx total bytes
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
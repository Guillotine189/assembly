section .text


global _print
global _print_with_new_line
global _strlen

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

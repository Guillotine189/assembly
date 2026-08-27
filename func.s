section .text

global _start

fun1:
	push rbp 				; store prev function rbp on stack
	mov rbp, rsp
	
	sub rsp, 4				; give 4 bytes for integer
	add eax, ebx
	mov [rbp-4], eax		; store value in stack

	mov ebx, [rbp-4]
	add eax, ebx
	sub rsp, 4
	mov [rbp-8], eax

	add rsp, 8
	pop rbp 			; restore the prev function's rbp from stack and remove from stack
	ret					; the value at top of stack(rsp) is the address of next instruction the previous 
						; function was executing, rsp takes that value and removes it from stack


_start:
	mov rax, 1
	mov rbx, 2
	call fun1			; when this is executed, the address of next instruction is stored in stack first

	mov rax, 60
	mov rdi, 99
	syscall
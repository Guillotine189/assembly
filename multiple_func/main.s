; This program prints the arguments provided inside satck when ran (1st argument is the program itself)

section .data
	args_printed dq 0

section .bss
	argc resq 1

section .text

extern _strlen
extern _print

global _start


_start:
	
	; store number of arguments
	
	mov rax, [rsp]
	mov [rel argc], rax

	.loop:

		; check if i have to print another argument
		mov rax, [rel args_printed]
		mov rbx, [rel argc]
		cmp rax, rbx
		jge .done

		mov rax, [rel args_printed]
		mov rbx, [rsp + 8 + rax*8] 				; pointer to actual argument in rcx

		mov rdi, rbx							
		call _strlen							; length in rax

		mov rdi, rbx							; address to argument
		mov rsi, rax							; length of argument
		call _print

		mov rax, [rel args_printed]				; increase the args printed
		inc rax
		mov [rel args_printed], rax

		jmp .loop


	.done:
		mov rax, 60
		mov rdi, 0
		syscall
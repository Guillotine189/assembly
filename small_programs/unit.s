section .data
	result DD 0
	time DD 0
	total DD 10
	addValue DD 10

section .bss
    arr RESB 8

section .text

global _start


exit:
	mov rax, 60
	mov rdi, 0
	syscall	

loop:
	
	cmp ebx, ecx
	jge loop_cont
	add eax, edx
	inc ebx
	jmp loop

loop_cont:

	mov [rel result], eax
	jmp exit

func:
	
	mov eax, [rel result]
	mov ebx, [rel time]
	mov ecx, [rel total]
	mov edx, [rel addValue]
	jmp loop

_start:

	mov rax, 10
	mov rdx, 0
	mov rcx, 3
	div rcx

	jmp func

	mov rax, 60
	mov rdi, 0
	syscall
	

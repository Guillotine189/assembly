section .data
	error_getting_mmap db "Error getting mapping address: ", 0
	error_getting_mmap_len equ $ - error_getting_mmap

	error_mmap db 0

section .bss
	buffer resb 1024

section .text

extern _print
extern _print_with_new_line
extern _print_error_with_new_line

global _start


_start:
	mov rbp, rsp

	
	mov rax, 9 								; syscall for mmap
	mov rdi, 0 								; address NULL/0 for any mapping
	mov rsi, 4096 							; len for mapping in page size multiple
	mov rdx, 3 								; premission for mappping, 1+2 (read+write)
	mov r10, 34 							; 32+2 -> flag_anonymous+flag_private
	mov r8, -1 								; fd -1, not a reg file
	mov r9, 0 								; offset 
	syscall 					; returns the starting address of the memory

	test rax, rax
	jl .set_error_getting_mmap_and_exit

	push rax 							; save the starting of this mapping

	mov byte [rax], 104
	mov byte [rax + 1], 101
	mov byte [rax + 2], 108
	mov byte [rax + 3], 108
	mov byte [rax + 4], 111
	mov byte [rax+5], 0

	mov rax, 5
	mov rdi, 1
	mov rsi, [rbp - 8]
	call _print_with_new_line


	.first:
	; find brk
	mov rax, 12
	xor rdi, rdi 									; get the position of brk
	syscall

	mov rcx,rax
	add rax, 4096
	mov rdi, rax
	mov rax, 12
	syscall

	.second:
	; find brk
	mov rax, 12
	xor rdi, rdi 									; get the position of brk
	syscall

	mov rcx,rax
	add rax, 4096
	mov rdi, rax
	mov rax, 12
	syscall


	; munmap
	mov rax, 11
	mov rdi, [rbp - 8]
	mov rsi, 4096
	syscall



	jmp _exit 						; place holder

	.set_error_getting_mmap_and_exit:
		mov [rel error_mmap], rax
		jmp .error_getting_mmap_and_exit


.error_getting_mmap_and_exit:
	mov rax, error_getting_mmap_len
	mov rdi, 1
	lea rsi, [rel error_getting_mmap]
	call _print

	mov rax, [rel error_mmap]
	call _print_error_with_new_line

	jmp _exit_with_status_code_1


_exit_with_status_code_1:
	mov rax, 60
	mov rdi, 1
	syscall
	
_exit:
	mov rax, 60
	mov rdi, 0
	syscall
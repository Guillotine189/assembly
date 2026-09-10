section .data
	error_getting_mmap db "Error getting mapping address: ", 0
	error_getting_mmap_len equ $ - error_getting_mmap

	error_getting_brk db "Error getting brk value : ", 0
	error_getting_brk_len equ $ - error_getting_brk

	error_mmap db 0

section .bss
	buffer resb 1024

section .text

extern _print
extern _print_with_new_line
extern _print_error_with_new_line

global _start


; rdi : size of memory is bytes
; returns : address of memory where the asked bytes are free to use in rax
; 		  : -ve number on error
_malloc:
	











_start:
	mov rbp, rsp

	jmp _exit

.error_getting_mmap_and_exit:
	mov rax, error_getting_mmap_len
	mov rdi, 1
	lea rsi, [rel error_getting_mmap]
	call _print

	mov rax, [rel error_mmap]
	call _print_error_with_new_line

	jmp _exit_with_status_code_1

.error_getting_brk_and_exit:
	mov rax, error_getting_brk_len
	mov rdi, 1
	lea rsi, [rel error_getting_brk]
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
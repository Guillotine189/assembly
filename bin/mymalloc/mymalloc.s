section .data

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

	mov rbx, rdi 					;store how much data to get in callee-saved reg

	; get the current break address
	mov rax, 12 								;syscall sys_brk
	xor rdi, rdi 								; 0 to find current brk address
	syscall 									; rax has curr brk address

	test rax, rax
	jl .error_getting_current_brk_address


	mov r12, rax 						; save old brk address

	; move brk up
	mov rax, 12
	mov rdi, r12 						; address of old brk
	add rdi, rbx 						; add new length for new address
	syscall 							; rax has new brk position

	test rax, rax
	jl .error_moving_brk_up

	jmp .send_old_address_back


	.send_old_address_back:
		mov rax, r12 						; r12 address of old brk
		ret

	.error_moving_brk_up:
		ret 						; error no still in rax 

	.error_getting_current_brk_address:
		call _error_getting_brk 		; TODO: remove this later when using as library
		ret 							; error no still in rax 





_start:
	mov rbp, rsp



	.first:
	mov rdi, 4096
	call _malloc

	.second:
	mov rdi, 4096
	call _malloc



	jmp _exit


_error_getting_brk:
	mov rax, error_getting_brk_len
	mov rdi, 1
	lea rsi, [rel error_getting_brk]
	call _print

	mov rax, [rel error_mmap]
	call _print_error_with_new_line


_exit_with_status_code_1:
	mov rax, 60
	mov rdi, 1
	syscall
	
_exit:
	mov rax, 60
	mov rdi, 0
	syscall
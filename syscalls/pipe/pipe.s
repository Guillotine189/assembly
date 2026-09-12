; ./pipe program1 program2 : output of 1st program will be given to input of second program

section .data
	error_getting_pipe db "Error getting pipe. Exiting..", 0
	error_getting_pipe_len equ $ - error_getting_pipe

	error_changing_fd db "Error changing fd: ",0
	error_changing_fd_len equ $ - error_changing_fd 

	error_running_process db "Error running process: ", 0
	error_running_process_len equ $ - error_running_process


section .bss
	reusable_pipe_buffer resd 2 				; 4*2 bytes, [pipe read, pipe write]

section .text
extern _strlen
extern _print
extern _print_with_new_line
extern _print_error_with_new_line

global _start


program_1_add_off equ 16
program_2_add_off equ 24

_start:
	mov rbp, rsp


	; get program_1 program_2
	mov rax, [rbp + program_1_add_off] 						; has address of progrm1
	mov rdi, rax
	call _strlen
	mov rdi, 1
	mov rsi, [rbp + program_1_add_off]
	call _print_with_new_line

	mov rax, [rbp + program_2_add_off] 						; has address of program 2
	mov rdi, rax
	call _strlen
	mov rdi, 1
	mov rsi, [rbp + program_2_add_off]
	call _print_with_new_line


	.pipe_call:
	mov rax, 22 					; pipe syscall
	lea rdi, [rel reusable_pipe_buffer]
	syscall

	test rax, rax
	jl .error_getting_pipe_and_exit

	; fork, then change fd of 1st child and run program

	mov rax, 57
	syscall

	test rax, rax
	jnz .start_second_process

	; this is the 1st program
	; change the fd dup2(oldfd, newfd) (fd1, fd2) -> fd2 = fd1

	;the file descriptor newfd is adjusted so that it now refers to the same open file description as oldfd.


	mov eax, 33
	mov edi, [rel reusable_pipe_buffer + 4]
	mov esi, 1
	syscall

	test rax, rax
	jl .error_changing_fd_and_exit

	; close original read end
	mov eax, 3
	mov edi, [rel reusable_pipe_buffer]
	syscall

	; close original write end
	mov eax, 3
	mov edi, [rel reusable_pipe_buffer + 4]
	syscall

	test rax,rax
	jl .error_changing_fd_and_exit

	; construct argc for this process
	mov rax, 0
	push rax
	mov rax, [rbp + program_1_add_off]
	push rax 								; stack: address|NULL|RBP|argc

	mov rax, 59 					; execve
	mov rsi, rsp
	mov rdi, [rsi]

	mov rdx, [rbp]
	add rdx, 2
	lea rdx, [rbp+rdx*8] 				; envp

	syscall

	jmp .error_running_process_and_exit


	.start_second_process:
		; fork, then change fd of 2st child and run program
	mov rax, 57
	syscall

	test rax, rax
	jnz .parent_wait

	; This is 2nd process


	; stdin = pipe read
	mov eax, 33
	mov edi, [rel reusable_pipe_buffer]
	xor esi, esi
	syscall

	test rax,rax
	jl .error_changing_fd_and_exit

	; close original read end
	mov eax, 3
	mov edi, [rel reusable_pipe_buffer]
	syscall

	; close original write end
	mov eax, 3
	mov edi, [rel reusable_pipe_buffer + 4]
	syscall
 					; terminal_read(fd0) -> pipe_read


	; construct argc for this process
	mov rax, 0
	push rax
	mov rax, [rbp + program_2_add_off]
	push rax 								; stack: address|NULL|RBP|argc

	mov rax, 59 					; execve
	mov rsi, rsp
	mov rdi, [rsi]
	
	mov rdx, [rbp]
	add rdx, 2
	lea rdx, [rbp+rdx*8] 				; envp

	syscall

	jmp .error_running_process_and_exit

	.parent_wait:

		; parent no longer needs either pipe FD
	    mov eax, 3
	    mov edi, [rel reusable_pipe_buffer]
	    syscall

	    mov eax, 3
	    mov edi, [rel reusable_pipe_buffer + 4]
	    syscall

		; wait for first child
		mov eax, 61
		mov edi, -1
		xor esi, esi
		xor edx, edx
		xor r10d, r10d
		syscall

		; wait for second child
		mov eax, 61
		mov edi, -1
		xor esi, esi
		xor edx, edx
		xor r10d, r10d
		syscall

	jmp _exit


.error_getting_pipe_and_exit:
	push rax
	mov rax, error_getting_pipe_len
	mov rdi, 1
	lea rsi, [rel error_getting_pipe]
	call _print

	pop rax
	call _print_error_with_new_line

	jmp	_exit


.error_changing_fd_and_exit:
	push rax
	mov rax, error_changing_fd_len
	mov rdi, 1
	lea rsi, [rel error_changing_fd]
	call _print

	pop rax
	call _print_error_with_new_line

	jmp	_close_pipe_and_exit

.error_running_process_and_exit:
	push rax
	mov rax, error_running_process_len
	mov rdi, 1
	mov rsi, [rel error_running_process]
	call _print


	pop rax
	call _print_error_with_new_line

	jmp _close_pipe_and_exit


_close_pipe_and_exit:
	mov rax, 3
	mov edi, [rel reusable_pipe_buffer]
	syscall

	mov eax, 3
	mov edi, [rel reusable_pipe_buffer + 4]
	syscall


	jmp _exit

_exit:
	mov rax, 60
	mov rdi, 0
	syscall
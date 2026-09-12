sys_read equ 0
sys_stat equ 4
sys_getpid equ 39
sys_fork equ 57
sys_execve equ 59
sys_wait4 equ 61

S_MODE_OFF equ 24

S_IFMT equ 0170000
S_IFREG equ 0100000    ; regular file
S_IFDIR equ 0040000    ; directory
S_IFLNK equ 0120000    ; symbolic link
S_IFIFO equ 0010000    ; FIFO
S_IFSOCK equ 0140000   ; socket
S_IFCHR equ 0020000    ; character device
S_IFBLK equ 0060000    ; block device

S_IRUSR equ 0400    ; owner read
S_IWUSR equ 0200    ; owner write
S_IXUSR equ 0100    ; owner execute

S_IRGRP equ 0040    ; group read
S_IWGRP equ 0020    ; group write
S_IXGRP equ 0010    ; group execute

S_IROTH equ 0004    ; others read
S_IWOTH equ 0002    ; others write
S_IXOTH equ 0001    ; others execute


section .data
	child_line db "Hello from child process", 0
	child_line_len equ $ - child_line
	parent_line db "Hello from parent process", 0
	parent_line_len equ $ - parent_line

	press_enter_line db "Press enter to execute your program", 0
	press_enter_line_len equ $ - press_enter_line

	executing_child_process_line db "Executing child process now..",10,"------------------------------------------------------------",10,0
	executing_child_process_line_len equ $ - executing_child_process_line

	child_process_done_line db 10,"------------------------------------------------------------",10,"Child process exited with status code: ", 0
	child_process_done_line_len equ $ - child_process_done_line

	child_process_killed_line db 10,"------------------------------------------------------------",10,"Child process Terminated with status code ", 0
	child_process_killed_line_len equ $ - child_process_killed_line

	child_process_exit_code dq 0

	error_getting_info_about_executable_line db "Error getting info about: ", 0
	error_getting_info_about_executable_line_len equ $ - error_getting_info_about_executable_line

	error_creating_child_process_line db "Error creating child process: ", 0
	error_creating_child_process_line_len equ $ - error_creating_child_process_line

	error_number dq 0

section .bss
	reusable_stat_buffer resb 144
	reusable_buffer resb 1024 


section .text

extern _print
extern _print_with_new_line
extern _strlen
extern _print_error_with_new_line
extern _itoa


global _start


_start:
	mov rbp, rsp


	; find weather the exectable entered a valid executable of not
	; executable_name_offset =  +16

	mov rax, sys_stat
	mov rdi, [rbp + 16] 						; address of the executable
	lea rsi, [rel reusable_stat_buffer]
	syscall

	test rax, rax
	jl .set_error_getting_info_about_executable_and_exit

	; read permission for execute for OWNER 

	mov eax, [rel reusable_stat_buffer + S_MODE_OFF] ; 4bytes
	and eax, S_IXUSR
	cmp eax, 0
	jnz .owner_can_execute_this_file

	jmp _exit 

	.owner_can_execute_this_file:

	mov rax, sys_fork
	syscall

	; for child: 0 is retured
	; for parent: pid of child is returned 
	test rax, rax
	jl .set_error_creating_child_process_and_exit
	jnz .parent


	; this is code for child
	mov rax, child_line_len
	mov rdi, 1
	lea rsi, [rel child_line]
	call _print_with_new_line


	mov rax, press_enter_line_len
	mov rdi, 1
	lea rsi, [rel press_enter_line]
	call _print_with_new_line

	mov rax, sys_read
	mov rdi, 0 					; fd
	lea rsi, [rel reusable_buffer] 		; address of reusable_buffer where data is copied to
	mov rdx, 1024 				; how much input to copy
	syscall


	; now find the address where env variables address start

	call .print_executing_child_process_line


	mov rax, sys_execve
	mov rdi, [rbp + 16] 				; address of executable name
	lea rsi, [rbp + 16] 				; address where addresses of argv starts
	mov rcx, [rbp] 						; stack: 4 ./fork_execve executable arg2 arg3 NULL
	add rcx, 2 							; bec of NULL which is also 8bytes
	lea rdx, [rbp+rcx*8] 				; address where addresses of env address start
	syscall

	jmp _exit

	; this is the rest of the code for parent
	.parent:

	push rax 				; store the child pid in stack

	mov rax, parent_line_len
	mov rdi, 1
	lea rsi, [rel parent_line]
	call _print_with_new_line

	mov rax, sys_wait4
	mov rdi, [rbp - 8]					 			; the pid of child
	lea rsi, [rel child_process_exit_code]		; address for child's exit status
	xor rdx, rdx         					; 0 -> normal blocking wait option
	xor r10, r10         					; don't need resource usage
	syscall

	jmp .child_process_done_and_exit

	.set_error_creating_child_process_and_exit:
		mov [rel error_number], rax 			; set the error number
		jmp .error_creating_child_process_and_exit


	.set_error_getting_info_about_executable_and_exit:
		mov [rel error_number], rax 			; set the error number
		jmp .error_getting_info_about_executable


.error_getting_info_about_executable:
	mov rax, error_getting_info_about_executable_line_len
	mov rdi, 1
	lea rsi, [rel error_getting_info_about_executable_line]
	call _print

	; the executable name
	mov rdi, [rbp + 16]
	call _strlen

	mov rdi, 1 
	mov rsi, [rbp + 16]							; print the name of executable passed
	call _print 

	mov rdi, [rel error_number]
	call _print_error_with_new_line

	jmp _exit_with_status_code_1	

.error_creating_child_process_and_exit:
	mov rax, error_creating_child_process_line_len
	mov rdi, 1
	lea rsi, [rel error_creating_child_process_line]
	call _print

	mov rdi, [rel error_number]
	call _print_error_with_new_line

	jmp _exit_with_status_code_1

.print_executing_child_process_line:
	mov rax, executing_child_process_line_len
	mov rdi, 1
	lea rsi, [rel executing_child_process_line]
	call _print_with_new_line
	ret


.child_process_done_and_exit:

	; check if child process exited normalyy or killed
	mov eax, [rel child_process_exit_code]
	test al, 0x7f
	jnz .killed_by_signal

	.normal_exit:
	shr eax, 8
	and eax, 0xff 					; this has the actual status code now

	cmp eax, 0
	je .zero_status_code
	
	sub rsp, 8
	mov rdi, rsp 				; convert status code into ascii, and put it into stack
	call _itoa

	mov rdi, rsp
	call _strlen
	push rax
	jmp .print_errors

	.zero_status_code:
		mov rax, 48
		push rax
		mov rax, 8
		push rax

	.print_errors:
	mov rax, child_process_done_line_len
	mov rdi, 1
	lea rsi, [rel child_process_done_line]
	call _print

	pop rax
	mov rdi, 1
	mov rsi, rsp
	call _print_with_new_line

	add rsp, 8
	jmp _exit

	.killed_by_signal:
	and eax, 0x7f		 ; this has the actual status code now
	

	cmp eax, 0
	je .zero_status_code_

	sub rsp, 8
	mov rdi, rsp 				; convert status code into ascii, and put it into stack
	call _itoa

	mov rdi, rsp
	call _strlen
	push rax
	jmp .print_errors2

	.zero_status_code_:
		mov rax, 48
		push rax
		mov rax, 8
		push rax

	.print_errors2:
	mov rax, child_process_killed_line_len
	mov rdi, 1
	lea rsi, [rel child_process_killed_line]
	call _print


	pop rax
	mov rdi, 1
	mov rsi, rsp
	call _print_with_new_line
	
	add rsp, 8
	jmp _exit



	
_exit_with_status_code_1:
	
	mov rax, 60
	mov rdi, 1
	syscall

_exit:
	mov rax, 60
	mov rdi, 0
	syscall
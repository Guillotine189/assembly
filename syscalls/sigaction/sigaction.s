; except SIGKILL, SIGSTOP i can write handlers for anything
SIGKILL equ  9
SIGSTOP equ  19

SIGABRT 	equ  6
SIGALRM 	equ  14
SIGBUS  	equ 7
SIGCHLD 	equ  17
SIGCONT 	equ  18
SIGFPE  	equ 8
SIGHUP  	equ 1
SIGILL  	equ 4
SIGINT  	equ 2
SIGPOLL 	equ  29
SIGIO 		equ  SIGPOLL
SIGIOT 		equ  SIGABRT
SIGPIPE 	equ  13
SIGPROF 	equ  27
SIGPWR 		equ  30
SIGQUIT 	equ  3
SIGSEGV 	equ  11
SIGSTKFLT 	equ  16
SIGSTKSZ 	equ  8192
SIGSYS	 	equ  31
SIGTERM 	equ  15
SIGTRAP 	equ  5
SIGTSTP 	equ  20
SIGTTIN 	equ  21
SIGTTOU 	equ  22
SIGURG 		equ  23
SIGUSR1 	equ  10
SIGUSR2 	equ  12
SIGVTALRM 	equ  26
SIGWINCH 	equ  28
SIGXCPU 	equ  24
SIGXFSZ 	equ  25

SA_RESTORER equ 0x04000000 	;flag value to tell kernal that restorer function is seperate
SA_RESTART equ 0x10000000 	; if a syscall was in progress, restart that syscall
SA_RESETHAND equ 0x80000000 ; after rec the interrupt once, reset the handler to default.


section .data
	tell_kernel_line db "To tell kernel about custom  ctrl+c handler, press enter.", 0
	tell_kernel_line_len equ $ - tell_kernel_line

	told_kernel_line db "Told the kernel about custom ctrl+c handler, press ctrl+c to test or press enter to exit.", 0
	told_kernel_line_len equ $ - told_kernel_line

	hello_line db "Hello from side the handler. Press ctrl+c again to exit.",0
	hello_line_len equ $ - hello_line

	align 8
	sa:
		dq _handler 						; address of handler
		dq SA_RESTORER | SA_RESTART  | SA_RESETHAND       ; for the flags
	    dq _restorer            			; address of restorer
	    times 16 dq 0        				; 16 times dq = 16x8 = 128bytes for maskA


	error_making_cutom_sigint_handler db "Error making custom SIGINT handler",0
	error_making_cutom_sigint_handler_len equ $ - error_making_cutom_sigint_handler


section .bss
	buffer resb 1024


section .text

extern _print_with_new_line

global _start

_handler:
	mov rax, hello_line_len
	mov rdi, 1
	lea rsi, [rel hello_line]
	call _print_with_new_line
	ret 

_restorer:
	mov rax, 15      ; SYS_rt_sigreturn
    syscall


_start:
	mov rax, tell_kernel_line_len
	mov rdi, 1
	lea rsi, [rel tell_kernel_line]
	call _print_with_new_line

	; basically wait for user to press enter before telling kernel about SIGINT custom handler

	mov rax, 0
	mov rdi ,0
	lea rsi, [rel buffer]
	mov rdx, 1024
	syscall


	mov rax, 13 					;sys_rt_sigaction
	mov rdi, SIGINT
	lea rsi, [rel sa] 				; address where the info about handler lives
	xor rdx, rdx 					; no address to get old config about this interrupt
	mov r10, 8 						; sizeof(sigset_t) = 8, expected by kernel
	syscall

	test rax, rax
	jl .error_making_cutom_sigint_handler_and_exit

	mov rax, told_kernel_line_len
	mov rdi, 1
	lea rsi, [rel told_kernel_line]
	call _print_with_new_line


	; basically wait for user to press enter before exiting
	 
	mov rax, 0
	mov rdi ,0
	lea rsi, [rel buffer]
	mov rdx, 1024
	syscall

	jmp _exit


.error_making_cutom_sigint_handler_and_exit:
	mov rax, error_making_cutom_sigint_handler_len
	mov rdi, 1
	lea rsi, [rel error_making_cutom_sigint_handler]
	call _print_with_new_line

	jmp _exit_status_code_1

_exit_status_code_1:
	mov rax, 60
	mov rdi, 1
	syscall

_exit:
	mov rax, 60
	mov rdi, 0
	syscall
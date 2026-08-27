; this files takes in input of 1024bytes from fd0, outputs the input and the arguments provided.


; Linux automaically adds the arguments you pass when you run the binary with args in stack
;								RSP points to top of this stack
;							              ↓
;							      ┌─────────────────────┐
;							+0    │ argc = 3            │ 8 bytes
;							      ├─────────────────────┤
;							+8    │ address of argv[0]  │ 8 bytes
;							      ├─────────────────────┤
;							+16   │ address of argv[1]  │ 8 bytes
;							      ├─────────────────────┤
;							+24   │ address of argv[2]  │ 8 bytes
;							      ├─────────────────────┤
;							+32   │ NULL                │ 8 bytes
;							      └─────────────────────┘
;				the argv values are also inside the stack in some other location


section .data
	line DB "Argument passed: ", 0
	idx dq 1
	total_bytes dq 0


section .bss
	buffer resb 1024


section .text

global _start


_find_length: 							; expects address of variable in rax, rcx to be 0

	.loop:
		cmp byte [rax + rcx], 0 		; if the BYTE(we are reading bytes not 8bytes,
		je .found					 	;so writing 'byte is important') is not 0, it must be part of arg
		
		inc rcx
		jmp .loop

	.found:
	
		ret



_print_arguments:
	
	.compare:
		mov rax, [rel idx]
		cmp rax, [rsp]					; compare the idx with total arguments given[1 min bec of program itslef]
		jge done

	.print_default_line:

		mov rax, 1 						; read syscall
		mov rdi, 1 						; fd=1 terminal:out
		mov rsi, line
		mov rdx, 17
		syscall

	.find_bytes_for_arg:

		mov rdx, [rel idx]
		mov rax, [rsp + 8 + rdx*8]
		mov rcx, 0
		call _find_length 				; output lenght of variable in rcx
		add qword [rel total_bytes], rcx

	.print_argument:

		mov rax, 1 						; read syscall
		mov rdi, 1 						; fd=1 terminal:out
		mov rsi, [rsp + 8 + rdx*8]  ; address of where the data lives
		mov rdx, rcx					; bytes to print
		syscall

	.increase:

		mov rax, [rel idx]
		inc rax
		mov [rel idx], rax				; increase idx

	.print_new_line:

		mov rax, 0x0a
		push rax

		mov rax, 1 						; read syscall
		mov rdi, 1 						; fd=1 terminal:out
		mov rsi, rsp
		mov rdx, 1 						; because i only pushed 1 byte of actual info, i need to only print 1 byte
		syscall
		pop rax

	.loop:
		jmp .compare


_start:

	mov rax, 0 						; read syscall
	mov rdi, 0 						; fd=0 terminal:in
	mov rsi, buffer
	mov rdx, 1024
	syscall

	mov rdx, rax
	mov rax, 1 						; read syscall
	mov rdi, 1 						; fd=1 terminal:out
	mov rsi, buffer
	syscall

	jmp _print_arguments

done:
	

	mov rax, 60
	mov rdi, 0
	syscall


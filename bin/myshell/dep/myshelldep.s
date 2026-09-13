section .text

global _print
global _print_with_new_line
global _strlen
global _itoa
global _mem_copy
global _string_copy_including_null


; rax: number of bytes to print 
; rdi: fd to write to
; rsi: address of string 
; returns bytes printed rax
_print:

	mov rdx, rax					; rdx total bytes
	mov rax, 1 						; write syscall
	syscall
	ret

; rax: number of bytes to print 
; rdi: fd to write to
; rsi: address of string 
; returns bytes printed rax
_print_with_new_line:

	mov rdx, rax					; rdx total bytes
	mov rax, 1 						; write syscall
	syscall

	; print new line
	mov rax, 10
	push rax

	mov rax, 1
	mov rdi, 1 						; fd
	mov rsi, rsp 					; buffer address
	mov rdx, 1 						; bytes to print
	syscall

	.cleanup:
	pop rax
	ret


; rdi: address of string
; return stored in rax
; searches until \0 encountered, return len excluding \0
_strlen:

	.intialize:
		xor rax, rax				; rax will store string length

	.loop:

		cmp byte [rdi + rax], 0 			; move byte inside rcx
		je .finish

		inc rax
		jmp .loop

	.finish:
		ret

; rax : the number
; rdi : address of buffer in which output is stored
; return address of buffer in rcx
; length of number in rax
_itoa:
	push rbp
	mov rbp, rsp

	xor r8, r8								; index when writing from stack
	xor r9, r9								; count of digits
	xor rsi, rsi							; holds count of digits
	mov r10, 10 							; constant divisor
	
	.loop:
		; check if i have to process anohter number
		test rax, rax
		je .move_data_to_buffer

		; find last digit 
		xor rdx, rdx						; clear rdx before division
		div r10
		add rdx, 48

		; push 1 byte to stack
		sub rsp, 1
		mov [rsp], dl

		inc r9
		inc rsi
		jmp .loop

	.move_data_to_buffer:
		cmp r9, 0
		je .done

		; read 1 byte from stack
		mov al, [rsp]
		add rsp, 1
		
		mov [rdi + r8], al
		inc r8
		sub r9, 1
		jmp .move_data_to_buffer


	.done:
		mov [rdi + r8], 0

		pop rbp
		mov rcx, rdi
		mov rax, rsi
		ret



; rdi : dest address
; rsi : src address
; rdx : how many bytes to copy
; returns: rax : the how many bytes copied
_mem_copy:
	push rbp
	mov rbp, rsp
	push rdx

	; find how many 8 bytes i can copy
	mov rax, rdx
	shr rax, 3 					; basically rax/8 quotient

	; find how many 1 bytes i need to copy
	mov rcx, rdx
	and rcx, 7 					; basically rdx%8

	.loop_eight_bytes:

		test rax, rax
		jz .loop_single_byte

		mov rdx, [rsi] 				; move 8bytes into register
		mov qword [rdi], rdx 				; move 8 bytes into memory

		add rsi, 8
		add rdi, 8

		dec rax

		jmp .loop_eight_bytes


	.loop_single_byte:
		test rcx, rcx
		je .done

		mov dl, [rsi]
		mov [rdi], dl

		inc rsi
		inc rdi

		dec rcx

		jmp .loop_single_byte

	.done:
		pop rax
		mov rsp, rbp
		pop rbp
		ret

; rdi : address of destination string
; rsi : address of source string
; return: rax : the len of string
; 		: rdi : the address of null byte(\0)
_string_copy_including_null:
	xor rax, rax

	.loop_copy:
		mov cl, [rsi + rax]
		mov [rdi + rax], cl

		cmp cl, 0
		je .done

		inc rax
		jmp .loop_copy

	.done:
		add rdi, rax
		ret
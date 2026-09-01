section .data
	arg1 DB "STRING1", 0
	arg2 DB "STRING2", 0
	string DB "22102149", 0

section .bss
	buffer RESB 9
	int_str_fmt resb 20

section .text

global _start


; rax 	 : size n
; rdi 	 : dest address
; rsi 	 : src address
; returns: pointer to dest address in  rax 
_memcpy:

	xor r9, r9							; this will store how many bytes i have copied
	push rdi
	.loop:
		; check if i have to cpoy another byte
		cmp r9, rax 						; rax will always store the original count of bytes until i 
		je .done

		; move data from src to destination
		mov bl , [rsi + r9]					; move exactly 1 byte
		mov [rdi + r9] , bl 				; 1 byte

		; increment bytes copied and loop
		inc r9
		jmp .loop

	.done:
		pop rax
		ret 


; rax : address string 1
; rdi : address string 2
; returns in rax
; 		 : 0 if string 1 and 2 are equal
;		 : 1 if string 1 > string 2
;		 : -1 if string 1 < string 2

; compare the 2 strings terminated by \0, char by char, until \0 or one of them has low ascii value
_strcmp:
	
	xor r9, r9										; this will act as a address index

	.loop:
		mov bl, [rax + r9]								; store value [1 byte]
		mov cl, [rdi + r9]		

		cmp bl, cl
		
		; case 1 : string 1 < srring 2
		jb .handle_string_one_smaller					; carry flasg = 1, jump below will work

		; case 2 : both are equal
		je .handle_equal

		; case 3 : string 1 > string 2
		ja .handle_string_one_bigger					; sign flag = 0, jump below will work

	.handle_string_one_smaller:
		mov rax, -1
		ret

	.handle_equal:
		; check if they ended, both has 0
		test rbx, rbx
		je .return_equal						; if both had \0 -> ZF = 1

		inc r9
		jmp .loop								; else just jump to loop

	.handle_string_one_bigger:
		mov rax, 1
		ret

	.return_equal:
		mov rax, 0
		ret



; rax : address of string
; returns the interger for of string in rax, max 4 bytes(2^32)
_atoi:

	mov rsi, rax
	xor rcx, rcx									; just to empty rcx

	xor rax, rax									; rax stores the final result
	xor r9, r9										; index for bytes counting

	mov r10, 10 									; mutiple constant

	.loop:
		; check weather i have to add another number
		mov cl, [rsi + r9]
		test cl, cl
		je .done

		; convert to integer, multiply old result by 10, add new number, loop
		sub cl, 48
		mul r10											; rax*rbx output stored in rax, rdx CHNAGED HERE
		add rax, rcx
		inc r9
		jmp .loop

	.done:
		ret


; rax : the number
; rdi : address of buffer
; return address of buffer in rax
_itoa:
	push rbp
	mov rbp, rsp

	xor r8, r8								; index when writing from stack
	xor r9, r9								; count of digits
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
		mov rax, rdi
		ret

_start:
	
	mov rax, 9
	mov rdi, buffer
	mov rsi, arg1
	call _memcpy


	mov rax, arg1
	mov rdi, arg2
	call _strcmp

	mov rax, string
	call _atoi

	mov rdi, int_str_fmt
	call _itoa

_exit:
	mov rax, 60
	mov rdi, 0
	syscall

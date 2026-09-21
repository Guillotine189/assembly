section .text

global _print
global _print_with_new_line
global _print_with_tabs
global _strlen
global _itoa
global _mem_copy
global _string_copy_including_null
global _strcmp
global _cmp_equal_memory
global _memcpy_with_end_char
global _strcpy_add_space_before_backslash


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

_print_with_tabs:
	mov rdx, rax					; rdx total bytes
	mov rax, 1 						; write syscall
	syscall

	; print new line
	mov rax, 0x09
	push rax

	mov rax, 1
	mov rdi, 1 						; fd
	mov rsi, rsp 					; buffer address
	mov rdx, 1 						; bytes to print
	syscall

	.cleanup:
	pop rax
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
	test rax, rax
	jz .zero_length
	jl .negative_number

	xor r11, r11
	jmp .convert_number_to_ascii

	.negative_number:
		mov r11, 1
		neg rax
		mov byte [rdi], '-'
		inc rdi

	.convert_number_to_ascii:
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

		test r11, r11 			; if number was negative add 1 to length
		jnz .add_one
		jmp .return

		.add_one:
			inc rax

		.return:
		ret

	.zero_length:
		mov rcx, rdi
		mov byte [rdi], '0'
		inc rdi
		mov byte [rdi], 0
		mov rax, 1
		ret



; rdi : dest address
; rsi : src address
; rdx : how many bytes to copy
; returns: rax : the how many bytes copied
_mem_copy:

	mov rcx, rdx
	shr rcx, 3 					; len/8 quotient

	mov rax, rcx  				; saving how many 8bytes to copy
	shl rax, 3 					; total 8bytes that are copied

	rep movsq 					; copy 8 bytes at a time


	mov rcx, rdx
	and rcx, 7 					; basically rdx%8
	add rax, rcx
	rep movsb 					; copy remaining 1 byte at a time

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



; rax : address string 1
; rdi : address string 2
; returns in rax
; 		 : 0 if string 1 and 2 are equal
;		 : 1 if string 1 > string 2
;		 : -1 if string 1 < string 2

; compare the 2 strings terminated by \0, char by char, until \0 or one of them has low ascii value
_strcmp:
	push rbx
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
		pop rbx
		mov rax, -1
		ret

	.handle_equal:
		; check if they ended, both has 0
		test bl, bl
		je .return_equal						; if both had \0 -> ZF = 1

		inc r9
		jmp .loop								; else just jump to loop

	.handle_string_one_bigger:
		pop rbx
		mov rax, 1
		ret

	.return_equal:
		pop rbx
		mov rax, 0
		ret

; rax: lenth of memory to compare
; rdi: address 1
; rsi: address 2
; returns : 0 if same, 1 if different
_cmp_equal_memory:
	; cld = clear direction flag, clears direction_flag to 0, rep, will +1 the registers
	; std: set direction flag, sets direction flag to = 1, if DF=1, rep will do -1 after every instruction
	cld 			; i never set std, but still

	mov rcx, rax
	shr rcx, 3 			; rcx = length to compare / 8
	
	repe cmpsq
	jne .not_equal

	mov rcx, rax
	and rcx, 7 			; ; rcx = length % 8 

	repe cmpsb   		; for remaining, comapre 1 byte at a time
	jne .not_equal
	jmp .equal

	.not_equal:
		mov rax, 1
		ret

	.equal:
		mov rax, 0
		ret


; rax 	 : size n
; rdi 	 : dest address
; rsi 	 : src address
; dl	 : end char after copy of string
; r8b 	 : if 0 -> dont append anything, anything else -> append dl
; returns: address of byte ahead of last byte written in  rax 
_memcpy_with_end_char:
	cld

	mov rcx, rax
	shr rcx, 3 			; rcx = length to compare / 8
	
	rep movsq 			; copy 8 bytes at a time

	mov rcx, rax
	and rcx, 7 			; ; rcx = length % 8 

	rep movsb   		; copy 1 byte at a time

	test r8b, r8b       ; if r8 is zero, i am done
	jz .done

	mov [rdi], dl   	; if r8 is not zero, copy the byte sent in dl register
	inc rdi

	.done:
	mov rax, rdi
	ret 


; rdi: address desstination string
; rsi: address source string
; returns: rdi: the address of null byte
_strcpy_add_space_before_backslash:
	xor rax, rax 			; index for input string
	xor rdx, rdx 			; indeex for output string

	.loop_copy:
		mov cl, [rsi + rax]

		cmp cl, ' '
		je .copy_slash_instead_of_space
		
		mov [rdi + rdx], cl
		jmp .loopback

		.copy_slash_instead_of_space:
			mov [rdi + rdx], '\'
			inc rdx
			mov [rdi + rdx], ' '

		.loopback:
		cmp cl, 0
		je .done

		inc rax
		inc rdx
		jmp .loop_copy

	.done:
		add rdi, rdx
		ret
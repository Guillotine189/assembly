section .text

global _strlen
global _print
global _memcpy_with_end_char
global _file_name_address

; rax: number of bytes to print 
; rdi: fd to write to
; rsi: address of string 
; returns bytes printed rax
_print:

	mov rdx, rax					; rdx total bytes
	mov rax, 1 						; write syscall
	syscall
	ret


; address of string in rdi
; return stored in rax
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


; rax 	 : size n
; rdi 	 : dest address
; rsi 	 : src address
; dl	 : end char after copy of string
; r8b 	 : if 0 -> dont append anything, anything else -> append dl
; returns: address of byte ahead of  last byte written in  rax 
_memcpy_with_end_char:

	xor r9, r9							; this will store how many bytes i have copied
	.loop:
		; check if i have to cpoy another byte
		cmp r9, rax 						; rax will always store the original count of bytes until i 
		je .add_end_char

		; move data from src to destination
		mov bl , [rsi + r9]					; move exactly 1 byte
		mov [rdi + r9] , bl 				; 1 byte

		; increment bytes copied and loop
		inc r9
		jmp .loop

	.add_end_char:
		test r8b, r8b
		jz .done

		mov al, dl
		mov [rdi + r9], al
		inc r9

	.done:
		mov rax, rdi
		add rax, r9
		ret 



; rax: size of string
; rdi: address of string
; returns : address inside string where the filename starts in rdi
;		  : size of original string in rax
_file_name_address:
	
	mov r9, rdi
	xor r8, r8						; bytes checked
	.loop:

		cmp r8, rax
		je .done

		mov cl, [r9 + r8]
		cmp cl, '/'
		jne .loopback

		inc r8
		mov rdi, r9
		add rdi, r8

		jmp .loop

		.loopback:

		inc r8
		jmp .loop

	.done:

		ret
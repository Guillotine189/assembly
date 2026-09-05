section .data
	single_dot db '.', 0
	double_dot db "..",0

section .text

global _strlen
global _print
global _print_with_new_line
global _memcpy_with_end_char
global _file_name_address
global _cmp_equal_memory
global _normalize_file_path
global _check_fp2_sub_dir_fp1


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


; rax: lenth of memory to compare
; rdi: address 1
; rsi: address 2
; returns : 0 if same, 1 if different
_cmp_equal_memory:

	xor r8, r8 				; stores how many bytes compared

	.loop:

		cmp r8, rax
		je .equal

		mov cl, [rdi + r8]						; 1 byte comparision
		mov dl, [rsi + r8]						; TODO: change it later for efficiency
		cmp cl, dl
		jne .not_equal

		inc r8
		jmp .loop


	.not_equal:
		mov rax, 1
		ret

	.equal:
		mov rax, 0
		ret

; rax: file path length
; rdi: file path address, [Absolute file path, atleast the beginning is valid/has a '/']
; rsi: dst address to put normalized fp into 
; returns : normalized file path length in rax
; reads the src path, normalizes it and puts it into dst address
; "/" at the will not be there
_normalize_file_path:
	; r8 -> offset for iterating through original src 
	; r9 -> total slashes seen
	; r10 -> length of normalized address
	; r11 -> len of component
	; rax, rdi, rsi -> original input throughout

	push rbp
    mov rbp, rsp

	xor r8, r8
	xor r9, r9
	xor r10, r10
	xor r11, r11

	.loop:
		; check if i have to process another byte
		cmp r8, rax
		je .finish

		; read a byte
		mov cl, byte [rdi + r8] 						; the actual byte
		cmp cl, '/'
		je .handle_slash

		; simply add the char to stack
		.handle_like_normal_char:
		; push cl 					; store the byte into stack
		sub rsp, 1
		mov byte [rsp], cl
		inc r11 					; len of component ++
		inc r10 					; normalized len++
		jmp .check_next_byte

	.handle_slash:
		inc r9									; total slahses seen ++

		; check if the bracket was seen the first time, or the second time
		cmp r9, 1 	 							; 1st time seeing
		je .first_slash

		; now i have to decide weather the component is valid or not

		; compare the component with ".", "..", ""
		test r11, r11 				; comp =  "" -> len of component is zero when
		jz .check_next_byte 		; "//" inside stack, just ignore 2nd '/'

		; compare component with "."

		cmp r11, 2
		je .compare_double_dot
		jl .compare_single_dot

		.valid_component:
		mov cl, '/'
		; push to stack 1 byte
		sub rsp, 1
		mov byte [rsp], cl
		inc r10 				; inc by 1 bec / added
		xor r11, r11			; len of new component 0
		jmp .check_next_byte


		.compare_single_dot:

		cmp byte [rsp], '.'
		je .ignore_because_single_dot
		jmp .handle_like_normal_char


		.ignore_because_single_dot:

		add rsp, 1							; pop the "." out of stack
		sub r10, 1 							; len of total norm fp -= 1
		xor r11, r11 						; len of new component = 0
		jmp .check_next_byte


		.compare_double_dot:

	    cmp byte [rsp], '.'
	    jne .valid_component
	    cmp byte [rsp + 1], '.'
	    jne .valid_component
	    jmp .remove_old_component_bec_double_dot



		.remove_old_component_bec_double_dot:
		
		add rsp, 3 			; pop the old '/..' out of stack
		sub r10, 3 			; sub 3 from normalized len

		; check if total length of normalized is 0

		; i expect the beginning to start with "/"
		; if string does not start with "/", the function breaks
		; "/folder/../../../" not possible to normalize so return -1
		cmp r10, 0
		jle .error_not_a_valid_file_path 		; nothing left after removing '/'

		xor r11, r11
		.find_prev_slash:
		    cmp byte [rsp], '/'
		    je .found_prev_slash

		    inc r11
		    add rsp, 1
		    jmp .find_prev_slash

		; len of component is zero now
		.found_prev_slash:
		sub r10, r11			; decrease normal fp len by len of old component
		xor r11, r11			; len of new component = 0
		jmp .check_next_byte



	.first_slash:
		mov cl, '/'
		sub rsp, 1
		mov byte [rsp], cl 				; put into stack '/'
		xor r11, r11 					; len of component = 0
		inc r10 					; normalized len++
		jmp .check_next_byte

	.check_next_byte:
		mov r9, 1 				; slashes seen = 1
		inc r8
		jmp .loop


	.error_not_a_valid_file_path:

	    mov rsp, rbp       ; no need to sub from stack, just make rsp point to base
	    pop rbp
	    
	    mov rax, -1
	    ret


	.finish:

	    test r11, r11 				; if no comp left
	    jz .maybe_remove_last_slash_if_exists
	    jmp .cont

	    .maybe_remove_last_slash_if_exists:
	    	cmp r10, 1 							; if the length of final path is 1, '/'
	    	je .copy_result 							; then do not remove

	    	cmp byte [rsp], '/' 				; else check if last byte was '/'
	    	je .remove_last_backlash 			; then remove
	    	jne .copy_result

	    .remove_last_backlash:
	    	add rsp, 1
	    	sub r10, 1
	    	jmp .copy_result

	    .cont:
	    cmp r11, 1 					
	    je .finish_single_dot

	    cmp r11, 2
	    je .finish_maybe_double_dot

	    .finish_single_dot:
	    	cmp byte [rsp], '.'
	    	je .remove_final_single_dot
	    	jne .copy_result

	    .finish_maybe_double_dot:
	    	cmp byte [rsp], '.'
	    	jne .copy_result

	    	cmp byte [rsp+1], '.'
	    	jne .copy_result

	    	je .remove_final_double_dot


	    .remove_final_single_dot:
	    	add rsp, 1
	    	sub r10, 1

	    	jmp .maybe_remove_last_slash_if_exists


	    .remove_final_double_dot:
		    add rsp, 3 			; pop the old '/..' out of stack
			sub r10, 3 			; sub 3 from normalized len

			; check if total length of normalized is 0

			; i expect the beginning to start with "/"
			; if string does not start with "/", the function breaks
			; "/folder/../../../" not possible to normalize so return -1
			cmp r10, 0
			jle .error_not_a_valid_file_path 		; nothing left after removing '/'

			xor r11, r11
			.find_prev_final_slash:
			    cmp byte [rsp], '/'
			    je .found_final_slash

			    inc r11
			    add rsp, 1
			    jmp .find_prev_final_slash


			.found_final_slash:
			sub r10, r11
			jmp .maybe_remove_last_slash_if_exists

	    .copy_result:
		; now copy the entire address to dest address
		lea rdi, [rsp + r10 - 1]
		mov rax, r10

		; rax = len
		; rdi = source address
		; rsi = destination address

		xor r11, r11              ; idx = 0

		.copy_loop:
		    cmp r11, rax
		    je .done

		    mov rcx, rdi
		    sub rcx, r11           ; rcx = rdi - idx

		    mov dl, byte [rcx]
		    mov byte [rsi + r11], dl

		    inc r11
		    jmp .copy_loop


	.done:
		mov rsp, rbp
		pop rbp
		ret




; rax 	 : size n
; rdi 	 : dest address
; rsi 	 : src address
; dl	 : end char after copy of string
; r8b 	 : if 0 -> dont append anything, anything else -> append dl
; returns: address of byte ahead of last byte written in  rax 
_memcpy_with_end_char:

	xor r9, r9							; this will store how many bytes i have copied
	.loop:
		; check if i have to cpoy another byte
		cmp r9, rax 						; rax will always store the original count of bytes until i 
		je .add_end_char

		; move data from src to destination
		mov cl , [rsi + r9]					; move exactly 1 byte
		mov [rdi + r9] , cl 				; 1 byte

		; increment bytes copied and loop
		inc r9
		jmp .loop

	.add_end_char:
		test r8b, r8b
		jz .done

		mov [rdi + r9], dl
		inc r9

	.done:
		mov rax, rdi
		add rax, r9
		ret 

; rdi: file path 1 address, make sure they are terminated with \0
; rsi: file path 2 address
; returns: 0 -> fp2 a sub directory of fp1
; 		   1 -> fp2 is NOT a sub dir of fp1
; both path received must either terminate without '/'
_check_fp2_sub_dir_fp1:
	

	xor r9, r9

	.loop:
		; check fp1
		cmp byte [rdi + r9], 0
	    je .fp1_ended

	    ; Check fp2
	    cmp byte [rsi + r9], 0
	    je .not_sub_dir

		mov al, [rdi + r9]
		mov cl, [rsi + r9]
		cmp al, cl
		jne .not_sub_dir

		inc r9
		jmp .loop

	.fp1_ended:
		; at thispoint, all the chars have been same
		; check if the next char is '/', in fp2, if it is, then its a subdir

		cmp byte [rsi + r9], '/'
		je .is_a_subdir

		cmp byte [rsi + r9], 0
		je .is_a_subdir

		jne .not_sub_dir

	.is_a_subdir:
		mov rax, 0
		ret
	.not_sub_dir:
		mov rax, 1
		ret

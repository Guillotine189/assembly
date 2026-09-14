section .data
	prompt db '>', 0
	prompt_len equ $ - prompt
	cursor_idx dq 0
	length dq 0

section .rodata
	

	move_cur_home_pos db 27, "[H", 0
	move_cur_end_pos db 27, "[F", 0
	move_cur_up db 27, "[A", 0
	move_cur_down db 27, "[B", 0
	move_cur_right db 27, "[C", 0
	move_cur_left db 27, "[D", 0
	erase_everything_after_cursor_including_cursor db 27, "[0K", 0

section .bss
	input_buffer resb 1024
	buffer resb 10
	termios     resb 60
    old_termios resb 60

SYS_IOCTL equ 16
C_LFLAG   equ 12
TCGETS    equ 0x5401
TCSETS    equ 0x5402


section .text


global _start


_print:
	mov rdx, rax					; rdx total bytes
	mov rax, 1 						; write syscall
	syscall
	ret


_start:
	
	; get old struct
	 mov     rax, SYS_IOCTL
    mov     rdi, 0
    mov     rsi, TCGETS
    lea     rdx, [rel termios]
    syscall

    ; Copy current settings to old_termios
    lea     rsi, [rel termios]
    lea     rdi, [rel old_termios]
    mov     rcx, 60
    rep     movsb

    ; modify old struct
    mov     eax, [rel termios + C_LFLAG]
    and     eax, ~(0x0002 | 0x0008)
    mov     [rel termios + C_LFLAG], eax

    ; apply new settings
    mov     rax, SYS_IOCTL
    mov     rdi, 0
    mov     rsi, TCSETS
    lea     rdx, [rel termios]
    syscall

	mov rax, 1
	mov rdi, 1
	lea rsi, [rel prompt]
	mov rdx, prompt_len
	syscall

	; one max 10 bytes read
	.read_key:
		mov rax, 0 						;sys_read
		mov rdi, 0 						; fd 0
		lea rsi, [rel buffer]
		mov rdx, 1 						; len to put into buffer
		syscall


		cmp byte [rel buffer], 27 
		je .escape_seq	

		cmp byte [rel buffer], 127 			; backspace
		je .handle_backspace

		cmp byte [rel buffer], 0x0a 		; TODO: move cursot to end of line before exit
		je _exit

		cmp byte [rel buffer], 0x09 		; tab, ignore
		je .read_key


		; move all the character from the cursorposition to right first

		cmp qword [rel length], 0
		jne .complex

		inc qword [rel length]
		inc qword [rel cursor_idx]
		mov al, [rel buffer]
		mov [rel input_buffer], al

		mov rax, 1
		mov rdi, 1
		lea rsi, [rel input_buffer]
		call _print



		jmp .read_key

		.complex:
		
		lea rax, [rel input_buffer]
		add rax, [rel length]   ; old length, so now rax points to 
		dec rax 				; address of the right most char in buffer
		lea rcx, [rel input_buffer]
		add rcx, [rel cursor_idx] 	; address of cursor

		cmp rcx, rax
		jg .done_copying

		.loop_shift_right:
			mov dl, [rax]
			mov [rax+1], dl

			cmp rax, rcx 			; end address and cursor address
			je .done_copying

			dec rax
			jmp .loop_shift_right

		.done_copying:
		inc qword [rel length]

		; insert new character into input_buffer
	    mov al, [rel buffer]
	    mov [rcx], al


	    ; print the updated right side
		lea rax, [rel input_buffer]
		add rax, [rel length] 			; the last byte is 1 byte ahead
		sub rax, rcx 				; address of last byte - add of cursor position
		push rax 
		mov rdi, 1
		lea rsi, [rel input_buffer]
		add rsi, [rel cursor_idx]
		call _print 						; cursor now at the end

		.done_printing:
		pop rdi
		dec rdi 							; i still want to move 1 space ahead
		.move_cursor_left:
			test rdi, rdi
		    jz .done

		    push rdi

		    mov rax, 1
		    mov rdi, 1
		    lea rsi, [rel move_cur_left]
		    mov rdx, 3
		    syscall

		    pop rdi
		    dec rdi
		    jmp .move_cursor_left

		.done:
		inc [rel cursor_idx]

		jmp .read_key

	.escape_seq:
		; read '['
		mov rax, 0
		xor rdi, rdi
		lea rsi, [rel buffer]
		mov rdx, 1
		syscall

		; read final char
		mov rax, 0
		xor rdi, rdi
		lea rsi, [rel buffer]
		mov rdx, 1
		syscall


		cmp byte [rel buffer], 'D'
		je .cursor_left

		cmp byte [rel buffer], 'C'
		je .cursor_right

	    cmp byte [rel buffer], 'H'
	    je .cursor_home

	    cmp byte [rel buffer], 'F'
	    je .cursor_end

		jmp .read_key


	.cursor_home:
		mov rax, [rel cursor_idx] 
	    test rax, rax
	    jz .read_key  			; if already at home do nothing

	    mov rdi, rax

	    .move_home:
	    test rdi, rdi
	    jz .home_done

	    push rdi

	    mov eax, 1
	    mov edi, 1
	    lea rsi, [rel move_cur_left]
	    mov edx, 3
	    syscall

	    pop rdi
	    dec rdi
	    jmp .move_home

		.home_done:
	    mov qword [rel cursor_idx], 0
	    jmp .read_key


	.cursor_end:
		mov rax, [rel length]
		sub rax, [rel cursor_idx]

		; rax has the number of positions to move right

		.move_end:
		test rax,  rax
		jz .end_done
		push rax

		mov rax, 1
		mov rdi, 1
		lea rsi, [rel move_cur_right]
		mov rdx, 3
		syscall

		pop rax
		dec rax
		jmp .move_end

		.end_done:
		mov rax, [rel length]
	    mov [rel cursor_idx], rax
	    jmp .read_key


	.cursor_left:
	    mov rax, [rel cursor_idx]

	    test rax, rax
	    jz .read_key

	    dec rax
	    mov [rel cursor_idx], rax

	    mov rax, 1
	    mov rdi, 1
	    lea rsi, [rel move_cur_left]
	    mov rdx, 3
	    syscall

	    jmp .read_key


	.cursor_right:
		
		mov rax, [rel cursor_idx]
		cmp rax, [rel length]
		jge .dont_move_forward

		inc rax
		mov [rel cursor_idx], rax

		mov rax, 1
		mov rdi, 1
		lea rsi, [rel move_cur_right]
		mov rdx, 3
		syscall

		.dont_move_forward:

		jmp .read_key

	; IMP: whichever index my cursor is at, i have to remove the prev element
	.handle_backspace:
		mov rax, [rel cursor_idx]

		test rax, rax 				; if i am at the very beginning dont, do anything
		jz .read_key


		; else copy memory from cursor till end to left
		lea rax, [rel input_buffer]
		add rax, [rel cursor_idx] 			; now i am at cursor index
		dec rax 							; at the index bfore cursor

		lea rcx, [rel input_buffer]
		add rcx, [rel length] 				; byte after buffer
		dec rcx 							; last byte of buffer

		cmp rax, rcx
		je .done_copying_left 		; to remove the last byte from buffer, no copy

		.loop_shift_left:

			cmp rax, rcx 			; when rax = last byte dont run.
			je .done_copying_left

			mov dl, [rax+1]
			mov [rax], dl

			inc rax
			jmp .loop_shift_left

		.done_copying_left:
		dec [rel length]

		; now print the changes, cursor pointing at the starting byte i neet to print

		mov rax, 1
	    mov rdi, 1
	    lea rsi, [rel move_cur_left]
	    mov rdx, 3
	    syscall
		dec qword [rel cursor_idx] 				; cursor at correct addess

		mov rax, [rel length]
		sub rax, [rel cursor_idx]
		push rax

		mov rdi, 1
		lea rsi, [rel input_buffer]
		add rsi, [rel cursor_idx]
		call _print 						; cursor now at the end

		; first remove old data, that was after this

	    mov rax, 1
	    mov rdi, 1
	    lea rsi, [rel erase_everything_after_cursor_including_cursor]
	    mov rdx, 4
	    syscall

		; now visially change cursor to go back last byte
		pop rdi
		.move_cursor_left_back:
			test rdi, rdi
		    jz .done2

		    push rdi

		    mov rax, 1
		    mov rdi, 1
		    lea rsi, [rel move_cur_left]
		    mov rdx, 3
		    syscall

		    pop rdi
		    dec rdi
		    jmp .move_cursor_left_back

		.done2:
		
	    jmp .read_key

_exit:

	; restore old struct
    mov     rax, SYS_IOCTL
    mov     rdi, 0
    mov     rsi, TCSETS
    lea     rdx, [rel old_termios]
    syscall



	mov rax, 60
	mov rdi, 0
	syscall
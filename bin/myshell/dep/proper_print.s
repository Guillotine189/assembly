%include "./dep/constants.inc"

section .data
	longest_word_len dq 0
	padding dq 2
	columns_per_line dq 0
	len_each_col dq 0

section .rodata
	new_line db 0x0a, 0

section .bss
	win_size:
    	resw 2   	; 2bytes row size, 2bytes column size
    	resw 2 	 	; 2bytes pixel width unavailable/zero, 2bytes pixel height unavai/zero

    output_string_object_address resq 1

    reusable_buffer_proper_print resb 4096


section .text


extern _print
extern _print_with_new_line
extern _strlen


extern _constructor_mystring
extern _destructor_mystring
extern _append_string_mystring


global _print_proper_layout




; rdi: string address
; "word\nword\nNULLBYTE"

_print_proper_layout:
	push rbp
	mov rbp, rsp


	push r12
	push r13
	push r14
	push r15

	mov r12, rdi

	mov qword [rel longest_word_len], 0
	mov qword [rel columns_per_line], 0
	mov qword [rel len_each_col], 0

	; find max length of 1 word
	; get the width of window
	; width of 1 column = max len + padding
	; total columns = total_width / with_1_col
	; say i get 4 column
	; print 4 words every column, then print \n
	; if wind width < longest name, column = 1


	; r12 has the address of string

	xor r8, r8 					; offset for start of word
	xor r9, r9 					; offset for end of word
	.loop_find_next_new_line:
		cmp byte [r12 + r9], 0
		je .get_window_dimensions

		cmp byte [r12 + r9], 0x0a
		je .new_line_found

		inc r9
		jmp .loop_find_next_new_line

	.new_line_found:
	; r8 is at address where the word starts, r9 is at address at next new_line byte is


	mov rax, r9
	sub rax, r8 			; this is the length of word

	cmp qword [rel longest_word_len], rax
	jge .loopback

	mov [rel longest_word_len], rax 			; update the longest 
	jmp .loopback


	.loopback:
		inc r9 						; r9 at starting of next word
		mov r8, r9 					; r8 at starting of next word
		jmp .loop_find_next_new_line



	.get_window_dimensions:


	mov rax, sys_ioctl
	mov rdi, 1              ; fd of terminal
	mov rsi, TIOCGWINSZ  	; get window size
	lea rdx, [rel win_size]
	syscall

	test rax, rax
	jl .return  ;TODO: if cannot get dimensions, simply print the line instead of returning

	
	xor rdx, rdx
	movzx rax, word [rel win_size + 2] 			; rax : terminal column width
    mov rcx, [rel longest_word_len] 			; rcx : max sizeof of word
    add rcx, [rel padding] 						; rcx : max_len + padding
    div rcx

    test rax, rax
    jz .biggest_word_greater_than_col

    mov [rel columns_per_line], rax 				; quotient > 0
    jmp .create_output

    .biggest_word_greater_than_col:
    	mov [rel columns_per_line], 1 

    .create_output:

    mov rax, [rel longest_word_len]
    add rax, [rel padding]
    mov [rel len_each_col], rax 					; lenght of each col


    movzx rax, word [rel win_size + 2] 			; rax : terminal column width
    sub rsp, 24
    mov qword [rsp + 0], rax             ; ask for col width len
    mov qword [rsp + 8], 0
    mov qword [rsp + 16], 0
    mov rdi, rsp
    call _constructor_mystring

    mov [rel output_string_object_address], rsp


    ; a word is len + padding

	xor r13, r13 					; offset for start of word
	xor r14, r14 					; offset for end of word
	xor r15, r15 				; how many words per line have been added

    .loop_till_words_per_line:

    cmp r15, [rel columns_per_line]
    je .call_add_a_new_line_char
    jmp .loop_till_new_line

    .call_add_a_new_line_char:
    	call .add_a_new_line_char


    .loop_till_new_line:

		cmp byte [r12 + r14], 0
		je .add_a_new_line_char_and_print

    	cmp byte [r12 + r14], 0x0a
		je .next_new_line_found

		inc r14
		jmp .loop_till_new_line

	.next_new_line_found:
		mov [r12 + r14], 0 			; new line char replaces with null byte

		; copy the word into the line
		mov rdi, [rel output_string_object_address]
		lea rsi, [r12 + r13]
		call _append_string_mystring

		mov rax, r14
		sub rax, r13 					; len of word
		
		mov rcx, [rel len_each_col]
		sub rcx, rax 					; rcx: extra spaces i need to add

		; i am going to append that many spaces into reusable buffer
		; this is a hack, bec if spaces > 4096 -> memory corruption

		lea rdi, [rel reusable_buffer_proper_print] 		; rdi: address where to add
		mov al, 0x20  					; which byte to add repeatedly, space here
		; rcx -> how many times to add
		rep stosb
		mov byte [rdi], 0 			; reusable buffer now has spaces + 0 ->  "     ", 0

		mov rdi, [rel output_string_object_address]
		lea rsi, [rel reusable_buffer_proper_print]
		call _append_string_mystring		

		; i have appended "word     ", in my string

		inc r15

		inc r14
		mov r13, r14

		jmp .loop_till_words_per_line


	.add_a_new_line_char:
		mov rdi, [rel output_string_object_address]
		lea rsi, [rel new_line]
		call _append_string_mystring
		xor r15, r15 							; next line now has 0 words
		ret

	.add_a_new_line_char_and_print:
		; if no words are there in new line, dont add another new line char
		test r15, r15 				
		jz .print_output
		
		mov rdi, [rel output_string_object_address]
		lea rsi, [rel new_line]
		call _append_string_mystring


	.print_output:
		mov rsi, [rel output_string_object_address]
		mov rax, [rsi + 8] 			; len of string
		mov rdi, 1
		mov rsi, [rsi + 16] 		; address of actual string
		call _print


    .cleanup_and_return:
    mov rdi, rsp
    call _destructor_mystring
    add rsp, 24

	.return:
		pop r15
		pop r14
		pop r13
		pop r12

		mov rsp, rbp
		pop rbp
		ret



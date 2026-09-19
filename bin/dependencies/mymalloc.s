section .data
	
	malloc_info db "myMalloc info: ", 0
	malloc_info_len equ $ - malloc_info
	info_total_seg db "Total segments: ", 0
	info_total_seg_len equ $ - info_total_seg
	info_filled_seg db "Total Occupied segments: ", 0
	info_filled_seg_len equ $ - info_filled_seg
	info_empty_seg db "Total Free segments: ", 0
	info_empty_seg_len equ $ - info_empty_seg

	malloc_address_first_segment dq 0
	malloc_address_last_segment dq 0
	malloc_total_segments dq 0
	malloc_empty_segments dq 0
	malloc_occupied_segments dq 0

	newline db 10

section .bss
	number_buffer resb 32


section .text


global _malloc
global _free
global _print_malloc_segments_info

; [free_size_of_this_segments] -> 8bytes
; [occupied|free]			   -> 8bytes
; [prev segment address] 	   -> 8bytes
; [next segment address] 	   -> 8bytes
; [actual_data_for_segment] 
; TOTAL size of segemnt: Requested size + 32bytes 


metadata_size equ 32
min_free_space_size equ 16
SIZE_OFF equ 0
USED_OFF equ 8
PREV_OFF equ 16
NEXT_OFF equ 24

; brk in ASSEMBLY, can return the old brk after asking for new brk on failure
; thats why rax might not contain a -ve number but the old brk
; to check this: if new value of brk asked != value returned => error

; rdi : size of memory is bytes
; returns : address of memory where the asked bytes are free to use in rax
; 		  : -ve number on error
_malloc:
	push rbx
	push r12
	push r13

	mov rbx, rdi 						;store requested size in callee-saved reg rbx

	; get the current break address
	mov rax, 12 								;syscall sys_brk
	xor rdi, rdi 								; 0 to find current brk address
	syscall 									; rax has curr brk address

	test rax, rax
	jl .error_getting_old_brk_address_and_ret

	mov r12, rax 						; save old brk address r12

	cmp qword [rel malloc_address_first_segment], 0
	je .assign_heap_start_address
	jmp .check_if_old_free_segment_available


	.assign_heap_start_address:
		mov [rel malloc_address_first_segment], r12
		mov [rel malloc_address_last_segment], r12
		mov r13, 0 				; prev segment address is 0 for first segment
		jmp .get_more_heap_space

	.check_if_old_free_segment_available:

	mov r8, [rel malloc_address_first_segment] 
	xor r9, r9 						; add of prev segment for 1st segment is 0

	.loop:
		cmp r8, r12 				; if all segment exhausted, get more space
		je .set_address_of_prev_seg_and_get_more_heap_space
		jmp .check_if_segment_is_free

		.set_address_of_prev_seg_and_get_more_heap_space:
			mov r13, r9 			; address of prev segment stored in r13
			jmp .check_if_last_segment_is_free


		.check_if_segment_is_free:
		cmp qword [r8+ USED_OFF], 0
		je .check_if_segment_has_enough_size
		jmp .loopback

		.check_if_segment_has_enough_size:
			cmp qword [r8], rbx
			jge .reuse_this_segment
			jmp .loopback

		.loopback:
			mov r9, r8 					; r9: add of prev segment for next segment
			mov r8, [r8+ NEXT_OFF] 				; r8 is now next segment address
			jmp .loop


	; r9 has has older segment starting address
	; r8 has the address of segment that is being reused
	.reuse_this_segment:

		.check_if_this_segment_can_be_split:

		;find size of free space
		mov rax, qword [r8]
		sub rax, rbx 				; space left after allocation

		mov rcx, metadata_size
		add rcx, min_free_space_size 	; min space required for new segment

		cmp rax, rcx
		jge .split_this_segment
		jmp .return_this_segment

		.split_this_segment:
	    inc qword [rel malloc_empty_segments]
	    inc qword [rel malloc_total_segments]


		;rax has total size of new segment
		sub rax, metadata_size					; rax: free space size of new seg

		mov rcx, r8
		add rcx, metadata_size
		add rcx, rbx 								; rcx is the adddress of new seg

		mov qword [rcx], rax
		mov qword [rcx + USED_OFF], 0 						; unoccupied segment
		mov [rcx+ PREV_OFF], r8  						; prev segment						
		; prev segment for this new segment  is the segment being split
		mov rdx, [r8+ NEXT_OFF]
		mov qword [rcx + NEXT_OFF], rdx 				; new seg points to old seg's next segment

		mov [r8+ NEXT_OFF], rcx 							; old segment points to new segment
		mov [r8], rbx 							; old segment size has been updated

		; now point the next segment's prev to this new segment
		mov rdx, [rcx+ NEXT_OFF] 				; next segment address
		cmp rdx, r12   					; cmp next segment address with brk
		je .mark_this_as_last_segment_and_ret  		; if this was last segment, return

		mov [rdx+ PREV_OFF], rcx 				; prev of next segment is this new segment created
		jmp .return_this_segment

		.mark_this_as_last_segment_and_ret:
			mov [rel malloc_address_last_segment], rcx   ; this segment is the last segment now
			jmp .return_this_segment

	.return_this_segment:
		mov qword [r8 + USED_OFF], 1 					; mark this as occupied
		mov rax, r8
		add rax, metadata_size 				; return to user address of free space

		dec qword [rel malloc_empty_segments]
	    inc qword [rel malloc_occupied_segments]

		jmp .return


	.check_if_last_segment_is_free:
		mov rax, [rel malloc_address_last_segment]
		cmp qword [rax + USED_OFF], 0
		jne .get_more_heap_space 	; if last segment not empty, just get more space

		jmp .get_more_heap_space_when_last_seg_included

		; i know the asked space is bigger than empty space of this last segment
		; in this case, when asking for new address i

	; r13 has older segment starting address before this is called
	.get_more_heap_space_when_last_seg_included:

		mov r12, [rel malloc_address_last_segment]
		mov rcx, rbx 				; rbx is original size requested
		sub rcx, [r12 + SIZE_OFF]  	; the size diff of original vs requested

		mov rax, 12
		mov rdi, r12						; address of last segment
		add rdi, metadata_size 				; add metadat size
		add rdi, rbx 						; the original size of segment
		add rdi, rcx 						; extra size needed
		syscall 							; rax has new brk position

		cmp rax, rdi
		jne .error_moving_brk_up_and_ret

		; Existing last segment is now the requested size.
	    mov [r12], rbx
	    mov qword [r12 + USED_OFF], 1
	    mov [r12 + NEXT_OFF], rax

	    dec qword [rel malloc_empty_segments]
	    inc qword [rel malloc_occupied_segments]

	    mov rax, r12
	    add rax, metadata_size
	    jmp .return


	; r13 has older segment starting address before this is called
	.get_more_heap_space:
	; move brk up, try to get more heap space
	mov rax, 12
	mov rdi, r12 						; address of old brk
	add rdi, metadata_size 				; add metadat size
	add rdi, rbx 						; add size requested
	syscall 							; rax has new brk position

	cmp rax, rdi
	jne .error_moving_brk_up_and_ret

	inc qword [rel malloc_total_segments]
	inc qword [rel malloc_occupied_segments]

	.fill_metadata:

	mov qword [r12], rbx 			; 1st 8 bytes: size of free space in this segment
	mov qword [r12 + USED_OFF], 1 			; 0 -> free, 1 -> occupied
	mov qword [r12 + PREV_OFF], r13 		; add_prev_segment
	mov qword [r12 + NEXT_OFF], rax 		; add_next_segment = new brk address

	mov [rel malloc_address_last_segment], r12   ; this segment is the last segment now

	jmp .return_old_brk_address

	.return_old_brk_address:
		mov rax, r12 						; r12 address of old brk
		add rax, metadata_size 				; + metadata to get address of usable space
		jmp .return

	.error_moving_brk_up_and_ret:
		jmp .return 						; error no still in rax 

	.error_getting_old_brk_address_and_ret:
		jmp .return 							; error no still in rax 

	.return:
		pop r13
		pop r12
		pop rbx
		ret



; TODO: maybe when last segment is freed, unmap them?
; rdi : address received from malloc
_free:

	push rbx

	sub rdi, metadata_size
	mov rbx, rdi 								;store the address of og segment
	    

	.mark_this_segment_as_free:
		mov qword [rbx+ USED_OFF], 0 					; mark this segment as free
		dec qword [rel malloc_occupied_segments]
		inc qword [rel malloc_empty_segments]


	call .check_and_update_if_next_segment_is_free
	call .check_if_prev_segment_is_free

	pop rbx
	ret

	.check_and_update_if_next_segment_is_free:
		cmp rbx, [rel malloc_address_last_segment]  	; if og segment was last segment
		je .occupied


		mov rax, [rbx + NEXT_OFF] 				 ; address of next segment


		cmp qword [rax+ USED_OFF], 1 				; check if new  segment is occupied or not
		je .occupied

		; merge current segment with next
		mov rcx, [rax] 					; free space of next segment in rcx
		add rcx, metadata_size 			; total size of next segment in rcx
		add [rbx], rcx 					; the og segment size been increased

		mov rdi, [rax+ NEXT_OFF]
		mov [rbx+ NEXT_OFF], rdi 				; og->next = curr->next

		; check if segment consumed was the last segment 
		cmp rax, [rel malloc_address_last_segment]
		je .update_last_segment_address_and_return

		; if this segment was not last

		mov rax, [rax+ NEXT_OFF] 				; address of og->next->next
		mov [rax+ PREV_OFF], rbx 				; og->next->next->prev = og

		jmp .not_occupied

		.update_last_segment_address_and_return:
			mov [rel malloc_address_last_segment], rbx 	; the og segment is the last segment
			jmp .not_occupied

		.not_occupied:
			dec qword [rel malloc_total_segments]
			dec qword [rel malloc_empty_segments]
			ret

		.occupied:
			ret

	.check_if_prev_segment_is_free:

		cmp qword [rbx + PREV_OFF], 0 					; og->prev is 0? meaning 1st segment?
		je .occupied2

		mov rax, [rbx + PREV_OFF] 				 ; og->prev

		cmp qword [rax+ USED_OFF], 1 				; check if new  segment is occupied or not
		je .occupied2

		; merge current segment with previous
		mov rcx, [rbx] 					; free space of og
		add rcx, metadata_size 			; total size of next segment in rcx
		add [rax], rcx 					; siz of prev += size of og

		mov rdi, [rbx+ NEXT_OFF]
		mov [rax+ NEXT_OFF], rdi 				; prev->next = og->next

		; check if og was last segment
		cmp rbx, [rel malloc_address_last_segment]
		je .update_prev_segment_address_and_return

		; if og segment was not last segment

		mov rcx, [rbx+ NEXT_OFF] 				; address of og->next
		mov [rcx+ PREV_OFF], rax 				; og->next->prev = prev

		jmp .not_occupied2

		.update_prev_segment_address_and_return:
			mov [rel malloc_address_last_segment], rax 	; the og segment is the last segment
			jmp .not_occupied2

		.not_occupied2:
			dec qword [rel malloc_total_segments]
			dec qword [rel malloc_empty_segments]
			ret

		.occupied2:
			ret



_print_malloc_segments_info:
	
	mov rax, malloc_info_len
	mov rdi, 1
	lea rsi, [rel malloc_info]
	call print_with_new_line

	mov rax, info_total_seg_len
	mov rdi, 1
	lea rsi, [rel info_total_seg]
	call print
	mov rax, [rel malloc_total_segments]
	lea rdi, [rel number_buffer]
	call itoa
	mov rdi, 1
	lea rsi, [rel number_buffer]
	call print_with_new_line

	mov rax, info_filled_seg_len
	mov rdi, 1
	lea rsi, [rel info_filled_seg]
	call print
	mov rax, [rel malloc_occupied_segments]
	lea rdi, [rel number_buffer]
	call itoa
	mov rdi, 1
	lea rsi, [rel number_buffer]
	call print_with_new_line

	mov rax, info_empty_seg_len
	mov rdi, 1
	lea rsi, [rel info_empty_seg]
	call print
	mov rax, [rel malloc_empty_segments]
	lea rdi, [rel number_buffer]
	call itoa
	mov rdi, 1
	lea rsi, [rel number_buffer]
	call print_with_new_line

	ret



; rax : the number
; rdi : address of buffer in which output is stored
; return address of buffer in rcx
; length of number in rax
itoa:
	test rax, rax
	jz .zero_lenght
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

	.zero_lenght:
		mov rcx, rdi
		mov byte [rdi], '0'
		inc rdi
		mov byte [rdi], 0
		mov rax, 1
		ret


; rax: number of bytes to print 
; rdi: fd to write to
; rsi: address of string 
; returns bytes printed rax
print_with_new_line:

	mov rdx, rax					; rdx total bytes
	mov rax, 1 						; write syscall
	syscall

	; print new line
	mov rax, 1
	mov rdi, 1 						; fd
	lea rsi, [rel newline] 			; buffer address
	mov rdx, 1 						; bytes to print
	syscall

	ret

; rax: number of bytes to print 
; rdi: fd to write to
; rsi: address of string 
; returns bytes printed rax
print:

	mov rdx, rax					; rdx total bytes
	mov rax, 1 						; write syscall
	syscall
	ret
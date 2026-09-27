section .data

	malloc_address_first_segment dq 0
	malloc_address_last_segment dq 0
	malloc_total_segments dq 0
	malloc_empty_segments dq 0
	malloc_occupied_segments dq 0
	malloc_called dq 0
	free_called dq 0



section .rodata
		
	malloc_info db "myMalloc info: ", 0
	malloc_info_len equ $ - malloc_info

	info_total_seg db "Total segments: ", 0
	info_total_seg_len equ $ - info_total_seg
	info_filled_seg db "Total Occupied segments: ", 0
	info_filled_seg_len equ $ - info_filled_seg
	info_empty_seg db "Total Free segments: ", 0
	info_empty_seg_len equ $ - info_empty_seg
	times_malloc_called db "Times malloc called: ", 0
	times_malloc_called_len equ $ - times_malloc_called
	times_free_called db "Times free called: ", 0
	times_free_called_len equ $ - times_free_called
	dash db "-", 0


	malloc_more_info db "myMalloc More info: ", 0
	malloc_more_info_len equ $ - malloc_more_info

	malloc_detailed_info db "myMalloc Detailed info: ", 0
	malloc_detailed_info_len equ $ - malloc_detailed_info
	new_line db 10
	vertial_seperator_line db "------------------------------------------------------------", 0
	vertial_seperator_line_len equ $ - vertial_seperator_line
	horizontal_seperator db " | ", 0
	horizontal_seperator_len equ $ - horizontal_seperator
	word_size db " Allocated Size: ", 0
	word_size_len equ $  - word_size
	word_bytes db " bytes", 0
	word_bytes_len equ $ - word_bytes
	word_status db "Status: ", 0
	word_status_len equ $ - word_status
	word_free db "Free", 0
	word_free_len equ $ - word_free
	word_occupied db "Occupied", 0
	word_occupied_len equ $ - word_occupied

section .bss

	malloc_info_buffer resb 256 		; detailed info line
	number_buffer resb 32


section .text


global _malloc
global _free
global _print_malloc_segments_info
global _print_more_malloc_info
global _print_detailed_malloc

; [free_size_of_this_segments] -> 8bytes
; [occupied|free]			   -> 8bytes
; [prev segment address] 	   -> 8bytes
; [next segment address] 	   -> 8bytes
; [actual_data_for_segment] 
; TOTAL size of segemnt: Requested size + 32bytes 


metadata_size equ 32
min_free_space_size equ 16

; remember to update these in mymalloc.inc if changed
MYMALLOC_SIZE_OFF 		equ 0
MYMALLOC_USED_OFF 		equ 8
MYMALLOC_PREV_OFF 		equ 16
MYMALLOC_NEXT_OFF 		equ 24

; brk in ASSEMBLY, can return the old brk after asking for new brk on failure
; thats why rax might not contain a -ve number but the old brk
; to check this: if new value of brk asked != value returned => error

; rdi : size of memory is bytes
; returns : address of memory where the asked bytes are free to use in rax
; 		  : -ve number on error
_malloc:
	inc qword [rel malloc_called]
	push rbx
	push r12
	push r13

	mov rbx, rdi 						;store requested size in callee-saved reg rbx

	cmp qword [rel malloc_total_segments], 0
	je .get_new_brk
	jmp .use_old_brk

	.get_new_brk:
	; get the current break address
	mov rax, 12 								;syscall sys_brk
	xor rdi, rdi 								; 0 to find current brk address
	syscall 									; rax has curr brk address

	test rax, rax
	jl .error_getting_old_brk_address_and_ret
	mov r12, rax 
	jmp .continue						; save old brk address r12

	.use_old_brk:
	mov r12, [rel malloc_address_last_segment]
	mov r12, [r12 + MYMALLOC_NEXT_OFF]

	.continue:
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
		cmp qword [r8+ MYMALLOC_USED_OFF], 0
		je .check_if_segment_has_enough_size
		jmp .loopback

		.check_if_segment_has_enough_size:
			cmp qword [r8], rbx
			jge .reuse_this_segment
			jmp .loopback

		.loopback:
			mov r9, r8 					; r9: add of prev segment for next segment
			mov r8, [r8+ MYMALLOC_NEXT_OFF] 				; r8 is now next segment address
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
		mov qword [rcx + MYMALLOC_USED_OFF], 0 						; unoccupied segment
		mov [rcx+ MYMALLOC_PREV_OFF], r8  						; prev segment						
		; prev segment for this new segment  is the segment being split
		mov rdx, [r8 + MYMALLOC_NEXT_OFF]
		mov qword [rcx + MYMALLOC_NEXT_OFF], rdx 				; new seg points to old seg's next segment

		mov [r8+ MYMALLOC_NEXT_OFF], rcx 							; old segment points to new segment
		mov [r8], rbx 							; old segment size has been updated

		; now point the next segment's prev to this new segment
		mov rdx, [rcx + MYMALLOC_NEXT_OFF] 				; next segment address
		cmp rdx, r12   					; cmp next segment address with brk
		je .mark_this_as_last_segment_and_ret  		; if this was last segment, return

		mov [rdx + MYMALLOC_PREV_OFF], rcx 				; prev of next segment is this new segment created
		jmp .return_this_segment

		.mark_this_as_last_segment_and_ret:
			mov [rel malloc_address_last_segment], rcx   ; this segment is the last segment now
			jmp .return_this_segment

	.return_this_segment:
		mov qword [r8 + MYMALLOC_USED_OFF], 1 					; mark this as occupied
		mov rax, r8
		add rax, metadata_size 				; return to user address of free space

		dec qword [rel malloc_empty_segments]
	    inc qword [rel malloc_occupied_segments]

		jmp .return


	.check_if_last_segment_is_free:
		mov rax, [rel malloc_address_last_segment]
		cmp qword [rax + MYMALLOC_USED_OFF], 0
		jne .get_more_heap_space 	; if last segment not empty, just get more space

		jmp .get_more_heap_space_when_last_seg_included

		; i know the asked space is bigger than empty space of this last segment
		; in this case, when asking for new address i

	; r13 has older segment starting address before this is called
	.get_more_heap_space_when_last_seg_included:

		mov r12, [rel malloc_address_last_segment]

		mov rax, 12
		mov rdi, r12						; address of last segment
		add rdi, metadata_size 				; add metadat size
		add rdi, rbx 						; the final size requested
		syscall 							; rax has new brk position

		cmp rax, rdi
		jne .error_moving_brk_up_and_ret

		; Existing last segment is now the requested size.
	    mov [r12], rbx
	    mov qword [r12 + MYMALLOC_USED_OFF], 1
	    mov [r12 + MYMALLOC_NEXT_OFF], rax

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
	mov qword [r12 + MYMALLOC_USED_OFF], 1 			; 0 -> free, 1 -> occupied
	mov qword [r12 + MYMALLOC_PREV_OFF], r13 		; add_prev_segment
	mov qword [r12 + MYMALLOC_NEXT_OFF], rax 		; add_next_segment = new brk address

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
	inc qword [rel free_called]
	push rbx

	sub rdi, metadata_size
	mov rbx, rdi 								;store the address of og segment
	    

	.mark_this_segment_as_free:
		mov qword [rbx + MYMALLOC_USED_OFF], 0 					; mark this segment as free
		dec qword [rel malloc_occupied_segments]
		inc qword [rel malloc_empty_segments]


	call .check_and_update_if_next_segment_is_free
	call .check_if_prev_segment_is_free

	pop rbx
	ret

	.check_and_update_if_next_segment_is_free:
		cmp rbx, [rel malloc_address_last_segment]  	; if og segment was last segment
		je .occupied

		mov rax, [rbx + MYMALLOC_NEXT_OFF] 				 ; address of next segment

		cmp qword [rax + MYMALLOC_USED_OFF], 1 				; check if new  segment is occupied or not
		je .occupied

		; merge current segment with next
		mov rcx, [rax] 					; free space of next segment in rcx
		add rcx, metadata_size 			; total size of next segment in rcx
		add [rbx], rcx 					; the og segment size been increased

		mov rdi, [rax+ MYMALLOC_NEXT_OFF]
		mov [rbx+ MYMALLOC_NEXT_OFF], rdi 				; og->next = curr->next

		; check if segment consumed was the last segment 
		cmp rax, [rel malloc_address_last_segment]
		je .update_last_segment_address_and_return

		; if this segment was not last

		mov rax, [rax+ MYMALLOC_NEXT_OFF] 				; address of og->next->next
		mov [rax+ MYMALLOC_PREV_OFF], rbx 				; og->next->next->prev = og

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

		cmp qword [rbx + MYMALLOC_PREV_OFF], 0 					; og->prev is 0? meaning 1st segment?
		je .occupied2

		mov rax, [rbx + MYMALLOC_PREV_OFF] 				 ; og->prev

		cmp qword [rax+ MYMALLOC_USED_OFF], 1 				; check if new  segment is occupied or not
		je .occupied2

		; merge current segment with previous
		mov rcx, [rbx] 					; free space of og
		add rcx, metadata_size 			; total size of next segment in rcx
		add [rax], rcx 					; siz of prev += size of og

		mov rdi, [rbx+ MYMALLOC_NEXT_OFF]
		mov [rax+ MYMALLOC_NEXT_OFF], rdi 				; prev->next = og->next

		; check if og was last segment
		cmp rbx, [rel malloc_address_last_segment]
		je .update_prev_segment_address_and_return

		; if og segment was not last segment

		mov rcx, [rbx+ MYMALLOC_NEXT_OFF] 				; address of og->next
		mov [rcx+ MYMALLOC_PREV_OFF], rax 				; og->next->prev = prev

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

	mov rax, times_malloc_called_len
	mov rdi, 1
	lea rsi, [rel times_malloc_called]
	call print
	mov rax, [rel malloc_called]
	lea rdi, [rel number_buffer]
	call itoa
	mov rdi, 1
	lea rsi, [rel number_buffer]
	call print_with_new_line

	mov rax, times_free_called_len
	mov rdi, 1
	lea rsi, [rel times_free_called]
	call print
	mov rax, [rel free_called]
	lea rdi, [rel number_buffer]
	call itoa
	mov rdi, 1
	lea rsi, [rel number_buffer]
	call print_with_new_line

	ret



_print_more_malloc_info:
	push r12
	push r13
	push r14
	push r15

	mov rax, malloc_more_info_len
	mov rdi, 1
	lea rsi, [rel malloc_more_info]
	call print_with_new_line


	mov r12, [rel malloc_address_first_segment]
	xor r13, r13 			; flag to check if last segment was reached
	mov r14, 1 				; which segment is begin processed

	xor r15, r15 			; state: weather collecting data on occupied/free segmnet
	; r15 = 0, free segment state, 1 -> occupied segment sate
	mov r15, [rel malloc_address_first_segment]
	mov r15, [r15 + MYMALLOC_USED_OFF] 		; 1 when occupied, 0 when free

	.loop_and_print_till_last_segment:
		mov r9, r14  			; the starting number of segment for this type
		xor r8, r8 				; size of segment with same type
	.loop_till_segment_type_changes:	

		cmp r12, [rel malloc_address_last_segment]
		je .mark_last_segment_reached
		jmp .continue

		.mark_last_segment_reached:
			call .last_segment_reached

		.continue:
		cmp [r12 + MYMALLOC_USED_OFF], r15  ; type of segment with current type
		je .add_size_to_current_type
		jne .print_and_change_segment

		.add_size_to_current_type:
			add r8, [r12 + MYMALLOC_SIZE_OFF]
			inc r14

			test r13, r13      ; is this was last segment and same type
			jne .print_and_change_segment

			mov r12, [r12 + MYMALLOC_NEXT_OFF]
			jmp .loop_till_segment_type_changes


		jmp .loop_till_segment_type_changes

	.print_and_change_segment:

		; copy the vertical line
		lea rdi, [rel malloc_info_buffer]
		lea rsi, [rel vertial_seperator_line]
		mov rcx, vertial_seperator_line_len
		rep movsb

		; copy new_line
		lea rsi, [rel new_line]
		mov rcx, 1
		rep movsb

		push rdi 				; save the next position for insertion
		push r8    				; saving the collective size of same segments
		;convert segment number into ascii
		mov rax, r9
		lea rdi, [rel number_buffer]
		call itoa
		pop r8
		pop rdi
		
		; the first segment-number for same type
		lea rsi, [rel number_buffer]
		mov rcx, rax
		rep movsb


		; copy a dash between the 2 segments
		lea rsi, [rel dash]
		mov rcx, rax
		rep movsb

		push rdi 				; save the next position for insertion
		push r8
		;convert last segment number into ascii
		mov rax, r14
		dec rax
		lea rdi, [rel number_buffer]
		call itoa
		pop r8
		pop rdi
		
		; the last segment-number for same type
		lea rsi, [rel number_buffer]
		mov rcx, rax
		rep movsb

		; copy the word "Allocated Size: "
		lea rsi, [rel word_size]
		mov rcx, word_size_len
		rep movsb

		push rdi 				; save the next position for insertion
		;convert size into ascii
		mov rax, r8
		lea rdi, [rel number_buffer]
		call itoa
		pop rdi

		; copy the actual size
		lea rsi, [rel number_buffer]
		mov rcx, rax
		rep movsb

		lea rsi, [rel word_bytes]
		mov rcx, word_bytes_len
		rep movsb

		; the horizontal seperator
		lea rsi, [rel horizontal_seperator]
		mov rcx, horizontal_seperator_len
		rep movsb

		; the word "Type: "
		lea rsi, [rel word_status]
		mov rcx, word_status_len
		rep movsb

		; weather occuped or free
		mov rax, r15  		; if current type(r15) is 0, it's free
		test rax, rax
		jz .segment_is_free

		lea rsi, [rel word_occupied]
		mov rcx, word_occupied_len
		rep movsb
		jmp .add_new_line

		.segment_is_free:
		lea rsi, [rel word_free]
		mov rcx, word_free_len
		rep movsb

		.add_new_line:
		lea rsi, [rel new_line]
		mov rcx, 1
		rep movsb

		; calculate the length
		; len = address after final byte - address 1st byte

		push r8
		push r9

		mov rcx, rdi
		lea r8, [rel malloc_info_buffer]
		sub rcx, r8

		mov rax, rcx
		mov rdi, 1
		lea rsi, [rel malloc_info_buffer]
		call print

		pop r9
		pop r8


	.loopback:
		test r13, r13
		jne .check_if_last_segment_was_same_as_curr_segment

		; change segment type 
		mov r15, [r12 + MYMALLOC_USED_OFF]
		jmp .loop_and_print_till_last_segment

	.check_if_last_segment_was_same_as_curr_segment:
		; if r12 is last segment, that means current segment was included
		cmp [r12 + MYMALLOC_USED_OFF], r15
		je .print_final_vertical_line    ; bec it was included in it

		; change segment type 
		mov r15, [r12 + MYMALLOC_USED_OFF]
		jmp .loop_and_print_till_last_segment

	.last_segment_reached:
		mov r13, 1
		ret

	.print_final_vertical_line:
		mov rax, vertial_seperator_line_len
		mov rdi, 1
		lea rsi, [rel vertial_seperator_line]
		call print_with_new_line


	.return:
		pop r15
		pop r14
		pop r13
		pop r12
		ret



_print_detailed_malloc:
	push r12
	push r13
	push r14

	mov rax, malloc_detailed_info_len
	mov rdi, 1
	lea rsi, [rel malloc_detailed_info]
	call print_with_new_line


	mov r12, [rel malloc_address_first_segment]
	xor r13, r13 					; flag to check if last segment was reached
	mov r14, 1 						; number of segments 
	.loop_and_print_till_last_segment:
		cmp r12, [rel malloc_address_last_segment]
		je .last_segment_reached

		.print_segment:


		; copy the vertical line
		lea rdi, [rel malloc_info_buffer]
		lea rsi, [rel vertial_seperator_line]
		mov rcx, vertial_seperator_line_len
		rep movsb

		; copy new_line
		lea rsi, [rel new_line]
		mov rcx, 1
		rep movsb

		push rdi 				; save the next position for insertion
		;convert segment number into ascii
		mov rax, r14
		lea rdi, [rel number_buffer]
		call itoa
		pop rdi
		
		inc r14
		; copy the actual size
		lea rsi, [rel number_buffer]
		mov rcx, rax
		rep movsb

		; copy the word "Allocated Size: "
		lea rsi, [rel word_size]
		mov rcx, word_size_len
		rep movsb

		push rdi 				; save the next position for insertion
		;convert size into ascii
		mov rax, [r12 + MYMALLOC_SIZE_OFF]
		lea rdi, [rel number_buffer]
		call itoa
		pop rdi

		; copy the actual size
		lea rsi, [rel number_buffer]
		mov rcx, rax
		rep movsb

		lea rsi, [rel word_bytes]
		mov rcx, word_bytes_len
		rep movsb

		; the horizontal seperator
		lea rsi, [rel horizontal_seperator]
		mov rcx, horizontal_seperator_len
		rep movsb

		; the word "Type: "
		lea rsi, [rel word_status]
		mov rcx, word_status_len
		rep movsb

		; weather occuped or free
		mov rax, [r12 + MYMALLOC_USED_OFF]  	
		test rax, rax
		jz .free

		lea rsi, [rel word_occupied]
		mov rcx, word_occupied_len
		rep movsb
		jmp .add_new_line

		.free:
		lea rsi, [rel word_free]
		mov rcx, word_free_len
		rep movsb

		.add_new_line:
		lea rsi, [rel new_line]
		mov rcx, 1
		rep movsb

		; calculate the length
		; len = address after final byte - address 1st byte

		mov rcx, rdi
		lea r8, [rel malloc_info_buffer]
		sub rcx, r8

		mov rax, rcx
		mov rdi, 1
		lea rsi, [rel malloc_info_buffer]
		call print


		.loopback:
		test r13, r13
		jne .print_final_vertical_line

		; move segment to next
		mov r12, [r12 + MYMALLOC_NEXT_OFF]
		jmp .loop_and_print_till_last_segment


		.last_segment_reached:
		mov r13, 1
		jmp .print_segment

	.print_final_vertical_line:
		mov rax, vertial_seperator_line_len
		mov rdi, 1
		lea rsi, [rel vertial_seperator_line]
		call print_with_new_line


	.return:
		pop r14
		pop r13
		pop r12
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
	lea rsi, [rel new_line] 			; buffer address
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
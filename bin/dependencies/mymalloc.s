section .data

	malloc_address_first_segment dq 0
	malloc_address_last_segment dq 0

section .text


global _malloc
gloabl _free


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

		mov rax, 12
		mov rdi, r12						; address of last segment
		add rdi, metadata_size 				; add metadat size
		add rdi, rbx 						; total size needed
		syscall 							; rax has new brk position

		cmp rax, rdi
		jne .error_moving_brk_up_and_ret

		; Existing last segment is now the requested size.
	    mov [r12], rbx
	    mov qword [r12 + USED_OFF], 1
	    mov [r12 + NEXT_OFF], rax

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

		ret

		.update_last_segment_address_and_return:
			mov [rel malloc_address_last_segment], rbx 	; the og segment is the last segment
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

		ret

		.update_prev_segment_address_and_return:
			mov [rel malloc_address_last_segment], rax 	; the og segment is the last segment
			ret

		.occupied2:
			ret


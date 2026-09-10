


section .data

	error_getting_brk db "Error getting brk value : ", 0
	error_getting_brk_len equ $ - error_getting_brk

	address_first_segment dq 0
	address_last_segment dq 0

	error_no dq 0

section .bss
	buffer resb 1024

section .text

extern _print
extern _print_with_new_line
extern _print_error_with_new_line

global _start


; [free_size_of_this_segments] -> 8bytes
; [occupied|free]			   -> 8bytes
; [prev segment address] 	   -> 8bytes
; [next segment address] 	   -> 8bytes
; [actual_data_for_segment] 
; TOTAL size of segemnt: Requested size + 32bytes 


metadata_size equ 32
min_free_space_size equ 16


; rdi : size of memory is bytes
; returns : address of memory where the asked bytes are free to use in rax
; 		  : -ve number on error
_malloc:

	mov rbx, rdi 						;store requested size in callee-saved reg rbx

	; get the current break address
	mov rax, 12 								;syscall sys_brk
	xor rdi, rdi 								; 0 to find current brk address
	syscall 									; rax has curr brk address

	test rax, rax
	jl .error_getting_old_brk_address_and_ret

	mov r12, rax 						; save old brk address r12

	cmp qword [rel address_first_segment], 0
	je .assign_heap_start_address
	jmp .check_if_old_free_segment_available


	.assign_heap_start_address:
		mov [rel address_first_segment], r12
		mov [rel address_last_segment], r12
		mov r13, 0 				; prev segment address is 0 for first segment
		jmp .get_more_heap_space

	.check_if_old_free_segment_available:

	mov r8, [rel address_first_segment] 
	xor r9, r9 						; add of prev segment for 1st segment is 0

	.loop:
		cmp r8, r12 				; if all segment exhausted, get more space
		je .set_address_of_prev_seg_and_get_more_heap_space
		jmp .check_if_segment_is_free

		.set_address_of_prev_seg_and_get_more_heap_space:
			mov r13, r9 			; address of prev segment stored in r13
			jmp .get_more_heap_space


		.check_if_segment_is_free:
		cmp qword [r8+8], 0
		je .check_if_segment_has_enough_size
		jmp .loopback

		.check_if_segment_has_enough_size:
			cmp qword [r8], rbx
			jge .reuse_this_segment
			jmp .loopback

		.loopback:
			mov r9, r8 					; r9: add of prev segment for next segment
			mov r8, [r8+24] 				; r8 is now next segment address
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
		mov qword [rcx + 8], 0 						; unoccupied segment
		mov [rcx+16], r8  						; prev segment						
		; prev segment for this new segment  is the segment being split
		mov rdx, [r8+24]
		mov qword [rcx + 24], rdx 				; new seg points to old seg's next segment

		mov [r8+24], rcx 							; old segment points to new segment
		mov [r8], rbx 							; old segment size has been updated

		; now point the next segment's prev to this new segment
		mov rdx, [rcx+24] 				; next segment address
		cmp rdx, r12   					; cmp next segment address with brk
		je .mark_this_as_last_segment_and_ret  		; if this was last segment, return

		mov [rdx+16], rcx 				; prev of next segment is this new segment created
		jmp .return_this_segment

		.mark_this_as_last_segment_and_ret:
			mov [rel address_last_segment], rcx   ; this segment is the last segment now
			jmp .return_this_segment

	.return_this_segment:
		mov qword [r8 + 8], 1 					; mark this as occupied
		mov rax, r8
		add rax, metadata_size 				; return to user address of free space
		ret


	; TODO: if last segment is free, but doesn't have enugh space as requested,
	; 	  : dont get the entire asked size + metadata
	; 	  : instead get: asked size - free size of last segment


	; r13 has older segment starting address before this is called
	.get_more_heap_space:
	; move brk up, try to get more heap space
	mov rax, 12
	mov rdi, r12 						; address of old brk
	add rdi, metadata_size 				; add metadat size
	add rdi, rbx 						; add size requested
	syscall 							; rax has new brk position

	test rax, rax
	jl .error_moving_brk_up_and_ret


	; fill metadata

	mov qword [r12], rbx 			; 1st 8 bytes: size of free space in this segment
	mov qword [r12 + 8], 1 			; 0 -> free, 1 -> occupied
	mov qword [r12 + 16], r13 		; add_prev_segment
	mov qword [r12 + 24], rax 		; add_next_segment = new brk address

	mov [rel address_last_segment], r12   ; this segment is the last segment now

	jmp .return_old_brk_address

	.return_old_brk_address:
		mov rax, r12 						; r12 address of old brk
		add rax, metadata_size 				; + metadata to get address of usable space
		ret

	.error_moving_brk_up_and_ret:
		ret 						; error no still in rax 

	.error_getting_old_brk_address_and_ret:
		mov [rel error_no], rax
		call _error_getting_brk 		; TODO: remove this later when using as library
		ret 							; error no still in rax 




; rdi : address received from malloc
_free:

	push rbx

	sub rdi, metadata_size
	mov rbx, rdi 								;store the address of og segment


	.mark_this_segment_as_free:
		mov qword [rbx+8], 0 					; mark this segment as free

	call .check_and_update_if_next_segment_is_free
	call .check_if_prev_segment_is_free

	pop rbx
	ret

	.check_and_update_if_next_segment_is_free:
		cmp qword rbx, [rel address_last_segment]  	; if og segment was last segment
		je .occupied


		mov rax, [rbx + 24] 				 ; address of next segment


		cmp qword [rax+8], 1 				; check if new  segment is occupied or not
		je .occupied

		; merge current segment with next
		mov rcx, [rax] 					; free space of next segment in rcx
		add rcx, metadata_size 			; total size of next segment in rcx
		add [rbx], rcx 					; the og segment size been increased

		mov rdi, [rax+24]
		mov [rbx+24], rdi 				; og->next = curr->next

		; check if segment consumed was the last segment 
		cmp rax, [rel address_last_segment]
		je .update_last_segment_address_and_return

		; if this segment was not last

		mov rax, [rax+24] 				; address of og->next->next
		mov [rax+16], rbx 				; og->next->next->prev = og

		ret

		.update_last_segment_address_and_return:
			mov [rel address_last_segment], rbx 	; the og segment is the last segment
			ret

		.occupied:
			ret

	.check_if_prev_segment_is_free:

		cmp qword [rbx + 16], 0 					; og->prev is 0? meaning 1st segment?
		je .occupied2

		mov rax, [rbx + 16] 				 ; og->prev

		cmp qword [rax+8], 1 				; check if new  segment is occupied or not
		je .occupied2

		; merge current segment with previous
		mov rcx, [rbx] 					; free space of og
		add rcx, metadata_size 			; total size of next segment in rcx
		add [rax], rcx 					; siz of prev += size of og

		mov rdi, [rbx+24]
		mov [rax+24], rdi 				; prev->next = og->next

		; check if og was last segment
		cmp rbx, [rel address_last_segment]
		je .update_prev_segment_address_and_return

		; if og segment was not last segment

		mov rcx, [rbx+24] 				; address of og->next
		mov [rcx+16], rax 				; og->next->prev = prev

		ret

		.update_prev_segment_address_and_return:
			mov [rel address_last_segment], rax 	; the og segment is the last segment
			ret

		.occupied2:
			ret





_start:
	mov rbp, rsp



	.allocate1:
	mov rdi, 4096
	call _malloc


	.free1:

	mov rdi, rax
	call _free

	.allocate2:

	mov rdi, 2048
	call _malloc

	
	.allocate3:

	mov rdi, 1024
	call _malloc

	.free2:
	mov rdi, rax
	call _free

	mov rdi, 2016
	call _malloc


	
	jmp _exit


_error_getting_brk:
	mov rax, error_getting_brk_len
	mov rdi, 1
	lea rsi, [rel error_getting_brk]
	call _print

	mov rax, [rel error_no]
	call _print_error_with_new_line


_exit_with_status_code_1:
	mov rax, 60
	mov rdi, 1
	syscall
	
_exit:
	mov rax, 60
	mov rdi, 0
	syscall
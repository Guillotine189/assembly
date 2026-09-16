section .data
	history_arr_address dq 0
	filled_history_array_size dq 0
	starting_index dq 0
	ending_index dq 0

section .rodata
	semi_colon_space db ": ", 0

section .bss
	reusable_number_buffer_history resb 20

; constants
capacity_arr equ 100


; var
extern error_code
extern exit_status_code

; funcs
extern _malloc
extern _free
extern _strlen
extern _print
extern _print_with_new_line
extern _itoa

extern _exit_with_status_code

extern print_error_allocating_memory_for_history
extern print_error_getting_mem_for_cmd_in_history

section .text

global _print_history
global _get_and_set_mem_for_history_array
global _add_cmd_into_history
global _return_address_of_command_from_newest


_get_and_set_mem_for_history_array:
	mov rdi, capacity_arr*8
	call _malloc

	test rax, rax
	jl .set_error_allocating_capacity_arr_and_exit

	mov [rel history_arr_address], rax 					; assign address to var
	ret

	.set_error_allocating_capacity_arr_and_exit:
		mov [rel error_code], rax
		call print_error_allocating_memory_for_history
		mov [rel exit_status_code], 1
		jmp _exit_with_status_code



; rdi: address of command
_add_cmd_into_history:
	; get new space for command
	push rdi 								; original address saved into stack

	call _strlen 						; rax has len of command
	push rax 								; original len saved in stack
	; round up len to next 8byte multiple
	; no reason to do this, i just wanted to
	mov rdi, rax
	inc rdi 								; include the \0
	add rdi, 7
	and rdi, -8
	call _malloc
    
	test rax, rax
	jl .set_error_getting_mem_for_cmd_in_history

	
	; copy the command into the address malloc gave me
	mov rdi, rax 				; address of destination
	pop rcx 					; len of command
	inc rcx 					; i want to copy 0 byte as well in end
	pop rsi 					; address of src
	rep movsb

	mov rdi, rax
	call _add_address_into_array
	ret

	.set_error_getting_mem_for_cmd_in_history:
		pop rdi
		pop rdi
		mov [rel error_code], rax
		call print_error_getting_mem_for_cmd_in_history
		ret 			; dont exit, just return and dont save into history


	
; rdi: address you want me to add
_add_address_into_array:
	cmp qword [rel filled_history_array_size], capacity_arr
	jl .not_wrapped

.wrapped:
	
	.write_new_address:
	mov rax, [rel history_arr_address]
	mov rcx, [rel ending_index]
	mov rsi, [rax + rcx*8] 					; save old address to free later
	mov [rax + rcx*8], rdi 					; update old address to new

	mov rdi, rsi
	call _free 	

	.increment_starting_index:
	cmp [rel starting_index], capacity_arr - 1
	jge .set_starting_to_zero

	inc qword [rel starting_index]
	jmp .handle_ending_index

	.set_starting_to_zero:
	mov qword [rel starting_index], 0
	jmp .handle_ending_index


	.handle_ending_index:
	cmp [rel ending_index], capacity_arr - 1
	jge .set_ending_to_zero

	jmp .increment_ending

	.set_ending_to_zero:
	mov qword [rel ending_index], 0
	jmp .return

	.increment_ending:
	inc qword [rel ending_index]

	.return:
	ret
		
.not_wrapped:

	mov rax, [rel history_arr_address]
	mov rcx, [rel ending_index]
	mov [rax + rcx*8], rdi

	inc qword [rel filled_history_array_size]

	cmp [rel ending_index], capacity_arr - 1
	jge .set_ending_to_zero_ret

	inc qword [rel ending_index]
	jmp .return

	.set_ending_to_zero_ret:
	mov qword [rel ending_index], 0
	inc qword [rel starting_index]

	ret

; REMEMBER in warped, end pointer is the single pointer to use

; rdi: offset, like 1,2 -> last command, last_to_last, or older
; returns: rax : address of the command, else -1
_return_address_of_command_from_newest:
	test rdi, rdi
	jle .return_not_exists

	; check if the history is full or not

	cmp rdi, capacity_arr
	jg .return_not_exists

	cmp [rel filled_history_array_size], capacity_arr
	jge .handle_warped

	; non warped array
	mov rax, [rel history_arr_address]
	mov rcx, [rel ending_index]
	sub rcx, rdi 							; 3 - 0 = 3 -> return array + 3*8

	cmp rdi, [rel filled_history_array_size]
	jg .return_not_exists
	mov rax, [rax + rcx*8] 
	ret

	.handle_warped:

	mov rax, [rel history_arr_address]
	mov rcx, [rel ending_index]
	sub rcx, rdi 

	test rcx, rcx
	jl .sub_from_end

	; at [positive or zero value, the value is the index

	mov rax, [rax + rcx*8] 
	ret

	.sub_from_end: 		; when sub is negative, index is cap+(-ve)result

	mov rdx, capacity_arr
	add rdx, rcx
	mov rax, [rax + rdx*8]
	ret

	.return_not_exists:
		mov rax, -1
		ret


_print_history:

	; wrap mode: rn start is at address of 2nd command
	; normal: start at 1st command

	mov rax, [rel filled_history_array_size]
	cmp rax, capacity_arr
	je .print_warped

	; print non warped
	
	xor r8, r8
	mov r9, 1 						; command numebr
	.loop_non_warped:
		mov rax, [rel starting_index]
		add rax, r8

		cmp rax, [rel ending_index]
		je .return_

		push r8
		push r9
		push rax

		mov rax, r9
		lea rdi, [rel reusable_number_buffer_history]
		call _itoa 		; raxx: len, number into ascii in buffer

		mov rdi, 1
		lea rsi, [rel reusable_number_buffer_history]
		call _print

		mov rax, 2
		mov rdi, 1
		lea rsi, [rel semi_colon_space]
		call _print

		pop rax
		mov rcx, [rel history_arr_address]
		mov rax, [rcx + rax*8] 			; rax has the address of command
		push rax
		mov rdi, rax
		call _strlen

		mov rdi, 1
		pop rsi
		call _print_with_new_line

		pop r9
		pop r8

		inc r8
		inc r9
		jmp .loop_non_warped

	.return_:
		ret



	.print_warped:

	; the end pointer is pointing to oldest command

	mov r9, 1 								; command number
	xor r8, r8
	xor r10, r10 			; flag to check if end_idx reached itself again
	.loop_start_end_match:
		mov rax, [rel ending_index]
		add rax, r8

		cmp rax, capacity_arr 			; the start index is out of bound, nove it to zero
		je .move_index_to_zero

		cmp rax, [rel ending_index]
		je .check_if_first_time

		; now print command and increase start_index
		.print_the_command:
		push r8
		push r9
		push rax

		mov rax, r9
		lea rdi, [rel reusable_number_buffer_history]
		call _itoa 		; raxx: len, number into ascii in buffer

		mov rdi, 1
		lea rsi, [rel reusable_number_buffer_history]
		call _print

		mov rax, 2
		mov rdi, 1
		lea rsi, [rel semi_colon_space]
		call _print

		pop rax
		mov rcx, [rel history_arr_address]
		mov rax, [rcx + rax*8] 			; rax has the address of command
		push rax
		mov rdi, rax
		call _strlen

		mov rdi, 1
		pop rsi
		call _print_with_new_line

		pop r9
		pop r8

		.loop:
		inc r8
		inc r9
		jmp .loop_start_end_match

		.check_if_first_time:
			test r10, r10
			jnz .return
			mov r10, 1
			jmp .print_the_command

		; make r8 such that after adding it to rax, it will point to zero index
		.move_index_to_zero: 			
			mov rax, [rel ending_index]
			neg rax
			mov r8, rax
			jmp .loop_start_end_match

		.return:
		ret
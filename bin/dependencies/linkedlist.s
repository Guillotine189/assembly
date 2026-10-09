; requires linking of mymalloc.o
; requires linking of mystring.o

extern _malloc
extern _free
extern _copy_constructor_mystring
extern _move_constructor_mystring


; linked_list_object
; [total elements] 			+0 bytes
; [size of element] 		+8 bytes
; [address to head_node]  	+16 bytes
; [address of end_node]     +24 bytes

LINKED_LIST_OBJECT_SIZE 		equ 32
LINKED_LIST_TOTAL_ELE_OFF 		equ 0
LINKED_LIST_ELE_SIZE_OFF 		equ 8
LINKED_LIST_HEAD_NODE_ADD_OFF   equ 16
LINKED_LIST_END_NODE_ADD_OFF    equ 24

; node
; [address of next node]    +0 bytes
; [actual element] 			+ 8 bytes


NODE_NEXT_NODE_ADD_OFF 		equ 0
NODE_ELEMENT_ADD_OFF 		equ 8

section .text

; remember to update the [linkedlist.inc, hash_set.s] after any changes
global _default_constructor_lninked_list
global _default_destructor_lninked_list
global _add_to_linked_list

global _add_to_linked_list_mystring
global _move_to_linked_list_mystring


; rdi: address of non-constructed Linked list object
_default_constructor_lninked_list:
	push r12

	mov r12, rdi 					; r12: the address of non-constructed LL object
 
	mov rax, [r12 + LINKED_LIST_ELE_SIZE_OFF]  ; rax: the size of element
	test rax, rax
	jle .error_invalid_size_element

	mov qword [r12 + LINKED_LIST_TOTAL_ELE_OFF], 0
	mov qword [r12 + LINKED_LIST_HEAD_NODE_ADD_OFF], 0
	mov qword [r12 + LINKED_LIST_END_NODE_ADD_OFF], 0

	; .return:
	pop r12
	xor rax, rax
	ret

	.error_invalid_size_element:
		pop r12
		mov rax, -1
		ret

; rdi: address of the linked list object
_default_destructor_lninked_list:
	push r12
	push r13
	push r14

	mov r14, rdi

	mov r12, [r14 + LINKED_LIST_HEAD_NODE_ADD_OFF] 	; r12: head
	test r12, r12  		; if head is null, return
	je .finish

	.loop_till_null:

		mov r13, [r12 + NODE_NEXT_NODE_ADD_OFF]   ; r13: curr->next

		mov rdi, r12							; free current (r12)
		call _free

		test r13, r13  							; if next is null return
		je .finish
 
		mov r12, r13  							; else curr = next
		jmp .loop_till_null

	.finish:
	mov qword [r14 + LINKED_LIST_TOTAL_ELE_OFF], 0
	mov qword [r14 + LINKED_LIST_HEAD_NODE_ADD_OFF], 0
	mov qword [r14 + LINKED_LIST_END_NODE_ADD_OFF], 0

	.return:
	pop r14
	pop r13
	pop r12
	ret

; rdi: address of linked list object
; rsi: address of element
_add_to_linked_list:
	push r12
	push r13
	mov r12, rdi 				; r12: the address of ll object
	mov r13, rsi

	mov rax, [r12 + LINKED_LIST_HEAD_NODE_ADD_OFF]

	test rax, rax
	je .head_is_null

	; if head is not null, there is atleast 1 element

	mov rdi, [r12 + LINKED_LIST_ELE_SIZE_OFF]  ; rdi: size of elemnt
	add rdi, 8 									; rdi: size of node
	call _malloc

	test rax, rax 								; rax: address of new node
	jl .error_creating_node

	mov rcx, [r12 + LINKED_LIST_END_NODE_ADD_OFF]
	mov [rcx + NODE_NEXT_NODE_ADD_OFF], rax   ; old_last_node->next = new_node

	mov [r12 + LINKED_LIST_END_NODE_ADD_OFF], rax 	; update the last node address in LL

	mov qword [rax + NODE_NEXT_NODE_ADD_OFF], 0   ; new_node->next = NULL

	; copying the actual element inside linked list
	lea rdi, [rax + NODE_ELEMENT_ADD_OFF]
	mov rsi, r13

	mov rcx, [r12 + LINKED_LIST_ELE_SIZE_OFF]
	shr rcx, 3 				; total 8bytes that can be copied
	rep movsq

	mov rcx, [r12 + LINKED_LIST_ELE_SIZE_OFF]
	and rcx, 7  			; remaining <8 bytes to be copied
	rep movsb

	inc qword [r12 + LINKED_LIST_TOTAL_ELE_OFF]
	jmp .return_success


	.head_is_null:

	mov rdi, [r12 + LINKED_LIST_ELE_SIZE_OFF]  ; rdi: size of elemnt
	add rdi, 8 									; rdi: size of node
	call _malloc

	test rax, rax 								; rax: address of new node
	jl .error_creating_node

	mov [r12 + LINKED_LIST_HEAD_NODE_ADD_OFF], rax
	mov [r12 + LINKED_LIST_END_NODE_ADD_OFF], rax

	mov qword [rax + NODE_NEXT_NODE_ADD_OFF], 0

	; copying the actual element inside linked list
	lea rdi, [rax + NODE_ELEMENT_ADD_OFF]
	mov rsi, r13

	mov rcx, [r12 + LINKED_LIST_ELE_SIZE_OFF]
	shr rcx, 3 				; total 8bytes that can be copied
	rep movsq

	mov rcx, [r12 + LINKED_LIST_ELE_SIZE_OFF]
	and rcx, 7  			; remaining <8 bytes to be copied
	rep movsb

	inc qword [r12 + LINKED_LIST_TOTAL_ELE_OFF]
	jmp .return_success


	.return_success:
	pop r13
	pop r12
	xor rax, rax
	ret


	.error_creating_node:
		pop r13
		pop r12
		mov rax, -1
		ret


; rdi: address of linked list object
; rsi: address of mystring object
_add_to_linked_list_mystring:
	push r12
	push r13
	push r14

	mov r12, rdi 				; r12: the address of ll object
	mov r13, rsi  				; r13: address of string object

	mov rax, [r12 + LINKED_LIST_HEAD_NODE_ADD_OFF]

	test rax, rax
	je .head_is_null

	; if head is not null, there is atleast 1 element

	mov rdi, [r12 + LINKED_LIST_ELE_SIZE_OFF]  ; rdi: size of elemnt
	add rdi, 8 									; rdi: size of node
	call _malloc

	test rax, rax 								; rax: address of new node
	jl .error_creating_node

	mov r14, rax 			; r14: address of new node

	mov qword [r14 + NODE_NEXT_NODE_ADD_OFF], 0   ; new_node->next = null

	mov rdi, r14   		; the new string address
	mov rsi, r13        ; the old string address
	call _copy_constructor_mystring

	test rax, rax
	jl .error_copying_mystring

	mov rcx, [r12 + LINKED_LIST_END_NODE_ADD_OFF] 	; rcx: old tail
	mov [rcx + NODE_NEXT_NODE_ADD_OFF], r14   		; old_last_node->next = new_node
	mov [r12 + LINKED_LIST_END_NODE_ADD_OFF], r14 	; update the last node address in LL
	inc qword [r12 + LINKED_LIST_TOTAL_ELE_OFF]
	jmp .return_success


	.head_is_null:

	mov rdi, [r12 + LINKED_LIST_ELE_SIZE_OFF]  ; rdi: size of elemnt
	add rdi, 8 									; rdi: size of node
	call _malloc

	test rax, rax 								; rax: address of new node
	jl .error_creating_node

	mov r14, rax  									; r14: address of new node

	mov qword [r14 + NODE_NEXT_NODE_ADD_OFF], 0   ; new_node->next = null

	mov rdi, r14   		; the new string address, created by malloc
	mov rsi, r13        ; the old string address given by user
	call _copy_constructor_mystring

	test rax, rax
	jl .error_copying_mystring


	mov [r12 + LINKED_LIST_HEAD_NODE_ADD_OFF], r14
	mov [r12 + LINKED_LIST_END_NODE_ADD_OFF], r14

	inc qword [r12 + LINKED_LIST_TOTAL_ELE_OFF]
	jmp .return_success

	.return_success:
		pop r14
		pop r13
		pop r12
		xor rax, rax
		ret

	.error_copying_mystring:
		mov rdi, r14
		call _free

	.error_creating_node:
		pop r14
		pop r13
		pop r12
		mov rax, -1
		ret

; rdi: address of linked list object
; rsi: address of mystring object
_move_to_linked_list_mystring:
	push r12
	push r13
	push r14

	mov r12, rdi 				; r12: the address of ll object
	mov r13, rsi  				; r13: address of string object

	mov rax, [r12 + LINKED_LIST_HEAD_NODE_ADD_OFF]

	test rax, rax
	je .head_is_null

	; if head is not null, there is atleast 1 element

	mov rdi, [r12 + LINKED_LIST_ELE_SIZE_OFF]  ; rdi: size of elemnt
	add rdi, 8 									; rdi: size of node
	call _malloc

	test rax, rax 								; rax: address of new node
	jl .error_creating_node

	mov r14, rax 			; r14: address of new node

	mov qword [r14 + NODE_NEXT_NODE_ADD_OFF], 0   ; new_node->next = null

	mov rdi, r14   		; the new string address
	mov rsi, r13        ; the old string address
	call _move_constructor_mystring

	test rax, rax
	jl .error_creating_node

	mov rcx, [r12 + LINKED_LIST_END_NODE_ADD_OFF] 	; rcx: old tail
	mov [rcx + NODE_NEXT_NODE_ADD_OFF], r14   		; old_last_node->next = new_node
	mov [r12 + LINKED_LIST_END_NODE_ADD_OFF], r14 	; update the last node address in LL
	inc qword [r12 + LINKED_LIST_TOTAL_ELE_OFF]
	jmp .return_success


	.head_is_null:

	mov rdi, [r12 + LINKED_LIST_ELE_SIZE_OFF]  ; rdi: size of elemnt
	add rdi, 8 									; rdi: size of node
	call _malloc

	test rax, rax 								; rax: address of new node
	jl .error_creating_node

	mov r14, rax
	mov qword [r14 + NODE_NEXT_NODE_ADD_OFF], 0   ; new_node->next = null

	mov rdi, r14   		; the new string address, created by malloc
	mov rsi, r13        ; the old string address given by user
	call _move_constructor_mystring

	test rax, rax
	jl .error_creating_node


	mov [r12 + LINKED_LIST_HEAD_NODE_ADD_OFF], r14
	mov [r12 + LINKED_LIST_END_NODE_ADD_OFF], r14

	inc qword [r12 + LINKED_LIST_TOTAL_ELE_OFF]
	jmp .return_success

	.return_success:
		pop r14
		pop r13
		pop r12
		xor rax, rax
		ret


	.error_creating_node:
		pop r14
		pop r13
		pop r12
		mov rax, -1
		ret
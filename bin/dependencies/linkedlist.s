; requires linking of mymalloc.o
; requires linking of mystring.o

extern _malloc
extern _free
extern _copy_constructor_mystring
extern _move_constructor_mystring
extern _destructor_mystring

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


; remember to redefine them in mystring.inc if changed
MYSTRING_OBJECT_SIZE 		equ 24
MYSTRING_CAPACITY_OFF 		equ 0
MYSTRING_SIZE_OFF     		equ 8
MYSTRING_POINTER_OFF 		equ 16

; node
; [address of next node]    +0 bytes
; [actual element] 			+ 8 bytes


NODE_NEXT_NODE_ADD_OFF 		equ 0
NODE_ELEMENT_ADD_OFF 		equ 8

section .text

; remember to update the [linkedlist.inc, hash_set.s] after any changes
global _default_constructor_linked_list
global _default_destructor_linked_list
global _add_to_linked_list

global _add_to_linked_list_mystring
global _move_to_linked_list_mystring
global _find_mystring_obj_linked_list
global _find_string_linked_list
global _destructor_linked_list_mystring

; rdi: address of non-constructed Linked list object
_default_constructor_linked_list:
	test rdi, rdi
	je .error_invalid_address 

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

	.error_invalid_address:
		mov rax, -1
		ret
	.error_invalid_size_element:
		pop r12
		mov rax, -1
		ret

; rdi: address of the linked list object
_default_destructor_linked_list:
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

; rdi: address of the linked list object
_destructor_linked_list_mystring:
	push r12
	push r13
	push r14

	mov r14, rdi

	mov r12, [r14 + LINKED_LIST_HEAD_NODE_ADD_OFF] 	; r12: head

	test r12, r12  		; if head is null, return
	je .finish

	.loop_till_null:

		mov r13, [r12 + NODE_NEXT_NODE_ADD_OFF]   ; r13: curr->next

		lea rdi, [r12 + NODE_ELEMENT_ADD_OFF]
		call _destructor_mystring

		mov rdi, r12							; free current (r12)
		call _free

		test r13, r13  							; if next is null return
		je .finish
 
		mov r12, r13  							; else curr = next
		jmp .loop_till_null

	.finish:
	mov qword [r14 + LINKED_LIST_TOTAL_ELE_OFF], 0
	mov qword [r14 + LINKED_LIST_ELE_SIZE_OFF], 0
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

	lea rdi, [r14 + NODE_ELEMENT_ADD_OFF]
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

	lea rdi, [r14 + NODE_ELEMENT_ADD_OFF]
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
	mov r13, rsi  				; r13: address of mystring object

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

	lea rdi, [r14 + NODE_ELEMENT_ADD_OFF]
	mov rsi, r13        ; the old mystring address
	call _move_constructor_mystring

	test rax, rax
	jl .error_moving_mystring

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

	lea rdi, [r14 + NODE_ELEMENT_ADD_OFF]
	mov rsi, r13        ; the old string address given by user
	call _move_constructor_mystring

	test rax, rax
	jl .error_moving_mystring


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

	.error_moving_mystring:
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
; when linked list contains mystring object, use this specifically
_find_mystring_obj_linked_list:
	push r12
	push r13
	push r14

	test rdi, rdi
	je .return_failure    ; invalid address

	test rsi, rsi
	je .return_failure    ; invalid address

	mov r12, rdi 			; r12: the address of linked list object
	mov r13, rsi 			; r13: the address of mystring object

	mov r14, [r12 + LINKED_LIST_HEAD_NODE_ADD_OFF]

	.loop_linked_list:
		test r14, r14
		je .return_failure 			; if end of ll reached, no matches found

		mov rdi, [r14 + MYSTRING_SIZE_OFF]
		mov rsi, [r13 + MYSTRING_SIZE_OFF]
		cmp r14, r13
		jne .check_next_node

		lea rdi, [r14 + NODE_ELEMENT_ADD_OFF] 		; rdi: the string object
		mov rdi, [rdi + MYSTRING_POINTER_OFF]
		mov rsi, [r13 + MYSTRING_POINTER_OFF]
		call strcmp

		test rax, rax
		je .return_success

	.check_next_node:
		mov r14, [r14 + NODE_NEXT_NODE_ADD_OFF]   ; curr = curr->next
		jmp .loop_linked_list

	.return_failure:
		pop r14
		pop r13
		pop r12
		mov rax, -1
		ret

	.return_success:
		pop r14
		pop r13
		pop r12
		xor rax, rax
		ret

; rdi: address of linked list object
; rsi: address of string
; when linked list contains mystring object, use this specifically
_find_string_linked_list:
	push r12
	push r13
	push r14

	test rdi, rdi
	je .return_failure    ; invalid address

	test rsi, rsi
	je .return_failure    ; invalid address

	mov r12, rdi 			; r12: the address of linked list object
	mov r13, rsi 			; r13: the address of string

	mov r14, [r12 + LINKED_LIST_HEAD_NODE_ADD_OFF]

	.loop_linked_list:
		test r14, r14
		je .return_failure 			; if end of ll reached, no matches found

		lea rdi, [r14 + NODE_ELEMENT_ADD_OFF] 		; rdi: the string object
		mov rdi, [rdi + MYSTRING_POINTER_OFF]
		mov rsi, r13
		call strcmp

		test rax, rax
		je .return_success

		mov r14, [r14 + NODE_NEXT_NODE_ADD_OFF]   ; curr = curr->next
		jmp .loop_linked_list

	.return_failure:
		pop r14
		pop r13
		pop r12
		mov rax, -1
		ret

	.return_success:
		pop r14
		pop r13
		pop r12
		xor rax, rax
		ret



; rdi : address string 1
; rsi : address string 2
; returns in rax
; 		 : 0 if string 1 and 2 are equal
;		 : 1 if string 1 > string 2
;		 : -1 if string 1 < string 2
strcmp:
	push rbx
	xor r9, r9										; this will act as a address index

	.loop:
		mov bl, [rdi + r9]								; store value [1 byte]
		mov cl, [rsi + r9]		

		cmp bl, cl
		
		; case 1 : string 1 < srring 2
		jb .handle_string_one_smaller					; carry flasg = 1, jump below will work

		; case 2 : both are equal
		je .handle_equal

		; case 3 : string 1 > string 2
		ja .handle_string_one_bigger					; sign flag = 0, jump below will work

	.handle_string_one_smaller:
		pop rbx
		mov rax, -1
		ret

	.handle_equal:
		; check if they ended, both has 0
		test bl, bl
		je .return_equal						; if both had \0 -> ZF = 1

		inc r9
		jmp .loop								; else just jump to loop

	.handle_string_one_bigger:
		pop rbx
		mov rax, 1
		ret

	.return_equal:
		pop rbx
		mov rax, 0
		ret
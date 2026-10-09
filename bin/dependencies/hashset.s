; requires linking of mymalloc.o
; requires linking of mystring.o
; requires linking of linkedlist.o

section .text

extern _malloc
extern _free

extern _default_constructor_linked_list
extern _default_destructor_linked_list
extern _add_to_linked_list

extern _add_to_linked_list_mystring
extern _destructor_linked_list_mystring

; extern _move_to_linked_list_mystring

LINKED_LIST_OBJECT_SIZE 		equ 32
LINKED_LIST_TOTAL_ELE_OFF 		equ 0
LINKED_LIST_ELE_SIZE_OFF 		equ 8
LINKED_LIST_HEAD_NODE_ADD_OFF   equ 16
LINKED_LIST_END_NODE_ADD_OFF    equ 24


; hash_set_object
; [total_elements_inside]      		 +0 bytes
; [total_buckets] 					 +8 bytes	
; [load factor] 		   	   		 +16 bytes
; [element size] 					 +24 bytes
; [SLL bucket_table_head_address]    +32 bytes

; a bucket is just a Linked_list_object


HASH_SET_OBJECT_SIZE 				equ 40
HASH_SET_TOTAL_ELE_OFF 				equ 0
HASH_SET_TOTAL_BUCKETS_OFF  		equ 8
HASH_SET_LOAD_FACTOR_OFF 			equ 16
HASH_SET_ELE_SIZE_OFF	 			equ 24
HASH_SET_BUCKET_HEAD_ADD_OFF		equ 32

; rdi: the address of hash set object not constructed
_default_contructor_hash_set:
	push r12

	mov r12, rdi

	mov rax, [r12 + HASH_SET_TOTAL_BUCKETS_OFF]

	test rax, rax
	je .zero_capacity_asked
	jmp .construct

	.zero_capacity_asked:
		mov [r12 + HASH_SET_TOTAL_BUCKETS_OFF], 16   ; if no capacity given, ask for 16buckets

	.construct:
	mov rax, [r12 + HASH_SET_ELE_SIZE_OFF]
	test rax, rax
	je .invalid_element_size

	; [r12 + HASH_SET_TOTAL_BUCKETS_OFF] has the total buckets asked

	xor rdx, rdx
	mov rax, [r12 + HASH_SET_TOTAL_BUCKETS_OFF]
	mov rdi, LINKED_LIST_OBJECT_SIZE
	mul rdi

	test rdx, rdx
	jnz .error_overflow
	
	mov rdi, rax
	call _malloc

	test rax, rax
	jl .error_acquiring_memory   ; custom _malloc, return -ve number on error unlike normal malloc

	mov qword [r12 + HASH_SET_TOTAL_ELE_OFF], 0
	mov qword [r12 + HASH_SET_LOAD_FACTOR_OFF], 0
	mov [r12 + HASH_SET_BUCKET_HEAD_ADD_OFF], rax

	; the address for bucket_array is given, 
	; but the values inside the bucket should be zero/linked_list object
	; initialize the values to be zero

	xor rcx, rcx
	.loop_nullify_array:
		cmp rcx, [r12 + HASH_SET_TOTAL_BUCKETS_OFF]
		jae .return_success

		mov qword [rax + LINKED_LIST_TOTAL_ELE_OFF], 0
		mov rdx, [r12 + HASH_SET_ELE_SIZE_OFF]
	    mov qword [rax + LINKED_LIST_ELE_SIZE_OFF], rdx
	    mov qword [rax + LINKED_LIST_HEAD_NODE_ADD_OFF], 0
	    mov qword [rax + LINKED_LIST_END_NODE_ADD_OFF], 0

		add rax, LINKED_LIST_OBJECT_SIZE
		inc rcx
		jmp .loop_nullify_array

	.error_acquiring_memory:
	.invalid_element_size:
	.error_overflow:
		jmp .return_failure

	.return_success:
		pop r12
		xor rax, rax
		ret

	.return_failure:
		pop r12
		mov rax, -1
		ret

; rdi: address of the hashset address
_default_destructor_hash_set:
	push r12
	push r13
	push r14

	test rdi, rdi
	je .error_invalid_address

	mov r12, rdi 					; r12: the address of the hasset
	mov r13, [r12 + HASH_SET_BUCKET_HEAD_ADD_OFF]

	test r13, r13
    jz .done_destructing

	xor r14, r14
	.loop_destruct_all_ll:
		cmp r14, [r12 + HASH_SET_TOTAL_BUCKETS_OFF]
		jae .done_destructing

		mov rdi, r13
		call _default_destructor_linked_list

		add r13, LINKED_LIST_OBJECT_SIZE  ; because the next bucket is just another linked list away
		inc r14
		jmp .loop_destruct_all_ll

	.done_destructing:
		mov rdi, [r12 + HASH_SET_BUCKET_HEAD_ADD_OFF]

		test rdi, rdi
		je .already_null

		call _free

		.already_null:
		mov qword [r12 + HASH_SET_TOTAL_ELE_OFF], 0
		mov qword [r12 + HASH_SET_TOTAL_BUCKETS_OFF], 0
		mov qword [r12 + HASH_SET_LOAD_FACTOR_OFF], 0
		mov qword [r12 + HASH_SET_ELE_SIZE_OFF], 0
		mov qword [r12 + HASH_SET_BUCKET_HEAD_ADD_OFF], 0

		jmp .return_success

	.error_invalid_address:
		jmp .return_failure


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

; rdi : address of hash set object
_destructor_hash_set_mystring:
	push r12
	push r13
	push r14

	test rdi, rdi
	je .error_invalid_address

	mov r12, rdi 					; r12: the address of the hasset
	mov r13, [r12 + HASH_SET_BUCKET_HEAD_ADD_OFF]

	test r13, r13
    jz .done_destructing

	xor r14, r14
	.loop_destruct_all_ll:
		cmp r14, [r12 + HASH_SET_TOTAL_BUCKETS_OFF]
		jae .done_destructing

		mov rdi, r13
		call _destructor_linked_list_mystring

		add r13, LINKED_LIST_OBJECT_SIZE  ; because the next bucket is just another linked list away
		inc r14
		jmp .loop_destruct_all_ll

	.done_destructing:
		mov rdi, [r12 + HASH_SET_BUCKET_HEAD_ADD_OFF]

		test rdi, rdi
		je .already_null

		call _free

		.already_null:
		mov qword [r12 + HASH_SET_TOTAL_ELE_OFF], 0
		mov qword [r12 + HASH_SET_TOTAL_BUCKETS_OFF], 0
		mov qword [r12 + HASH_SET_LOAD_FACTOR_OFF], 0
		mov qword [r12 + HASH_SET_ELE_SIZE_OFF], 0
		mov qword [r12 + HASH_SET_BUCKET_HEAD_ADD_OFF], 0

		jmp .return_success

	.error_invalid_address:
		jmp .return_failure


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

; rdi = address of hash_set object
; rsi: the address of string object
; returns:
;   rax =  0  : element added
;   rax =  1  : element already exists
;   rax = -1  : error
; This hash set will own the string object/ deep copy of the string object
_add_to_hash_set_mystring_object:
	; get hash of the actual string
	; check if the string exists inside set
	; if it doesn't get new 
	ret
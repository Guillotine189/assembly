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
extern _find_mystring_linked_list
extern _destructor_linked_list_mystring

extern _move_to_linked_list_mystring

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

global _default_contructor_hashset
global _default_destructor_hashset
global _destructor_hashset_mystring
global _add_to_hashset_mystring
global _move_to_hashset_mystring

; rdi: the address of hash set object not constructed
_default_contructor_hashset:
	push r12
	push r13
	push r14

	mov r12, rdi

	mov rax, [r12 + HASH_SET_TOTAL_BUCKETS_OFF]

	test rax, rax
	je .zero_capacity_asked
	jmp .construct

	.zero_capacity_asked:
		mov qword [r12 + HASH_SET_TOTAL_BUCKETS_OFF], 16   ; if no capacity given, ask for 16buckets

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

	xor r13, r13
	mov r14, rax
	.loop_create_ll:
		cmp r13, [r12 + HASH_SET_TOTAL_BUCKETS_OFF]
		jae .return_success

		mov rdx, [r12 + HASH_SET_ELE_SIZE_OFF]
	    mov qword [r14 + LINKED_LIST_ELE_SIZE_OFF], rdx
	    mov rdi, r14
	    call _default_constructor_linked_list
	    ; TODO: handle error

		add r14, LINKED_LIST_OBJECT_SIZE
		inc r13
		jmp .loop_create_ll

	.error_acquiring_memory:
	.invalid_element_size:
	.error_overflow:
		jmp .return_failure

	.return_success:
		pop r14
		pop r13
		pop r12
		xor rax, rax
		ret

	.return_failure:
		pop r14
		pop r13
		pop r12
		mov rax, -1
		ret

; rdi: address of the hashset address
_default_destructor_hashset:
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
_destructor_hashset_mystring:
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



; rdi: address of string
; rsi: len of string
; returns
; 	rax: the hash of string
;----------------- THE HASH FUNCTION IS NOT WRITTEN BY ME -----------
hash_string:
    mov     rax, 0xCBF29CE484222325 ; FNV offset basis
    mov     rcx, 0                 ; i = 0

.loop:
    cmp     rcx, rsi               ; i >= len?
    jae     .done                  ; if yes, finish

    movzx   rdx, byte [rdi + rcx]  ; rdx = str[i]
    xor     rax, rdx               ; hash ^= str[i]
    mov     rdx, 0x100000001B3     ; FNV prime
    imul    rax, rdx               ; hash *= prime (64-bit)

    inc     rcx                    ; i++
    jmp     .loop

.done:
    ret


; rdi = address of hash_set object
; rsi: the address of string object
; returns:
;   rax =  0  : element added
;   rax =  1  : element already exists
;   rax = -1  : error
; This hash set will own the string object/ deep copy of the string object
_add_to_hashset_mystring:
	push r12
	push r13
	push r14

	test rdi, rdi
	je .return_failure    ; invalid address

	test rsi, rsi
	je .return_failure    ; invalid address


	mov r12, rdi 					; r12: address of hash set object
	mov r13, rsi 					; r13: address of string object that needs to be added

	; get hash of the actual string
	mov rdi, [r13 + MYSTRING_POINTER_OFF]
	call strlen 					; in rax: it will have the len of string

	mov rdi, [r13 + MYSTRING_POINTER_OFF]
	mov rsi, rax
	call hash_string 				; in rax: the hash of string

	; check if the string exists inside set

	; rax has the hash
	xor rdx, rdx
	mov rdi, [r12 + HASH_SET_TOTAL_BUCKETS_OFF]
	div rdi

	; rdx: hash % total_buckets in hash_set

	; i know each bucket just holds a linked_list_object
	mov rcx, [r12 + HASH_SET_BUCKET_HEAD_ADD_OFF] 

	mov rax, rdx
	imul rax, LINKED_LIST_OBJECT_SIZE
	; rax: the total offset for the bucket

	lea r14, [rcx + rax] 		; rax: address of the bucket/linked_list_object

	; check_if_element_inside_bucket

	; r14: has the address of bucket/linked_list_object
	mov rdi, r14
	mov rsi, r13
	call _find_mystring_linked_list

	test rax, rax 					; 0 if it is inside, -ve if not
	je .return_already_present
		
	; r14: has the address of the bucket where i am inserting the string
	mov rdi, r14
	mov rsi, r13
	call _add_to_linked_list_mystring

	test rax, rax
	jl .return_failure

	inc qword [r12 + HASH_SET_TOTAL_ELE_OFF]
	jmp .return_added	

	.return_failure:
		pop r14
		pop r13
		pop r12
		mov rax, -1
		ret

	.return_added:
		pop r14
		pop r13
		pop r12
		xor rax, rax
		ret

	.return_already_present:
		pop r14
		pop r13
		pop r12
		mov rax, 1
		ret


; rdi = address of hash_set object
; rsi: the address of string object
; returns:
;   rax =  0  : element added
;   rax =  1  : element already exists
;   rax = -1  : error
; This hash set will own the string object/ deep copy of the string object
_move_to_hashset_mystring:
	push r12
	push r13
	push r14

	test rdi, rdi
	je .return_failure    ; invalid address

	test rsi, rsi
	je .return_failure    ; invalid address


	mov r12, rdi 					; r12: address of hash set object
	mov r13, rsi 					; r13: address of string object that needs to be added

	; get hash of the actual string
	mov rdi, [r13 + MYSTRING_POINTER_OFF]
	call strlen 					; in rax: it will have the len of string

	mov rdi, [r13 + MYSTRING_POINTER_OFF]
	mov rsi, rax
	call hash_string 				; in rax: the hash of string

	; check if the string exists inside set

	; rax has the hash
	xor rdx, rdx
	mov rdi, [r12 + HASH_SET_TOTAL_BUCKETS_OFF]
	div rdi

	; rdx: hash % total_buckets in hash_set

	; i know each bucket just holds a linked_list_object
	mov rcx, [r12 + HASH_SET_BUCKET_HEAD_ADD_OFF] 

	mov rax, rdx
	imul rax, LINKED_LIST_OBJECT_SIZE
	; rax: the total offset for the bucket

	lea r14, [rcx + rax] 		; rax: address of the bucket/linked_list_object

	; check_if_element_inside_bucket

	; r14: has the address of bucket/linked_list_object
	mov rdi, r14
	mov rsi, r13
	call _find_mystring_linked_list

	test rax, rax 					; 0 if it is inside, -ve if not
	je .return_already_present
		
	; r14: has the address of the bucket where i am inserting the string
	mov rdi, r14
	mov rsi, r13
	call _move_to_linked_list_mystring

	test rax, rax
	jl .return_failure

	inc qword [r12 + HASH_SET_TOTAL_ELE_OFF]
	jmp .return_added	

	.return_failure:
		pop r14
		pop r13
		pop r12
		mov rax, -1
		ret

	.return_added:
		pop r14
		pop r13
		pop r12
		xor rax, rax
		ret

	.return_already_present:
		pop r14
		pop r13
		pop r12
		mov rax, 1
		ret

; rdi: the address of null terminated string
; returns: rax: the len of string
strlen:
	mov rax, rdi

.loop_find_null:
	cmp byte [rax], 0
	je .done

	inc rax
	jmp .loop_find_null

.done:
	sub rax, rdi
	ret
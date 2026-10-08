; requires mymalloc.s
; requires mystring.s
; requires linkedlist.s

section .text

extern _malloc
extern _free

extern _default_constructor_lninked_list
extern _default_destructor_lninked_list
extern _add_to_linked_list
extern _move_to_linked_list_mystring

LINKED_LIST_OBJECT_SIZE 		equ 32
LINKED_LIST_TOTAL_ELE_OFF 		equ 0
LINKED_LIST_ELE_SIZE_OFF 		equ 8



; LINKED_LIST_HEAD_NODE_ADD_OFF   equ 16
; LINKED_LIST_END_NODE_ADD_OFF    equ 24


; hash_set_object
; [total_elements_inside]      		 +0 bytes
; [total_buckets] 					 +8 bytes	
; [load factor] 		   	   		 +16 bytes
; [SLL bucket_table_head_address]    +24 bytes


HASH_SET_TOTAL_ELE_OFF 				equ 0
HASH_SET_TOTAL_BUCKETS_OFF  		equ 8
HASH_SET_LOAD_FACTOR_OFF 			equ 16
HASH_SET_BUCKET_HEAD_ADD_OFF		equ 24

; rdi: the address of hash set object not constructed
_default_contructor_hash_set:
	push r12

	mov r12, rdi

	mov rax, [r12 + HASH_SET_TOTAL_ELE_OFF]

	test rax, rax
	je .zero_capacity_asked

	mov [r12 + HASH_SET_TOTAL_BUCKETS_OFF], rax
	jmp .construct

	.zero_capacity_asked:
		mov [r12 + HASH_SET_TOTAL_BUCKETS_OFF], 16   ; if no capacity given, ask for 16buckets

	.construct:



	ret

_default_destructor_hash_set:
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
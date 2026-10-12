%include "../dependencies/hashset.inc"
%include "../dependencies/mystring.inc"
%include "../dependencies/mymalloc.inc"

section .data
	string1 db "Hello world1", 0
	string1_len equ $ - string1
	string2 db "Hello world2", 0
	string2_len equ $ - string2
	string3 db "Hello world3", 
	string3_len equ $ - string3

section .bss
	string_obj1 resb MYSTRING_OBJECT_SIZE
	string_obj2 resb MYSTRING_OBJECT_SIZE
	string_obj3 resb MYSTRING_OBJECT_SIZE

section .text

; remember to redefine them in mystring.inc if changed
MYSTRING_OBJECT_SIZE 		equ 24
MYSTRING_CAPACITY_OFF 		equ 0
MYSTRING_SIZE_OFF     		equ 8
MYSTRING_POINTER_OFF 		equ 16

extern _constructor_mystring
extern _append_string_mystring

HASH_SET_OBJECT_SIZE 				equ 40
HASH_SET_TOTAL_ELE_OFF 				equ 0
HASH_SET_TOTAL_BUCKETS_OFF  		equ 8
HASH_SET_LOAD_FACTOR_OFF 			equ 16
HASH_SET_ELE_SIZE_OFF	 			equ 24
HASH_SET_BUCKET_HEAD_ADD_OFF		equ 32

extern _default_contructor_hashset
extern _default_destructor_hashset
extern _destructor_hashset_mystring
extern _add_to_hashset_mystring
extern _move_to_hashset_mystring

global _start
_start:
	
	sub rsp, HASH_SET_OBJECT_SIZE
	mov qword [rsp + HASH_SET_ELE_SIZE_OFF], MYSTRING_OBJECT_SIZE
	mov qword [rsp + HASH_SET_TOTAL_BUCKETS_OFF], 1024
	mov rdi, rsp
	call _default_contructor_hashset
	call _print_malloc_segments_info
	call _print_free_list_info
	.bk1:

	; create 3 string object
	lea rdi, [rel string_obj1]
	mov qword [rdi + MYSTRING_CAPACITY_OFF], string1_len
	call _constructor_mystring

	lea rdi, [rel string_obj1]
	lea rsi, [rel string1]
	call _append_string_mystring


	lea rdi, [rel string_obj2]
	mov qword [rdi + MYSTRING_CAPACITY_OFF], string2_len
	call _constructor_mystring

	lea rdi, [rel string_obj2]
	lea rsi, [rel string2]
	call _append_string_mystring


	lea rdi, [rel string_obj3]
	mov qword [rdi + MYSTRING_CAPACITY_OFF], string3_len
	call _constructor_mystring

	lea rdi, [rel string_obj3]
	lea rsi, [rel string3]
	call _append_string_mystring

	.bk2:

	; add the 3 string object inside the hashset
	mov rdi, rsp
	lea rsi, [rel string_obj1]
	call _move_to_hashset_mystring

	mov rdi, rsp
	lea rsi, [rel string_obj2]
	call _move_to_hashset_mystring
	
	mov rdi, rsp
	lea rsi, [rel string_obj3]
	call _move_to_hashset_mystring
	
	.bk3:

	call _print_malloc_segments_info
	call _print_free_list_info

	mov rdi, rsp
	call _destructor_hashset_mystring

	call _print_malloc_segments_info
	call _print_free_list_info
_exit:
	mov rax, 60
	mov rdi, 0
	syscall
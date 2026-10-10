%ifndef _MY_HASHSET_INC
%define _MY_HASHSET_INC

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
extern _check_mystring_inside_hashset
extern _check_string_inside_hashset

%endif
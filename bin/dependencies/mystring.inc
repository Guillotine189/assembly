%ifndef _MYSTRING_INC
%define _MYSTRING_INC

extern _constructor_mystring
extern _move_constructor_mystring
extern _copy_constructor_mystring
extern _destructor_mystring
extern _append_string_mystring
extern _append_bytes_mystring
extern _mystring_clear
extern _mystring_truncate

MYSTRING_OBJECT_SIZE 		equ 24
MYSTRING_CAPACITY_OFF 		equ 0
MYSTRING_SIZE_OFF     		equ 8
MYSTRING_POINTER_OFF 		equ 16

%endif
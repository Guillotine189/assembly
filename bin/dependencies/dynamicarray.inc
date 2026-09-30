%ifndef _DYNAMIC_ARRAY_INC
%define _DYNAMIC_ARRAY_INC

extern _default_dynamic_array_constructor
extern _default_dynamic_array_destructor
extern _dynamic_array_add_element
extern _dynamic_array_remove_element
extern _dynamic_array_get_element_address
extern _dynamic_array_clear


DYNAMICARRAY_OBJECT_SIZE 		equ 32
DYNAMICARRAY_CAPACITY_OFF 		equ 0
DYNAMICARRAY_SIZE_OFF     		equ 8
DYNAMICARRAY_ELEMENT_SIZE_OFF 	equ 16
DYNAMICARRAY_POINTER_OFF 		equ 24

%endif
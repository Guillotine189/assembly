%include "../dependencies/mystring.inc"

section .text

global _default_dynamic_array_constructor
global _default_dynamic_array_destructor
global _dynamic_array_add_element

extern _malloc
extern _free

; dynamic_array object
; +0 bytes   -> capacity / can be given to constructor (eg: 10 elements)
; +8 bytes   -> size of array / 0 After constructor
; +16 bytes  -> size of 1 value, (ex: 8bytes for pointers)
; +24 bytes  -> pointer to free space/ Null before constructor
; Total object size : 32 bytes
; you can make constructors/destructors yourself 


; default constructor: looks at size of one value, and capacity of vecotor
; asks for size_of_1_val*capacity from malloc
; if capacity is not given, it allocates 1*size_of_1_value
; MAKE SURE SIZE_OF_1_VALUE is PRESENT



; remember to change them in 
DYNAMICARRAY_OBJECT_SIZE 		equ 32
DYNAMICARRAY_CAPACITY_OFF 		equ 0
DYNAMICARRAY_SIZE_OFF     		equ 8
DYNAMICARRAY_ELEMENT_SIZE_OFF 	equ 16
DYNAMICARRAY_POINTER_OFF 		equ 24



; TODO: recheck myconstructor

; rdi : address of non-constructed dynamic_array object 
; returns rax: 0 on success and -ve nuumber on error
_default_dynamic_array_constructor:
	mov rax, [rdi + DYNAMICARRAY_CAPACITY_OFF]
	mov rcx, [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF]

	test rax, rax   				 ; if capacity is -ve, return
	jl .error_allocating_memory

	test rcx, rcx   					; if size of 1 element is 0 or -ve return error
	jle .error_allocating_memory

	push rdi 							; save the address of the object in stack

	; check how much memory to allocate
	mul rcx 				; rax * rcx -> output is rdx:rax

	test rcx, rcx
	je .allocate_size_of_one_element

	.allocate_size_of_one_element:
		mov rcx, [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF]

	mov rdi, rcx
	call _malloc 			; rax has the pointer to the memory

	test rax, rax
	jl .error_allocating_memory

	pop rdi 				; resotre the address ob object

	mov [rdi + DYNAMICARRAY_POINTER_OFF], rax 		; store the pointer info
	mov qword [rdi + DYNAMICARRAY_SIZE_OFF], 0 		; total elements stored is zero


	xor rax, rax
	ret 

	.error_allocating_memory:
		mov rax, -1
		ret


; rdi : address of dynamic_array object 
; just frees the malloc object
_default_dynamic_array_destructor:
	
	mov rdi, [rdi + DYNAMICARRAY_POINTER_OFF]
	call _free
	ret



; rdi: address of dynamic_array object
; rsi: address of element
; returns: rax: 0 on success, -ve number on error
_dynamic_array_add_element:
	test rsi, rsi 					; check for element address
	jz .error_invalid_address

	test rdi, rdi 					; check for element address
	jz .error_invalid_address

	push rbp
	mov rbp, rsp
	push r12
	push r13
	push r14

	mov r12, rdi
	mov r13, rsi

	; check if i can even add this element
	mov rax, [r12 + DYNAMICARRAY_SIZE_OFF]
	mov rcx, [r12 + DYNAMICARRAY_CAPACITY_OFF]

	cmp rax, rcx
	je .get_more_dynamic_array_space

	.append_element:

	mov rax, [r12 + DYNAMICARRAY_ELEMENT_SIZE_OFF]      ; rax = element_size
	mov rcx, [r12 + DYNAMICARRAY_SIZE_OFF]              ; rcx = size_of_dynamic_array
	mul rcx                                ; rdx:rax = element_size * size_of_dynamic_array
	; rax is offset in the actual array where the data will go

	; if overflow into rdx, too big of memory asked, return error
	test rdx, rdx
	jnz .error_appending_object


	add rax, [r12 + DYNAMICARRAY_POINTER_OFF] ; rax now points to new location where the new element will go

	; copy the element from original to my dynamic_array
	; iknow that size of element is constant so copy only that many bytes

	mov rdi, rax
	mov rsi, r13
	mov rcx, [r12 + DYNAMICARRAY_ELEMENT_SIZE_OFF] ; rcx = size of 1 element
	
	mov rdx, rcx 				; save how much data to copy

	shr rcx, 3 					; len/8 quotient
	rep movsq 					; copy 8 bytes at a time

	mov rcx, rdx
	and rcx, 7 					; basically rdx%8
	rep movsb 					; copy remaining 1 byte at a time

	inc qword [r12 + DYNAMICARRAY_SIZE_OFF] 		; increment the size of array
	jmp .success_adding_element


	.get_more_dynamic_array_space:

		; new space = original space*2
		mov rax, [r12 + DYNAMICARRAY_CAPACITY_OFF]
		shl rax, 1 				; capacity*2  ex: 10*2 = 20 elements
		mov rcx, [r12 + DYNAMICARRAY_ELEMENT_SIZE_OFF]
		mul rcx
		; now rax has 20*size_of_1_element

		; because the output is rds: rax, if there is a value in rdx, there is overflow
		test rdx, rdx
		jnz .error_appending_object

		mov rdi, rax
		call _malloc

		test rax, rax
		jl .error_appending_object
		
		; rax has the new address
		; copy old data into  new data

		mov r14, rax 								; save the new location

		mov rdi, r14 							   ; location new new data
		mov rsi, [r12 + DYNAMICARRAY_POINTER_OFF]  ; location of old data
		mov rcx, [r12 + DYNAMICARRAY_SIZE_OFF] 				; size of array
		mov rax, [r12 + DYNAMICARRAY_ELEMENT_SIZE_OFF]      ; size of 1 element
		mul rcx 											; rax: size_arr * size_1_element
		mov rcx, rax  										; rcx =  rax

		mov rdx, rcx 				; save how much data to copy

		shr rcx, 3 					; len/8 quotient
		rep movsq 					; copy 8 bytes at a time

		mov rcx, rdx
		and rcx, 7 					; basically rdx%8
		rep movsb 					; copy remaining 1 byte at a time

		;update the capacity
		mov rax, [r12 + DYNAMICARRAY_CAPACITY_OFF]
		shl rax, 1
		mov [r12 + DYNAMICARRAY_CAPACITY_OFF], rax

		; free the old location
		mov rdi, [r12 + DYNAMICARRAY_POINTER_OFF]
		call _free

		; update the pointer
		mov [r12 + DYNAMICARRAY_POINTER_OFF], r14

		jmp .append_element

	.error_invalid_address:
		mov rax, -1
		ret

	.error_appending_object:
		pop r14
		pop r13
		pop r12
		mov rsp, rbp
		pop rbp

		mov rax, -2
		ret

	.success_adding_element:
		pop r14
		pop r13
		pop r12
		mov rsp, rbp
		pop rbp

		xor rax, rax
		ret




; rdi: address of dynamic_array object 
; rsi: the index of element (1st element at 0th index)
; returns: rax : the address of the element , -ve number on error
_dynamic_array_get_element_address:
	
	test rdi, rdi
    jz .error_invalid_address

    test rsi, rsi
    js .error_negative_index

	mov rax, [rdi + DYNAMICARRAY_SIZE_OFF]   		; eg size = 5 elemts
	
	cmp rsi, rax 					; asked for element at index 4, but size is 4 -> error
	jae .error_out_of_bounds

	mov rcx, [rdi + DYNAMICARRAY_POINTER_OFF]

	mov rax, [rdi + DYNAMICARRAY_ELEMENT_SIZE_OFF] 
	mul rsi
	;rax:  13th element * size of element = eg: 13*2 = 26bytes offset

	add rax, rcx
	; now i added the offset to the address of the actual malloc allocated array

	ret

	.error_invalid_address:
	.error_negative_index:
	.error_out_of_bounds:
		mov rax, -1
		ret
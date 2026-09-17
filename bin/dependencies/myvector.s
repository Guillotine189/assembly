section .text

global _default_myvector_constructor
global _default_myvector_destructor

extern _malloc
extern _free

; vector object
; +0 bytes   -> capacity / can be given to constructor
; +8 bytes   -> size / 0 After constructor
; +16 bytes  -> size of 1 value, (8bytes for pointers)
; +24 bytes  -> pointer to free space/ Null before constructor
; Total object size : 32 bytes
; you can make constructors/destructors yourself 


; default constructor: looks at size of one value, and capacity of vecotor
; asks for size_of_1_val*capacity from malloc
; if capacity is not given, it allocates 1*size_of_1_value
; MAKE SURE SIZE_OF_1_VALUE is PRESENT




CAPACITY_OFF 		equ 0
SIZE_OFF     		equ 8
SIZE_ELEMENT_OFF 	equ 16
POINTER_OFF 		equ 24



; TODO: recheck myconstructor

; rdi : address of costructed vector object 
; returns rax: 0 on success and -ve nuumber on error
_default_myvector_constructor:
	
	push rdi 							; save the address of the object in stack

	; chek how much memory to allocate
	mov rax, [rdi + CAPACITY_OFF]

	mov rbx, [rdi + SIZE_ELEMENT_OFF]

	mul rbx 				; rdx:rax * rbx -> output is rax

	mov rdi, rax
	call _malloc 			; rax has the pointer to the memory

	test rax, rax
	jl .error_allocating_memory

	pop rdi 				; resotre the address ob object

	mov [rdi + POINTER_OFF], rax 		; store the pointer info
	mov qword [rdi + SIZE_OFF], 0 		; total elements stored is zero


	xor rax, rax
	ret 

	.error_allocating_memory:
		ret


; rdi : address of vector object 
; just frees the malloc object
_default_myvector_destructor:
	
	mov rdi, [rdi + POINTER_OFF]
	call _free
	ret



; rdi: address of vector object
; rsi: address of element
; returns: rax: 0 on success, -ve number on error
_myvector_add_element:
	test rsi, rsi 					; check for element address
	jl .error_invalid_address

	test rdi, rdi 					; check for element address
	jl .error_invalid_address

	; check if i can even add this element
	mov rax, [rdi + SIZE_OFF]
	mov rcx, [rdi + CAPACITY_OFF]

	cmp rax, rcx
	jge .get_more_space
	jmp .append_element

	.get_more_space:
		call .get_more_vector_space

	.append_element:

	mov rax, [rdi + SIZE_ELEMENT_OFF]      ; rax = element_size
	mov rcx, [rdi + SIZE_OFF]              ; rcx = size_of_vector
	mul rcx                                ; rdx:rax = element_size * size_of_vector

	mov rcx, [rdi + POINTER_OFF] 				; rax has address of that array
	; address of new element = array address + size_of_1_element*size_of_array
	add rcx, rax 	; rcx now points to the memory location where the new element will go

	; copy the element from original to my vector
	; iknow that size of element is constant so copy only that many bytes

	mov r8, rdi 						; save vector object address

	mov rdi, rcx
	mov rcx, [r8 + SIZE_ELEMENT_OFF] ; rcx = size of 1 element, ie the data to copy

	; rsi : address of new element
	; rdi : address where the new elemnt will go
	; rcx = size of 1 element, ie the data to copy
	rep movsb 					; actually copies data
	ret



	; DO NOT DESTROY rsi and rdi
	.get_more_vector_space:

		; new space = original space*2
		mov rax, [rdi + CAPACITY_OFF]



		ret


	.error_invalid_address:
		mov rax, -1
		ret




; rdi: address of vector object 
; rsi: the index of element (1st element at 0th index)
; returns: rax : the address of the element , -ve number on error
_myvector_get_element_address:
	
	test rsi, rsi
	jl .error_negative_index

	mov rax, [rdi + CAPACITY_OFF]   		; eg cap = 5 elemts
	sub rax, rsi 							; asked for element at index 4, rax: 1

	test rax, rax 							
	jle .error_out_of_bounds

	mov rax, [rdi + POINTER_OFF]
	mov rax, [rax + rsi]
	ret


	.error_negative_index:
	.error_out_of_bounds:
		mov rax, -1
		ret
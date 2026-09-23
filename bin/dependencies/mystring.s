section .text

global _constructor_mystring
global _destructor_mystring

extern _malloc
extern _free

; string object
; +0 bytes   -> capacity / can be given to constructor, if <= 0 given: it will get default bytes
; +8 bytes   -> size / 0 After constructor
; +16 bytes  -> pointer to free space/ Null before constructor
; Total object size : 24 bytes


; logic: constructor: i asked for 32bytes, it will add 1, so 33bytes
; 					now 33 is rounded off to 40, and 40 bytes are asked.
; 					but capacity is stored as 39

; add to string: capacity: 39, size = 38
; 			need to add a string of len 24
; 			39 + 24 = 63
; 			63 + 64 = 127 (64bytes growth for future)
; 			127 -> 128 rounded off to next 8byte multiple
; 			new capacity = 127bytes. NOT 128. because 1 byte for null



global _constructor_mystring
global _destructor_mystring
global _append_string_mystring
global _mystring_clear

; remember to redefine them in mystring.inc if changed
MYSTRING_OBJECT_SIZE 		equ 24
MYSTRING_CAPACITY_OFF 		equ 0
MYSTRING_SIZE_OFF     		equ 8
MYSTRING_POINTER_OFF 		equ 16


; rdi : address of costructed string object 
; returns rax: 0 on success and -ve nuumber on error
_constructor_mystring:
	push r12
	push r13	

	mov r12, rdi 							; r12 address of string object

	; chek how much memory to allocate
	mov rdi, [r12 + MYSTRING_CAPACITY_OFF]

	test rdi, rdi
	jle .zero_cap_given

	jmp .allocate

	.zero_cap_given:
		mov rdi, 24

	.allocate:
	add rdi, 1  			; for null
	add rdi, 7
	and rdi, -8 			; make rdi multiple of 
	mov r13, rdi 			; save the new capacity in r13

	call _malloc 			; rax has the pointer to the memory

	test rax, rax
	jl .error_allocating_memory

	mov [r12 + MYSTRING_POINTER_OFF], rax 		; store the pointer info
	mov qword [r12 + MYSTRING_SIZE_OFF], 0 		; total elements stored is zero
	; i will not store the capacity of string, i will store capacity -1 so i can add \n after every insertion without problem
	dec r13
	mov [r12 + MYSTRING_CAPACITY_OFF], r13 		; maybe capacity was changed

	pop r13
	pop r12
	xor rax, rax
	ret 

	.error_allocating_memory:
		pop r13
		pop r12
		mov rax, -1
		ret

; rdi : address of string object 
; just frees the malloc object
_destructor_mystring:
	
	mov rdi, [rdi + MYSTRING_POINTER_OFF]
	call _free
	ret


; rdi : address of string object
; rsi: address of null terminated string
; returns: rax: 0 on success, -ve on error

; Does not copy the NULL terminator in the end
_append_string_mystring:
	push r12
	push r13
	push r14

	mov r12, rdi
	mov r14, rsi

	mov rdi, r14
	call strlen 				; rax: len of new string
	
	mov r13, rax

	mov r8, [r12 + MYSTRING_CAPACITY_OFF]
	mov r9, [r12 + MYSTRING_SIZE_OFF]
	add r9, r13


	cmp r8, r9 				; capacity  - (og_size + size_of_new_string)
	jl .get_more_space_string


	.append_string:

	mov rcx, [r12 + MYSTRING_POINTER_OFF]
	add rcx, [r12 + MYSTRING_SIZE_OFF] 				; rcx at address where the new string will go


	; r14 : address of new string
	mov rdi, rcx 						; rdi : destination address
	mov rsi, r14
	mov rcx, r13  						; rcx : len of new string
	rep movsb							; actuallly copy the new string into old

	mov byte [rdi], 0 					; add a null at end of byte

	add [r12 + MYSTRING_SIZE_OFF], r13 			; update the size

	jmp .return


	.get_more_space_string:

	; r13 has the len of new string
	mov r9, [r12 + MYSTRING_SIZE_OFF]
	add r9, r13                  ; required size
	add r9, 128                 ; growth
	add r9, 7
	and r9, -8                   ; align with next 8 byte multiple

	push r9 					; store new capacity in stack

	mov rdi, r9
	call _malloc  			; rax has address of new array
 	
	pop r9 						; r9 has new capacity

	test rax, rax
	jl .error_increasng_string_size

	; copy old string into new

	mov rdi, rax 					; rdi: address of destination
	mov rsi, [r12 + MYSTRING_POINTER_OFF] 	; rsi : address of  src
	mov rcx, [r12 + MYSTRING_SIZE_OFF] 		; rcx : size of old string
	rep movsb

	;update capacity

	dec r9
	mov [r12 + MYSTRING_CAPACITY_OFF], r9

	; save old pointer
	mov r8, [r12 + MYSTRING_POINTER_OFF]

	; update new pointer
	mov [r12 + MYSTRING_POINTER_OFF], rax 

	; free old memory
	mov rdi, r8
	call _free

	jmp .append_string


	.error_increasng_string_size:
	.error_appending_string:
		mov rax, -1

	.return:
		pop r14
		pop r13
		pop r12
		ret


; rdi: address of string object
_mystring_clear:
	mov qword [rdi + MYSTRING_SIZE_OFF], 0
	mov rdi, [rdi + MYSTRING_POINTER_OFF]
	mov byte [rdi], 0
	xor rax, rax
	ret


; rdi: address of string
; return stored in rax
; searches until \0 encountered, return len excluding \0
strlen:

	.intialize:
		xor rax, rax				; rax will store string length

	.loop:

		cmp byte [rdi + rax], 0 			; move byte inside rcx
		je .finish

		inc rax
		jmp .loop

	.finish:
		ret


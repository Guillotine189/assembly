extern printf
extern exit

section .data
	msg DB "HELLO WORLD!", 0		; 0 is null terminator for string
	fmt DB "Output is: %s", 10, 0		; 10 is new line char

section .text
global main

; printf(fmt, message) -> so in stack, first msg then fmt as stack wil pop fmt first
; which is what the function wants

main:
	
	lea rdi, [rel fmt]
	lea rsi, [rel msg]
	xor eax, eax
	call printf

	mov edi, 0
	CALL exit
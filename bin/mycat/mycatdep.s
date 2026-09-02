section .text

global _print

; rdi: address of string 
; rsi: number of bytes to print 
; prints to fd1
; return amount of data printed in rax
_print:
	mov rax, rsi

	mov rsi, rdi 					; buffer in rsi
	mov rdi, 1						; fd nuber
	mov rdx, rax					; total bytes to write
	mov rax, 1
	syscall							; returns printed data size in rax

	ret
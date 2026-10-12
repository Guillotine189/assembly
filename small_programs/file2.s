; This program reads a file and prints it to fd1 [terminal by default]


section .data
	path1 DB "/home/sarthak/Desktop/asm/data2.txt", 0

section .bss
	fd1 resq 1
	file_size_bytes resq 1

section .text

global _start

_start:

	; open file 1

	mov rax, 2						; syscall number to open a file, returns fd number in rax
	mov rdi, path1					; load the address of string not the actual string
	mov rsi, 0 						; 0 -> read only
	syscall							; output is a fd (like 3 stored in rax)
	
	mov [rel fd1], rax

	; read file size first

	mov rax, 8  					;  syscall for lseek
	mov rdi, [rel fd1]
	mov rsi, 0 						; offset 0 bytes
	mov rdx, 2 						; type: 0 -> set beginning, 1-> curr, 2-> end
	syscall

	mov [rel file_size_bytes], rax

	; reset seek to 0

	mov rax, 8 						; seek syscall
	mov rdi, [rel fd1]
	mov rsi, 0 						; offset
	mov rdx, 0 						; type 0 -> go beginning
	syscall

	; read the entire file and store in buffer
	
	sub rsp, [rel file_size_bytes]	; create stack space

	mov rax, 0 						; read syscall
	mov rdi, [rel fd1]
	mov rsi, rsp
	mov rdx, [rel file_size_bytes]
	syscall							; get data inside stack

	; print to terminal

	mov rax, 1
	mov rdi, 1
	mov rsi, rsp
	mov rdx, [rel file_size_bytes]
	syscall							; print data to terminal

	add rsp, [rel file_size_bytes]

	; close fd

	mov rax, 3
	mov rdi, [rel fd1]
	syscall

	mov rax, 60
	mov rdi, 0
	syscall							; exit program
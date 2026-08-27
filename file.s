; This program reads 1024 bytes from file1 and appends it to file 2


section .data
	path1 db "/home/sarthak/Desktop/asm/data.txt", 0
	path2 db "/home/sarthak/Desktop/asm/data2.txt", 0


section .bss
	buffer resb 1024
	fd1 resq 1
	fd2 resq 1
	bytes_read resq 1


section .text

global _start

_start:
	
	; open file 1

	mov rax, 2				; syscall number to open a file, returns fd number in rax
	mov rdi, path1			; load the address of string not the actual string
	mov rsi, 0 				; 0 -> read only
	syscall					; output is a fd (like 3 stored in rax)
	
	mov [rel fd1], rax

	; open file 2

	mov rax, 2				; syscall number to open a file, returns fd number in rax
	mov rdi, path2			; load the address of string not the actual string
	mov rsi, 1025 			; 0 -> read only, 1-> write only, 1024->append only, 1025 -> write+append
	syscall					; output is a fd (like 3 stored in rax)

	mov [rel fd2], rax


	; read from file 1 and store into buffer

	mov rax, 0				; 0 -> syscall for read
	mov rdi, [rel fd1]		; fd stored in rdi
	mov rsi, buffer
	mov rdx, 1024			; how much to read, returns how much it read inside rax
	syscall

	mov [rel bytes_read], rax

	; change fd 1 to point to file2

	mov rax, 33				; syscall number to change fd
	mov rdi, [rel fd2]		; the fd of which copy will be made
	mov rsi, 1 				; fd which will become the copy of old fd
	syscall

	; write to fd 1

	mov rbx, rax				; storing amount of data read inside rbx
	mov rax, 1 					; 1 -> syscall to write
	mov rdi, 1 					; fd = 1, terminal selected (1 default terminal change to write_tofile)
	mov rsi, buffer 			; location of data given
	mov rdx, [rel bytes_read]   ; amount of data to print given
	syscall

	; close fd1

	mov rax, 3			; syscall number to close the file
	mov rdi, [rel fd1]
	syscall

	; close fd2

	mov rax, 3			; syscall number to close the file
	mov rdi, [rel fd2]
	syscall

	; exit program

	mov rax, 60			; sysclal to exit program
	mov rdi, 0 			; status code
	syscall

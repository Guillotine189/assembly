section .data
	usage_line0 db "Usage: ",0
	usage_line0_len equ $ - usage_line0

	usage_line1 db " <filePath1> <filePath2>",10,0
	usage_line1_len equ $ - usage_line1

	error_opening_file db "Error opening file: ", 0
	error_opening_file_len equ $ - error_opening_file

	error_creating_file db "Error Creating file: ", 0
	error_creating_file_len equ $ - error_creating_file

	error_reading_from_file db "Error reading from file: ", 0
	error_reading_from_file_len equ $ - error_reading_from_file

	error_writing_to_file db "Error writing to file: ", 0
	error_writing_to_file_len equ $ - error_writing_to_file

section .bss
	buffer resb 16384
	buffer_size equ 16384
	statbuf resb 144				; yes it is always 144 bytes

	finalFilePath resb 4096

	S_IFMT  equ 0o170000			; masks for st_mode
	S_IFREG equ 0o100000			; value file when : mask AND eax 
	S_IFDIR equ 0o040000			; value dir  when : mask AND eax 



section .text

extern _print
extern _strlen
extern _memcpy_with_end_char
extern _file_name_address

global _start


_start:

	; handle args passed

	mov rax, [rsp]							; argc in rax
	cmp rax, 3
	jne _usage

	; open 1st file

	mov rax, 2 								; open syscall
	mov rdi, [rsp + 16]						; address of filepath
	mov rsi, 0 								; 0 flag: readOnly
	syscall

	cmp rax, 0
	jl .error_opening_file_one

	mov r12, rax							; r12 stores fd1
	
	; check if 2nd arg is file/dir


	mov rax, 4 								; stat syscall
	mov rdi, [rsp + 24]						; address filepath
	mov rsi, statbuf						; address to put data 
	syscall									; if rax < 0 -> error 

	cmp rax, 0
	jl .check_if_filepath_can_be_created_original_path

	; get the st_mode	
	mov eax, [rel statbuf + 24] 				; st_mode offset 24, only 4bytes in size

	and eax, S_IFMT
	
	; if the output filepath is a file
	cmp eax, S_IFREG
	je .loop

	; handle when output path is a directory
	
	mov rdi, [rsp + 24]
	call _strlen

	mov rcx, [rsp + 24]
	cmp byte [rcx + rax - 1], '/'
	je .initialize_memcpy			; if the end of filepath2 is /

	mov dl, '/'									; when memcpy called, it will append 
	mov r8b, 1 									; set flag to apppend anything 			
	jmp .copy_dest_address_to_final_path


	.initialize_memcpy:
		mov r8b, 0

	
	.copy_dest_address_to_final_path:
		mov rdi, finalFilePath
		mov rsi, [rsp + 24]
		call _memcpy_with_end_char 				; move filepath2 to final address
		
	
	.copy_file_name_to_final_address:
		mov r14, rax

		mov rdi, [rsp + 16]
		call _strlen
	
		mov rdi, [rsp + 16]								; address destination 
		; pointer to filename in rdi, size of original string in rax
		call _file_name_address 
	
		mov rsi, rdi 							; address incoming bytes src
		mov rdi, r14
		mov rdx, 0
		mov r8b, 1
		call _memcpy_with_end_char
	
		jmp .check_if_filepath_can_be_created_new_path


	.check_if_filepath_can_be_created_original_path:
		mov rax, 2 								; open syscall
		mov rdi, [rsp + 24]						; address of filepath
		mov rsi, 65 							; 1 + 64 flag: writeOnly + create
		mov rdx, 0644o							; 64 : permission 644
		syscall

		cmp rax, 0
		jl .error_creating_file_two
		
		mov r13, rax							; r13 stores fd2
		jmp .loop
		

	.check_if_filepath_can_be_created_new_path:
		mov rax, 2 								; open syscall
		mov rdi, finalFilePath					; address of filepath
		mov rsi, 65 							; 1 + 64 flag: writeOnly + create
		mov rdx, 0644o							; 64 : permission 644
		syscall

		cmp rax, 0
		jl .error_creating_file_two
		
		mov r13, rax							; r13 stores fd2


	.loop:
		; copy to buffer from file 1 into memory

		mov rax, 0 							; read syscall
		mov rdi, r12						; fd to read from
		mov rsi, buffer 					; address to store data
		mov rdx, buffer_size 				; how much to read (macro)
		syscall								; rax stores how many bytes read

		cmp rax, 0
		jl .error_reading_from_file
		je .close_both_fd

		; write output to fd of file 2

		mov rdx, rax						; number of bytes to print
		mov rax, 1 							; write syscall
		mov rdi, r13						; fd number
		mov rsi, buffer 					; address of input
		syscall								; return bytes written in rax

		cmp rax, 0
		jl .error_writing_to_file

		jmp .loop


	.error_opening_file_one:

		mov rax, error_opening_file_len			; length (this is a macro)
		mov rdi, 2 								; fd
		mov rsi, error_opening_file				; address
		call _print

		; find length of the arg
		mov rdi, [rsp + 16]						; address of input string
		call _strlen 							; output len in rax

		; print the argv[1]/filepath1
		mov rdi, 2 								; fd of output
		mov rsi, [rsp + 16]						; address
		call _print

		mov rax, 1
		jmp _exit_with_status_code

	.error_creating_file_two:

		mov rax, error_creating_file_len			; length (this is a macro)
		mov rdi, 2 									; fd
		mov rsi, error_creating_file 				; address
		call _print

		; find length of the arg
		mov rdi, [rsp + 24]						; address of input string
		call _strlen 							; output len in rax

		; print the argv[1]/filepath1
		mov rdi, 2 								; fd of output
		mov rsi, [rsp + 24]						; address
		call _print
		
		call _close_fd1
		mov rax, 1
		jmp _exit_with_status_code

	.error_reading_from_file:

		mov rax, error_reading_from_file_len	; length (this is a macro)
		mov rdi, 2 								; fd
		mov rsi, error_reading_from_file 		; address
		call _print

		; find length of the arg
		mov rdi, [rsp + 16]						; address of input string
		call _strlen 							; output len in rax

		; print the argv[1]/filepath1
		mov rdi, 2 								; fd of output
		mov rsi, [rsp + 16]						; address
		call _print
		
		mov rax, 1 								; exit code
		jmp .close_both_fd

	.error_writing_to_file:

		mov rax, error_writing_to_file_len		; length (this is a macro)
		mov rdi, 2 								; fd
		mov rsi, error_writing_to_file 			; address
		call _print

		; find length of the arg
		mov rdi, [rsp + 24]						; address of input string
		call _strlen 							; output len in rax

		; print the argv[1]/filepath1
		mov rdi, 2 								; fd of output
		mov rsi, [rsp + 24]						; address
		call _print

		mov rax, 1 								; exit code
		jmp .close_both_fd
		

	.close_both_fd:
		mov r12, rax
		call _close_fd2
		call _close_fd1
		mov rax, r12
		jmp _exit_with_status_code


_close_fd1:
	mov rax, 3
	mov rdi, r12
	syscall
	ret


_close_fd2:
	mov rax, 3
	mov rdi, r13
	syscall
	ret

_usage:
	mov rax, usage_line0_len				; length (this is a macro)
	mov rdi, 1 								; fd
	mov rsi, usage_line0 					; address
	call _print


	; find length of the arg
	mov rdi, [rsp + 8]						; address of input string
	call _strlen 							; output len in rax

	; print the argv[0]
	mov rdi, 1 								; fd of output
	mov rsi, [rsp + 8]						; address
	call _print


	mov rax, usage_line1_len				; length (this is a macro)
	mov rdi, 1 								; fd
	mov rsi, usage_line1 					; address
	call _print

	jmp _exit


_exit_with_status_code:

	
	cmp rax, 0
	je _exit

	mov r12, rax
	; print new line
	mov al, 10

	; add to stack 1 byte
	sub rsp, 1
	mov [rsp], al 							; move 1 byte to stack

	mov rax, 1 								; write syscall
	mov rdi, 2 								; fd
	mov rsi, rsp							; address of that 1 byte
	mov rdx, 1 								; total bytes to print
	syscall

	; remove from stack
	add rsp ,1

	mov rax, 60
	mov rdi, r12
	syscall


_exit:
	mov rax, 60
	mov rdi, 0
	syscall
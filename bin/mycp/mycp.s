section .data
	usage_line0 db "Usage: ",0
	usage_line0_len equ $ - usage_line0
	usage_line1 db " [-flag: r] <filePath1> <filePath2>",10,0
	usage_line1_len equ $ - usage_line1

	recursive_flag db "-r",0

	error_opening_file db "Error opening file: ", 0
	error_opening_file_len equ $ - error_opening_file

	error_creating_file db "Error Creating file: ", 0
	error_creating_file_len equ $ - error_creating_file

	error_reading_from_file db "Error reading from file: ", 0
	error_reading_from_file_len equ $ - error_reading_from_file

	error_writing_to_file db "Error writing to file: ", 0
	error_writing_to_file_len equ $ - error_writing_to_file

	error_unkown_flag db "Error: Unkown flag passed: ", 0
	error_unkown_flag_len equ $ - error_unkown_flag

	error_input_dir_no_rec_flag0 db "Error: ", 0
	error_input_dir_no_rec_flag0_len equ $ - error_input_dir_no_rec_flag0
	error_input_dir_no_rec_flag1 db " is a directory. Use -r flag to copy a directory.", 0
	error_input_dir_no_rec_flag1_len equ $ - error_input_dir_no_rec_flag1

	error_status_code dq 0

section .bss
	buffer resb 16384
	buffer_size equ 16384
	statBufFp1 resb 144				; yes it is always 144 bytes
	statBufFp2 resb 144				; yes it is always 144 bytes

	flag_address resb 8
	flag_address_len resq 1

	fp1_address resb 8
	fp1_address_len resq 1
	fp1_fd resq 1
	fp2_address resb 8
	fp2_address_len resq 1
	fp2_fd resq 1

	finalFilePath resb 4096

	S_IFMT  equ 0o170000			; masks for st_mode
	S_IFREG equ 0o100000			; value file when : mask AND eax 
	S_IFDIR equ 0o040000			; value dir  when : mask AND eax 

	DT_REG equ 8    ; regular file
	DT_DIR equ 4    ; directory


section .text

extern _print
extern _strlen
extern _memcpy_with_end_char
extern _file_name_address
extern _cmp_equal_memory

global _start


_start:

	; handle args passed

	mov rax, [rsp]							; argc in rax

	cmp rax, 3
	je .no_flag_passed

	cmp rax, 4
	je .flag_passed

	jmp _usage


	.flag_passed:

	; save the file path and length to variables and flag

	mov rcx, [rsp + 16]
	mov [rel flag_address], rcx
	mov rcx, [rsp + 24]
	mov [rel fp1_address], rcx
	mov rcx, [rsp + 32]
	mov [rel fp2_address], rcx

	mov rdi, [rel flag_address]
	call _strlen
	mov [rel flag_address_len], rax

	mov rdi, [rel fp1_address]
	call _strlen
	mov [rel fp1_address_len], rax

	mov rdi, [rel fp2_address]
	call _strlen
	mov [rel fp2_address_len], rax

	jmp .check_flag


	.check_flag:

		cmp [rel flag_address_len], 2
		jne .error_unkown_flag

		mov rax, 2
		mov rdi, recursive_flag
		mov rsi, [rel flag_address]
		call _cmp_equal_memory		; check if the flag is -r, 0is same, 1 if not

		cmp rax, 0
		jne .error_unkown_flag

		; at this point I know that -r flag has been passed
		; check if the 1st file is a file or dir

		mov rax, 4 								; stat syscall
		mov rdi, [rel fp1_address]
		lea rsi, [rel statBufFp1]
		syscall

		cmp rax, 0
		jl .error_opening_file_one

		; read the mode
		mov eax, [rel statBufFp1 + 24]						;read 4 bytes
		and eax, S_IFMT


		cmp eax, S_IFREG
		je .start_program

		cmp eax, S_IFDIR
		je .input_is_dir


	.input_is_dir:







		call _exit



	.no_flag_passed:

	; save the file path and length to variables
	mov rcx, [rsp + 16]
	mov [rel fp1_address], rcx
	mov rcx, [rsp + 24]
	mov [rel fp2_address], rcx

	mov rdi, [rel fp1_address]
	call _strlen
	mov [rel fp1_address_len], rax

	mov rdi, [rel fp2_address]
	call _strlen
	mov [rel fp2_address_len], rax

	; check if file 1 is file or dir
	mov rax, 4 								; stat syscall
	mov rdi, [rel fp1_address]
	lea rsi, [rel statBufFp1]
	syscall

	cmp rax, 0
	jl .error_opening_file_one

	; read the mode
	mov eax, [rel statBufFp1 + 24]						;read 4 bytes
	and eax, S_IFMT


	cmp eax, S_IFREG
	je .start_program

	cmp eax, S_IFDIR
	je .error_input_dir_no_rec_flag





	.start_program:


	; open 1st file, 
	; If you are here, it means the fp1 exists

	mov rax, 2 								; open syscall
	mov rdi, [rel fp1_address]						; address of filepath
	mov rsi, 0 								; 0 flag: readOnly
	syscall

	mov [rel fp1_fd], rax							; [rel fp1_fd] stores fd1
	




	; check if 2nd arg is file/dir


	mov rax, 4 								; stat syscall
	mov rdi, [rel fp2_address]						; address filepath
	lea rsi, [rel statBufFp2]						; address to put data 
	syscall									; if rax < 0 -> error 

	cmp rax, 0
	jl .check_if_filepath2_can_be_opened_original_path

	; get the st_mode	
	mov eax, [rel statBufFp2 + 24] 				; st_mode offset 24, only 4bytes in size

	and eax, S_IFMT
	
	; if the output filepath is a file
	cmp eax, S_IFREG
	je .check_if_filepath2_can_be_opened_original_path

	; handle when output path is a directory
	
	mov rdi, [rel fp2_address]
	call _strlen

	mov rcx, [rel fp2_address]
	cmp byte [rcx + rax - 1], '/'
	je .initialize_memcpy			; if the end of filepath2 is /

	mov dl, '/'									; when memcpy called, it will append 
	mov r8b, 1 									; set flag to apppend anything 			
	jmp .copy_dest_address_to_final_path


	.initialize_memcpy:
		mov r8b, 0

	
	.copy_dest_address_to_final_path:
		mov rdi, finalFilePath
		mov rsi, [rel fp2_address]
		call _memcpy_with_end_char 				; move filepath2 to final address
		
	
	.copy_file_name_to_final_address:
		mov r14, rax

		mov rdi, [rel fp1_address]
		call _strlen
	
		mov rdi, [rel fp1_address]								; address destination 
		; pointer to filename in rdi, size of original string in rax
		call _file_name_address 
	
		mov rsi, rdi 							; address incoming bytes src
		mov rdi, r14
		mov rdx, 0
		mov r8b, 1
		call _memcpy_with_end_char
	
		jmp .check_if_filepath_can_be_created_new_path


	.check_if_filepath2_can_be_opened_original_path:
		mov rax, 2 								; open syscall
		mov rdi, [rel fp2_address]						; address of filepath
		mov rsi, 65 							; 1 + 64 flag: writeOnly + create
		mov rdx, 0644o							; 64 : permission 644
		syscall

		cmp rax, 0
		jl .error_creating_file_two
		
		mov [rel fp2_fd], rax							; [rel fp2_fd] stores fd2
		jmp .loop
		

	.check_if_filepath_can_be_created_new_path:
		mov rax, 2 								; open syscall
		mov rdi, finalFilePath					; address of filepath
		mov rsi, 65 							; 1 + 64 flag: writeOnly + create
		mov rdx, 0644o							; 64 : permission 644
		syscall

		cmp rax, 0
		jl .error_creating_file_two
		
		mov [rel fp2_fd], rax							; [rel fp2_fd] stores fd2


	.loop:
		; copy to buffer from file 1 into memory

		mov rax, 0 							; read syscall
		mov rdi, [rel fp1_fd]						; fd to read from
		mov rsi, buffer 					; address to store data
		mov rdx, buffer_size 				; how much to read (macro)
		syscall								; rax stores how many bytes read

		cmp rax, 0
		jl .error_reading_from_file
		je .close_both_fd

		; write output to fd of file 2

		mov rdx, rax						; number of bytes to print
		mov rax, 1 							; write syscall
		mov rdi, [rel fp2_fd]						; fd number
		mov rsi, buffer 					; address of input
		syscall								; return bytes written in rax

		cmp rax, 0
		jl .error_writing_to_file

		jmp .loop


	.error_unkown_flag:
		mov rax, error_unkown_flag_len			; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_unkown_flag]				; address
		call _print

		mov rax, [rel flag_address_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel flag_address]						; address
		call _print

		mov [rel error_status_code], 1
		jmp _exit_with_status_code


	.error_input_dir_no_rec_flag:
	

		mov rax, error_input_dir_no_rec_flag0_len			; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_input_dir_no_rec_flag0]				; address
		call _print

		mov rax, [rel fp1_address_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp1_address]						; address
		call _print


		mov rax, error_input_dir_no_rec_flag1_len		; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_input_dir_no_rec_flag1]				; address
		call _print

		mov [rel error_status_code], 1
		jmp _exit_with_status_code


	.error_opening_file_one:

		mov rax, error_opening_file_len			; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_opening_file]				; address of string itself
		call _print

		mov rax, [rel fp1_address_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp1_address]						; address
		call _print

		mov [rel error_status_code], 1
		jmp _exit_with_status_code

	.error_creating_file_two:

		mov rax, error_creating_file_len			; length (this is a macro)
		mov rdi, 2 									; fd
		lea rsi, [rel error_creating_file] 				; address
		call _print

		mov rax, [rel fp2_address_len]						; address of input string
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp2_address]						; address
		call _print
		
		call _close_fd1
		mov [rel error_status_code], 1
		jmp _exit_with_status_code

	.error_reading_from_file:

		mov rax, error_reading_from_file_len	; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_reading_from_file] 		; address
		call _print

		mov rax, [rel fp1_address_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp1_address]						; address
		call _print
		
		mov [rel error_status_code], 1
		jmp .close_both_fd

	.error_writing_to_file:

		mov rax, error_writing_to_file_len		; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_writing_to_file] 			; address
		call _print

		mov rax, [rel fp2_address_len]						; address of input string
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp2_address]						; address
		call _print

		mov [rel error_status_code], 1
		jmp .close_both_fd
	

	.close_both_fd:
		call _close_fd2
		call _close_fd1
		jmp _exit_with_status_code


_close_fd1:
	mov rax, 3
	mov rdi, [rel fp1_fd]
	syscall
	ret


_close_fd2:
	mov rax, 3
	mov rdi, [rel fp2_fd]
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

	
	cmp [rel error_status_code], 0
	je _exit

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
	mov rdi, [rel error_status_code]
	syscall


_exit:
	mov rax, 60
	mov rdi, 0
	syscall
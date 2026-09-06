section .data
	usage_line0 db "Usage: ",0
	usage_line0_len equ $ - usage_line0
	usage_line1 db " [-flag: r] <filePath1> <filePath2>",10,0
	usage_line1_len equ $ - usage_line1

	recursive_flag db "-r",0

	error_opening_directory db "Error opening directory: ", 0
	error_opening_directory_len equ $ - error_opening_directory

	error_output_is_file_input_is_dir0 db "Error: Cannot copy directory ",0
	error_output_is_file_input_is_dir0_len equ $ - error_output_is_file_input_is_dir0
	error_output_is_file_input_is_dir1 db " as ", 0
	error_output_is_file_input_is_dir1_len equ $ - error_output_is_file_input_is_dir1
	error_output_is_file_input_is_dir2 db ", file with this name already exists.", 0
	error_output_is_file_input_is_dir2_len equ $ - error_output_is_file_input_is_dir2

	error_creating_initial_directory db "Error creating directory: ", 0
	error_creating_initial_directory_len equ $ - error_creating_initial_directory

	error_getting_cwd_org_src_file db "Error getting absolute file path for ", 0
	error_getting_cwd_org_src_file_len equ $ - error_getting_cwd_org_src_file

	error_fp2_is_sub_dir_fp10 db "Error: ", 0
	error_fp2_is_sub_dir_fp10_len equ $ - error_fp2_is_sub_dir_fp10

	error_fp2_is_sub_dir_fp11 db ", is a sub directory of ", 0
	error_fp2_is_sub_dir_fp11_len equ $ - error_fp2_is_sub_dir_fp11

	error_creating_new_dir_and_exit db "Error creating directory: ", 0
	error_creating_new_dir_and_exit_len equ $ - error_creating_new_dir_and_exit

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

	error_same_file_provided db "Error: same file provided.", 0
	error_same_file_provided_len equ $ - error_same_file_provided

	error_input_dir_no_rec_flag0 db "Error: ", 0
	error_input_dir_no_rec_flag0_len equ $ - error_input_dir_no_rec_flag0
	error_input_dir_no_rec_flag1 db " is a directory. Use -r flag to copy a directory.", 0
	error_input_dir_no_rec_flag1_len equ $ - error_input_dir_no_rec_flag1

	error_only_dir_file_copy_supported0 db "Error copying : ",0 
	error_only_dir_file_copy_supported0_len equ $ - error_only_dir_file_copy_supported0
	error_only_dir_file_copy_supported1 db ", only Directory or a Regular file can be copied.", 0
	error_only_dir_file_copy_supported1_len equ $ - error_only_dir_file_copy_supported1

	error_status_code dq 0
	getDentDirBuf_size dq 0

	dot_file db '.', 0
	double_dot_file db '..', 0
	backSlash db '/', 0

section .bss
	buffer resb 16384
	buffer_size equ 16384
	statBufFSrcDir resb 144				; yes it is always 144 bytes
	statBufFDstDir resb 144				; yes it is always 144 bytes
	statBufFp1 resb 144				; yes it is always 144 bytes
	statBufFp2 resb 144				; yes it is always 144 bytes

	flag_address resb 8
	flag_address_len resq 1

	dir_fd resq 1
	original_src_dir_address resb 8
	original_src_dir_name_len resq 1

	original_dst_dir_address resb 8
	original_dst_dir_name_len resq 1

	normalized_src_dir_name resb 4096
	normalized_src_dir_name_len resq 1
	normalized_dst_dir_name resb 40196
	normalized_dst_dir_name_len resq 1

	cwd_buf resb 4096
	cwd_fp_len resq 1

	original_src_combined_cwd_and_input_file_name resb 4096
	original_src_combined_cwd_and_input_file_name_len resq 8
	original_dst_combined_cwd_and_output_file_name resb 4096
	original_dst_combined_cwd_and_output_file_name_len resq 8

	local_src_dir_address resb 8
	local_src_dir_name_len resq 1
	local_dst_dir_address resb 8
	local_dst_dir_name_len resq 1

	fp1_address resb 8
	fp1_name_len resq 1
	fp1_fd resq 1
	fp2_address resb 8
	fp2_name_len resq 1
	fp2_fd resq 1

	finalFilePath resb 4096

	getDentDirBuf resb 4096

	rec_file_path_src resb 4096

	S_IFMT  equ 0o170000			; masks for st_mode
	S_IFREG equ 0o100000			; value file when : mask AND eax 
	S_IFDIR equ 0o040000			; value dir  when : mask AND eax 

	DT_REG equ 8    ; regular file
	DT_DIR equ 4    ; directory
	DT_LNK equ 10



section .text

extern _print
extern _print_with_new_line
extern _strlen
extern _memcpy_with_end_char
extern _file_name_address
extern _cmp_equal_memory
extern _normalize_file_path
extern _check_fp2_is_sub_dir_fp1

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
	mov [rel original_src_dir_address], rcx
	mov rcx, [rsp + 32]
	mov [rel original_dst_dir_address], rcx

	mov rdi, [rel flag_address]
	call _strlen
	mov [rel flag_address_len], rax

	mov rdi, [rel original_src_dir_address]
	call _strlen
	mov [rel original_src_dir_name_len], rax

	mov rdi, [rel original_dst_dir_address]
	call _strlen
	mov [rel original_dst_dir_name_len], rax

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
		mov rdi, [rel original_src_dir_address]
		lea rsi, [rel statBufFSrcDir]
		syscall

		cmp rax, 0
		jl .error_opening_file_one_with_exit

		; read the mode
		mov eax, [rel statBufFSrcDir + 24]						;read 4 bytes
		and eax, S_IFMT

		cmp eax, S_IFDIR
		je .check_if_out_path_is_a_dir

		cmp eax, S_IFREG
		jne .print_error_only_fileDir_supported_and_exit

		; first path was a file not a directory
		mov rax, [rel original_src_dir_address]
		mov [rel fp1_address], rax
		mov rax, [rel original_src_dir_name_len]
		mov [rel fp1_name_len], rax

		mov rax, [rel original_dst_dir_address]
		mov [rel fp2_address], rax
		mov rax, [rel original_dst_dir_name_len]
		mov [rel fp2_name_len], rax

		mov rax, 144						; size of both is 144bytes
		mov rdi, statBufFSrcDir				; src address
		mov rsi, statBufFp1					; dest address
		xor r8, r8 							; no end char to copy
		call _memcpy_with_end_char

		; check if 2nd file is same as first
		jmp ._check_second


		.check_if_out_path_is_a_dir:
			mov rax, 4 								; stat syscall
			mov rdi, [rel original_dst_dir_address]
			lea rsi, [rel statBufFDstDir]
			syscall

			cmp rax, 0
			jl .check_if_dir_can_be_created

			; read the mode
			mov eax, [rel statBufFDstDir + 24]						;read 4 bytes
			and eax, S_IFMT

			cmp eax, S_IFDIR
			je .setup_and_start_copying

			cmp eax, S_IFREG
			je .call_out_is_file_inp_is_dir_error_and_exit

			jmp .print_error_only_fileDir_supported_and_exit

			.call_out_is_file_inp_is_dir_error_and_exit:
				call .error_output_is_file_input_is_dir
				call _exit_with_status_code


			; dst address does NOT exists: 	
			; [try to create the og_dst,start copying: no adding og_src_folder_name]
			.check_if_dir_can_be_created:
				call .normalize_file_paths_and_check_sub_dir
				call .check_if_og_dst_can_be_created
				jmp .prepare_args_call_copy_dir_function


			; dst directory exists:
			; [try to create the (og_dst+og_src_folder_name),start copying]
			.setup_and_start_copying:
				call .normalize_file_paths_and_check_sub_dir	
				call .check_and_create_src_folder_inside_og_dst
				jmp .prepare_args_call_copy_dir_function


			call _exit 					; TODO: placeholder remove this later


		.normalize_file_paths_and_check_sub_dir:
			; get cwd

			mov rax, 79 						; cwd syscall number
			lea rdi, [rel cwd_buf]
			mov rsi, 4096 						; buffer size
			syscall 							; rax has the file size

			; make abs_src_address cwd + og_src_address

			cmp rax, 0
			jl .error_getting_cwd_org_src_file 

			mov [rel cwd_fp_len], rax

			; make abs_src_adds cwd+og_src_address
			sub rax, 1 							; og len includes \0, i dont want that
			lea rdi, [rel original_src_combined_cwd_and_input_file_name]
			lea rsi, [rel cwd_buf]
			mov dl, '/'
			mov r8,1
			call _memcpy_with_end_char  		; rax pointer to next address

			mov rdi, rax
			mov rax, [rel original_src_dir_name_len]
			mov rsi, [rel original_src_dir_address]
			mov dl, 0
			mov r8,1
			call _memcpy_with_end_char  		; rax pointer to next address

			lea rcx, [rel original_src_combined_cwd_and_input_file_name]
			sub rax, rcx
			sub rax, 1 							; og len includes \0, i dont want that
			mov [rel original_src_combined_cwd_and_input_file_name_len], rax


			; make abs_dest_adds cwd + og_dst_address 
			mov rax, [rel cwd_fp_len]
			sub rax, 1
			lea rdi, [rel original_dst_combined_cwd_and_output_file_name]
			lea rsi, [rel cwd_buf]
			mov dl, '/'
			mov r8,1
			call _memcpy_with_end_char  		; rax pointer to next address

			mov rdi, rax
			mov rax, [rel original_dst_dir_name_len]
			mov rsi, [rel original_dst_dir_address]
			mov dl, 0
			mov r8,1
			call _memcpy_with_end_char  		; rax pointer to next address

			lea rcx, [rel original_dst_combined_cwd_and_output_file_name]
			sub rax, rcx
			sub rax, 1 							; og len includes \0, i dont want that
			mov [rel original_dst_combined_cwd_and_output_file_name_len], rax


			;normalize abs_src_address
			mov rax, [rel original_src_combined_cwd_and_input_file_name_len]
			lea rdi, [rel original_src_combined_cwd_and_input_file_name]
			lea rsi, [rel normalized_src_dir_name]
			call _normalize_file_path

			cmp rax, 0
			jl .error_opening_file_one_with_exit ; TODO : fix error invalid path

			mov [rel normalized_src_dir_name_len], rax

			;normalize abs_src_address
			mov rax, [rel original_dst_combined_cwd_and_output_file_name_len]
			lea rdi, [rel original_dst_combined_cwd_and_output_file_name]
			lea rsi, [rel normalized_dst_dir_name]
			call _normalize_file_path

			mov [rel normalized_dst_dir_name_len], rax
			; TODO : fix error invalid path, same a sabove

			; check_output_dir_not_a_sub_dir
			
			lea rdi, [rel normalized_src_dir_name]
			lea rsi, [rel normalized_dst_dir_name]
			call _check_fp2_is_sub_dir_fp1


			cmp rax, 0
			je .error_fp2_is_sub_dir_fp1
			ret

		.check_if_og_dst_can_be_created:

			mov rax, 83          ; sys_mkdir
		    lea rdi, [rel normalized_dst_dir_name]     ; pathname
		    mov rsi, 0755o       ; permissions
		    syscall

		    cmp rax, 0
		    jl .error_creating_initial_directory  ; TODO: fix which directory is shown in error

		    ret 

		.check_and_create_src_folder_inside_og_dst:

			; find the len of the file_name, eg
			; /home/sarthak/src_filename
			; |a		   |b 	       |c
			; a -> original address
			; b -> addd returned from _file_name_address - 1 -> '/'
			; c -> a + len of path - 1
			; size_src_file_name = c - b + 1, 

			mov rax, [rel normalized_src_dir_name_len]
			lea rdi, [rel normalized_src_dir_name]
			call _file_name_address 		; rdi has address where filename starts

			sub rdi, 1

			lea rcx, [rel normalized_src_dir_name]				; a
			add rcx, [rel normalized_src_dir_name_len]
			sub rcx, 1 											; c
			sub rcx, rdi 										
			inc rcx 								; file_name_size when '/' included

			mov rax, rcx
			mov rsi, rdi
			lea rdi, [rel normalized_dst_dir_name]
			add rdi, [rel normalized_dst_dir_name_len] 	; at '\0'
			mov dl, 0 									; copy \0 at end
			mov r8, 1
			call _memcpy_with_end_char

			; save new len of fnormalized address
			; /home/sarthak/dst_folder_that_already_exists/src_folder\0
			; |a 													  |rax
			lea rcx, [rel normalized_dst_dir_name] 				; a
			sub rax, rcx
			mov [rel normalized_dst_dir_name_len], rax


			; now check if you can make this new directory

			mov rax, 83          ; sys_mkdir
		    lea rdi, [rel normalized_dst_dir_name]     ; pathname
		    mov rsi, 0755o       ; permissions
		    syscall

		    cmp rax, 0
		    jl .error_creating_new_dir_and_exit
			ret

		.prepare_args_call_copy_dir_function:

			; STACK -----------------------------------------------------------

			;  			|     	actual_sys_getdents64_data		| -> -z bytes
			; 					------------------------
			;	  0x103	|    src_dir_name_ending_with_'\0'	  	| -> -x bytes
			; 					------------------------
			;	  0x105	|    dst_dir_name_ending_with_'\0'	  	| -> -y bytes
			; 					------------------------
	
			; rax: fd of current open directory
			; rdi: offset_for_getdents64
			; rsi: total_size_sys_getdents64
			; rdx: local_src_dir_name_length
			; rcx: local_dst_dir_name_length

			.open_init_src_dir:

			mov rax, 2
			lea rdi, [rel normalized_src_dir_name]
			mov rsi, 0 							; read only for src
			syscall

			cmp rax, 0
			jl .cannot_open_initial_src_dir_exit
			
			mov r12, rax 					; r12 fd in callee register safe

			jmp .getdent_init_src_dir

			.cannot_open_initial_src_dir_exit:
				call .error_opening_directory   ;TODO: fix display proper file	
				call _exit_with_status_code

			.getdent_init_src_dir:

			mov rax, 217 					; sys_getdents64 syscall
			mov rdi, r12						; fd
			lea rsi, [rel getDentDirBuf] 	; buffer
			mov rdx, 4096					; how much bytes to write
			syscall

			cmp rax, 0
			jl .cannot_open_initial_src_dir_exit   ; TODO: maybe give proper error

			mov r13, rax 				; r13: size of getdent in callee register safe

			.prepare_stack:
			; find how much space to need in stack
			mov r10, r13 							; size of get_dent_data			
			add r10, [rel normalized_src_dir_name_len]	; add len of src_file_name
			inc r10									; add space for '\0'
			add r10, [rel normalized_dst_dir_name_len] ; add len of dst_file_name
			inc r10									; add space for '\0'

			; reserver stack space
			sub rsp, r10

			.check_stack:

			; add info to stack

			; move actual sysgetdentData
			mov rax, r13								; len of data recv from getdent
			mov rdi, rsp 								; destination stack
			lea rsi, [rel getDentDirBuf] 				; src address 
			xor r8, r8 									; no ending with anything
			call _memcpy_with_end_char 		; rax has next address of last byte writen
			;mov rsp, rax 								; move rsp forward

			;add the src_file_name
			mov rdi, rax
			mov rax, [rel normalized_src_dir_name_len]
			lea rsi, [rel normalized_src_dir_name]
			mov dl, 0
			mov r8, 1
			call _memcpy_with_end_char
			;mov rsp, rax 								; move rsp forward

			; add the dst file name
			mov rdi, rax
			mov rax, [rel normalized_dst_dir_name_len]
			lea rsi, [rel normalized_dst_dir_name]
			mov dl, 0
			mov r8, 1
			call _memcpy_with_end_char

			.prepare_registers:

			mov rsi, r13 								; rsi size of getdent_returned
			mov rax, r12 								; rax has fd
			mov rdi, 0 									; offset for getdent, init: 0
			mov rdx, [rel normalized_src_dir_name_len]
			mov rcx, [rel normalized_dst_dir_name_len]

			.debug3:
				call _exit







			sub rsp, [rel original_src_dir_name_len]
			sub rsp, [rel original_dst_dir_name_len]
			sub rsp, 34

			; (3x8 + 2 + len_src + len_dst)(for 1st iteration) + 8(for termation)
			
			; directory fd
			mov qword [rsp], 0

			; length of src directory_name
			mov rax, [rel original_src_dir_name_len]
			mov [rsp + 8], rax
			
			.problem_start:
			; actual src directory name
			mov rax, [rel original_src_dir_name_len]
			lea rdi, [rsp + 16]
			mov rsi, [rel original_src_dir_address]
			mov r8, 1 								; '\0 as end char'
			xor rdx, rdx 							; null terminator in end
			call _memcpy_with_end_char
			
			mov rbx,  [rel original_src_dir_name_len]
			inc rbx 						; bec of "\0"

			; length of dst directory_name
			mov rax, [rel original_dst_dir_name_len]
			mov [rsp + 16 + rbx], rax
			
			; actual dst directory name
			mov rax, [rel original_dst_dir_name_len]
			lea rdi, [rsp + 24 + rbx]
			mov rsi, [rel original_dst_dir_address]
			mov r8, 1 								; '\0 as end char'
			xor rdx, rdx 							; null terminator in end
			call _memcpy_with_end_char			

			.problem:

			add rbx, [rel original_dst_dir_name_len]
			inc rbx
			
			; this is the condition for my recursive _input_is_file function to end
			mov rax,  99999
			mov [rsp + 24 + rbx],	rax				; fake fd for last recursion
			
			
			.before_call:

			call .start_copying_dir


	; in the first iteration it's 

	; old rbp will be added to stack when this function runs
	; rsp->0x1  | 				old rbp x100 			| -> -8 bytes
	; 			| 		   address for return 			| -> current rbp

	;			|      	  offset_for_getdents64 		| -> +16 bytes
	;  			|     	total_size_sys_getdents64		| -> +24 bytes
	;  			|     	actual_sys_getdents64_data		| -> +32 bytes
	; 					------------------------
	;  	  0x2	| 	 	fd of currnet directory   		| -> +x bytes
	;	  0x3	| 		local_src_dir_name_length		| -> +x+8 bytes
	;	  0x4	|    src_dir_name_ending_with_'\0'	  	| -> +x+16 bytes
	; 					------------------------
	;	  0x5	| 		local_dst_dir_name_length		| -> +y  bytes
	;	  0x6	|    dst_dir_name_ending_with_'\0'	  	| -> +x+8 bytes
	; 					------------------------
	


	; STACK -----------------------------------------------------------

	; 	rsp ->  | 			return address 				| -> +0bytes
	;  			|     	actual_sys_getdents64_data		| -> +8 bytes
	; 					------------------------
	;	  0x103	|    src_dir_name_ending_with_'\0'	  	| -> +x bytes
	; 					------------------------
	;	  0x105	|    dst_dir_name_ending_with_'\0'	  	| -> +xy bytes
	; 					------------------------
	

	; rax: fd of current open directory
	; rdi: offset_for_getdents64
	; rsi: total_size_sys_getdents64
	; rdx: local_src_dir_name_length
	; rcx: local_dst_dir_name_length
	; stack: actual_sys_getdents64_data
	; stack: src_dir_name_ending_with_'\0'
	; stack: dst_dir_name_ending_with_'\0'

	.start_copying_dir:

		push rbp
		mov rbp, rsp
		
		.examin:
		mov rax, [rsp]							; check the fd
		cmp rax, 99999
		je _exit

		mov rax, [rsp + 16]                    ; source length
		lea rcx, [rsp + 24]                    ; source address
		mov [rel local_src_dir_address], rcx
		mov [rel local_src_dir_name_len], rax

		lea rcx, [rsp + 24 + rax + 1]          ; destination len address

		mov rdx, [rcx]                         ; actual destination length
		mov [rel local_dst_dir_name_len], rdx

		lea rcx, [rcx + 8]                     ; destination string address
		mov [rel local_dst_dir_address], rcx

		add rcx, [rel local_dst_dir_name_len]
		inc rcx									; bec of '\0'
		push rcx						; The top of stack has address of next address

		; open directory

		.check_open:

		mov rax, 2
		mov rdi, [rel local_src_dir_address]
		mov rsi, 0
		syscall

		test rax, rax
		jl .print_error_opening_dir_and_move_out_of_directory

		mov [rsp + 8], rax 							; also save it in stack
		mov [rel dir_fd], rax 						; fd1 not lives in stack for 8 bytes

		.outer_loop:

		; get data for input 

		mov rax, 217 					; sys_getdents64 syscall
		mov rdi, [rel dir_fd]					; fd
		lea rsi, [rel getDentDirBuf] 	; buffer
		mov rdx, 4096					; how much bytes to write
		syscall

		test rax,rax
		jl .print_error_opening_dir_and_move_out_of_directory
		jz .move_out_of_directory

		; now check all the files inside

		; rax will always contain the total size
		xor r8, r8 								; offset for reading buffer

		; make sure to push rax, r8 to stack when recursive
		.inner_loop:

			; check if next segment is available
			cmp r8, rax
			je .move_out_of_directory

			; read filetype dir/file
			lea rdx, [rel getDentDirBuf]
			mov cl, [rdx + r8 + 18] 					; file type
			
			cmp cl, DT_DIR
			;je .move_int_directory
			
			cmp cl, DT_REG
			je .is_a_file

			; check if the files are . or ..
			.error:

			push rax
			push r8

			add rdx, r8
			add rdx, 19 			; addres of file name

			mov rax, 2 				; compare '.\0', thats why 2
			mov rdi, rdx
			mov rsi, dot_file
			call _cmp_equal_memory
			cmp rax, 0
			jne .go_loop_again

			mov rax, 3 				; compare '..\0', thats why 3
			mov rdi, rdx
			mov rsi, double_dot_file
			call _cmp_equal_memory
			cmp rax, 0
			jne .go_loop_again


			.go_loop_again:
				pop r8
				pop rax
				jmp .loopback
			
			pop r8
			pop rax


			call .error_opening_file_one_with_exit 		; not a dir, or file
			jmp .move_out_of_directory

		.is_a_file:

			; caluculate the size of file_name
			; first: get segment size : from d_reclen located at 16bytes
			; file size = [segment size - 19bytes - padding by compiler]

			lea rdx, [rel getDentDirBuf + 16]
			movzx r9, word [r8 + rdx] 					; 2bytes contain the segments size

			lea rdi, [rel getDentDirBuf]
			add rdi, r8
			add rdi, 19
			xor r10, r10

		.count_loop:
			cmp [rdi + r10], 0
			je .done

			inc r10
			jmp .count_loop

		.done:
			; 	now r10 has the file_name size

			; 1)move into rec_file_path_src the directory name + '/'
			; 2)add the file name to rec_file_path_src
			; 3)value in fp1_address equals to address of rec_file_path_src

			; 1) 
			push rax
			push r8
			push r10
			mov rax, [rel local_src_dir_name_len]
			lea rdi, [rel rec_file_path_src]
			mov rsi, [rel local_src_dir_address]
			mov r8, 1
			mov rdx, '/'
			call _memcpy_with_end_char			; rax has address of next location
			pop r10
			pop r8

			.check:
			push r8
			;2)
			mov rdi, rax
			mov rax, r10
			lea rsi, [rel getDentDirBuf]
			add rsi, r8
			add rsi, 19 						; idk why but at 18 you get file name
			mov r8, 1
			mov rdx, 0
			call _memcpy_with_end_char			; rax has address of next location

			.check2:

			; fp1_address
			lea rdx, [rel rec_file_path_src]
			mov [rel fp1_address], rdx


			; 3)
			lea rdi, [rel rec_file_path_src]
			call _strlen
			; rax now has file of path

			; fp1_name_len
			mov [rel fp1_name_len], rax


			; fp2_address
			mov rdx, [rel local_dst_dir_address]
			mov [rel fp2_address], rdx

			; fp2_name_len
			mov rdx, [rel local_dst_dir_name_len]
			mov [rel fp2_name_len], rdx

			call .copy_file1_to_path

			pop r8
			pop rax
			
		.loopback:

			lea rsi, [rel getDentDirBuf]
			add rsi, r8
			add rsi, 16
			movzx ecx, word [rsi]
			add r8, rcx

			jmp .inner_loop


		.move_int_directory:

			; TODO getDentDirBuf to stack

			call _exit


		.move_out_of_directory:

			;[ VERY IMPORTANT line]
			mov rsp, rbp

			; add stuff here

			; todo : pop recursion values from stack

			call _exit


		.print_error_opening_dir_and_move_out_of_directory:
			call .error_opening_directory
			jmp .move_out_of_directory



	.no_flag_passed:

		; save the file path and length to variables
		mov rcx, [rsp + 16]
		mov [rel fp1_address], rcx
		mov rcx, [rsp + 24]
		mov [rel fp2_address], rcx

		mov rdi, [rel fp1_address]
		call _strlen
		mov [rel fp1_name_len], rax

		mov rdi, [rel fp2_address]
		call _strlen
		mov [rel fp2_name_len], rax

		; check if file 1 is file or dir
		mov rax, 4 								; stat syscall
		mov rdi, [rel fp1_address]
		lea rsi, [rel statBufFp1]
		syscall

		cmp rax, 0
		jl .error_opening_file_one_with_exit

		; read the mode
		mov eax, [rel statBufFp1 + 24]						;read 4 bytes
		and eax, S_IFMT

		cmp eax, S_IFDIR
		je .error_input_dir_no_rec_flag

		cmp eax, S_IFREG 					; if not a dir/file, just exit
		jne .print_error_only_fileDir_supported_and_exit

		._check_second:

		; check if 2nd file is same as first
		
		mov rax, 4 								; stat syscall
		mov rdi, [rel fp2_address]
		lea rsi, [rel statBufFp2]
		syscall		

		cmp rax, 0
		; if the 2nd path doesn't exist, atleast it's not the same file
		jl .run_program_and_exit

		; check inode and dev to see if both are same of not

		mov rax, [rel statBufFp1 + 0]  ; 0 offset is dev for 8 bytes
		cmp rax, [rel statBufFp2 + 0]
		jne .run_program_and_exit 		; if not equal, diff files

		mov rax, [rel statBufFp1 + 8]  ; 8 offset is inode for 8 bytes
		cmp rax, [rel statBufFp2 + 8]
		jne .run_program_and_exit  		; if not equl diff files
		
		jmp .error_same_file_provided 	; else diff files


		.print_error_only_fileDir_supported_and_exit:
			call .error_only_dir_file_copy_supported
			call _exit_with_status_code

		.run_program_and_exit:
			call .copy_file1_to_path 
			call _exit_with_status_code



	; before calling this make sure to have
	;  fp1_address, fp1_name_len
	;  fp2_address, fp2_name_len already inside variables
	.copy_file1_to_path:


	; open 1st file, 
	; If you are here, it means the fp1 exists

	mov rax, 2 								; open syscall
	mov rdi, [rel fp1_address]						; address of filepath
	mov rsi, 0 								; 0 flag: readOnly
	syscall

	cmp rax, 0
	jl .error_opening_file_one

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
	
	mov rax, [rel fp2_name_len]
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
		; rax contains address ahead of the last byte copied
	
	.copy_file_name_to_final_address:
		mov r14, rax

		mov rax, [rel fp1_name_len]
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
		call _print_with_new_line

		mov [rel error_status_code], 1
		jmp _exit_with_status_code


	.error_input_dir_no_rec_flag:
	

		mov rax, error_input_dir_no_rec_flag0_len			; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_input_dir_no_rec_flag0]				; address
		call _print

		mov rax, [rel fp1_name_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp1_address]						; address
		call _print

		mov rax, error_input_dir_no_rec_flag1_len		; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_input_dir_no_rec_flag1]				; address
		call _print_with_new_line

		mov [rel error_status_code], 1
		jmp _exit_with_status_code


	.error_same_file_provided:

		mov rax, error_same_file_provided_len			; length (this is a macro)
		mov rdi, 2 											; fd
		lea rsi, [rel error_same_file_provided]				; address of string itself
		call _print_with_new_line

		mov [rel error_status_code], 1
		jmp _exit_with_status_code

	.error_getting_cwd_org_src_file:
		mov rax, error_getting_cwd_org_src_file_len			; length (this is a macro)
		mov rdi, 2 											; fd
		lea rsi, [rel error_getting_cwd_org_src_file]		
		call _print

		mov rax, [rel original_src_dir_name_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel original_src_dir_address]						; address
		call _print_with_new_line

		mov [rel error_status_code], 1
		jmp _exit_with_status_code

	.error_fp2_is_sub_dir_fp1:
		mov rax, error_fp2_is_sub_dir_fp10_len			; length (this is a macro)
		mov rdi, 2 											; fd
		lea rsi, [rel error_fp2_is_sub_dir_fp10]		
		call _print

		mov rax, [rel original_dst_dir_name_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel original_dst_dir_address]						; address
		call _print


		mov rax, error_fp2_is_sub_dir_fp11_len			; length (this is a macro)
		mov rdi, 2 											; fd
		lea rsi, [rel error_fp2_is_sub_dir_fp11]		
		call _print

		mov rax, [rel original_src_dir_name_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel original_src_dir_address]						; address
		call _print_with_new_line

		mov [rel error_status_code], 1
		jmp _exit_with_status_code
	
	.error_creating_initial_directory:
		mov rax, error_creating_initial_directory_len		
		mov rdi, 2 													; fd
		lea rsi, [rel error_creating_initial_directory]			
		call _print

		mov rax, [rel original_dst_dir_name_len]
		mov rdi, 2 										; fd of output
		mov rsi, [rel original_dst_dir_address]						; address
		call _print_with_new_line		

		mov [rel error_status_code], 1
		jmp _exit_with_status_code

	.error_creating_new_dir_and_exit:
		mov rax, error_creating_new_dir_and_exit_len		
		mov rdi, 2 													; fd
		lea rsi, [rel error_creating_new_dir_and_exit]			
		call _print

		mov rax, [rel normalized_dst_dir_name_len]
		mov rdi, 2 										; fd of output
		mov rsi, [rel normalized_dst_dir_name]						; address
		call _print_with_new_line		

		mov [rel error_status_code], 1
		jmp _exit_with_status_code



	.error_opening_directory:

		mov rax, error_opening_directory_len			; length (this is a macro)
		mov rdi, 2 										; fd
		lea rsi, [rel error_opening_directory]				; address of string itself
		call _print

		mov rax, [rel local_src_dir_name_len]
		mov rdi, 2 										; fd of output
		mov rsi, [rel local_src_dir_address]						; address
		call _print_with_new_line

		mov [rel error_status_code], 1
		ret

	.error_opening_file_one:

		mov rax, error_opening_file_len			; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_opening_file]				; address of string itself
		call _print

		mov rax, [rel fp1_name_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp1_address]						; address
		call _print_with_new_line

		mov [rel error_status_code], 1
		ret


	.error_opening_file_one_with_exit:

		mov rax, error_opening_file_len			; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_opening_file]				; address of string itself
		call _print

		mov rax, [rel fp1_name_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp1_address]						; address
		call _print_with_new_line

		mov [rel error_status_code], 1
		jmp _exit_with_status_code

	.error_creating_file_two:

		mov rax, error_creating_file_len			; length (this is a macro)
		mov rdi, 2 									; fd
		lea rsi, [rel error_creating_file] 				; address
		call _print

		mov rax, [rel fp2_name_len]						; address of input string
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp2_address]						; address
		call _print_with_new_line
		
		call _close_fd1
		mov [rel error_status_code], 1
		ret

	.error_reading_from_file:

		mov rax, error_reading_from_file_len	; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_reading_from_file] 		; address
		call _print

		mov rax, [rel fp1_name_len]
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp1_address]						; address
		call _print_with_new_line
		
		mov [rel error_status_code], 1
		ret

	.error_writing_to_file:

		mov rax, error_writing_to_file_len		; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_writing_to_file] 			; address
		call _print

		mov rax, [rel fp2_name_len]						; address of input string
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp2_address]						; address
		call _print_with_new_line

		mov [rel error_status_code], 1
		ret
		jmp .close_both_fd
	
	.error_output_is_file_input_is_dir:

		mov rax, error_output_is_file_input_is_dir0_len	; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_output_is_file_input_is_dir0] 		; address
		call _print

		mov rax, [rel original_src_dir_name_len]					
		mov rdi, 2 								; fd of output
		mov rsi, [rel original_src_dir_address]						; address
		call _print

		mov rax, error_output_is_file_input_is_dir1_len	; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_output_is_file_input_is_dir1] 		; address
		call _print

		mov rax, [rel original_dst_dir_name_len]					
		mov rdi, 2 								; fd of output
		mov rsi, [rel original_dst_dir_address]						; address
		call _print

		mov rax, error_output_is_file_input_is_dir2_len	; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_output_is_file_input_is_dir2] 		; address
		call _print_with_new_line

		mov [rel error_status_code], 1
		ret


	.error_only_dir_file_copy_supported:

		mov rax, error_only_dir_file_copy_supported0_len		; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_only_dir_file_copy_supported0] 			; address
		call _print

		mov rax, [rel fp1_name_len]						; address of input string
		mov rdi, 2 								; fd of output
		mov rsi, [rel fp1_address]						; address
		call _print

		mov rax, error_only_dir_file_copy_supported1_len		; length (this is a macro)
		mov rdi, 2 								; fd
		lea rsi, [rel error_only_dir_file_copy_supported1]				; address
		call _print_with_new_line

		mov [rel error_status_code], 1
		ret


	.close_both_fd:
		call _close_fd2
		call _close_fd1
		ret
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

	mov rax, 60
	mov rdi, [rel error_status_code]
	syscall


_exit:
	mov rax, 60
	mov rdi, 0
	syscall
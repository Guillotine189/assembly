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

	add_cwd_og_src_path_flag db 0
	add_cwd_og_dst_path_flag db 0

section .bss
	buffer resb 16384
	buffer_size equ 16384
	statBufFSrcDir resb 144				; yes it is always 144 bytes
	statBufFDstDir resb 144				; yes it is always 144 bytes
	statBufFp1 resb 144				; yes it is always 144 bytes
	statBufFp2 resb 144				; yes it is always 144 bytes

	flag_address resb 8
	flag_address_len resq 1

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

	temp_src_file_path resb 4096
	temp_src_file_name_len resq 1
	temp_dst_file_path resb 4096
	temp_dst_file_name_len resq 1

	fp1_address resb 8
	fp1_name_len resq 1
	fp1_fd resq 1
	fp2_address resb 8
	fp2_name_len resq 1
	fp2_fd resq 1

	finalFilePath_temp resb 4096

	getDentDirBuf resb 4096

	rec_src_file_path_name resb 4096
	rec_src_dst_path_name resb 4096

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
		je .handle_original_src_is_dir
		

		cmp eax, S_IFREG
		jne .print_error_only_fileDir_supported_and_exit  ; if 1st is file, still copy it

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



		.handle_original_src_is_dir:
			call .check_and_mark_if_og_src_is_absolute_path
			jmp .check_if_out_path_is_a_dir

		.check_and_mark_if_og_src_is_absolute_path:
			mov rdi, [rel original_src_dir_address]
			cmp byte [rdi], '/'
			je .absolute_src_path_passed

			.relative_src_path_passed:
				mov [rel add_cwd_og_src_path_flag], 1
				ret
			.absolute_src_path_passed:
				mov [rel add_cwd_og_src_path_flag], 0
				ret


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

				call .check_and_mark_if_og_dst_is_absolute_path
				call .normalize_file_paths_and_check_sub_dir
				call .check_if_og_dst_can_be_created
				jmp .prepare_args_call_copy_dir_function


			; dst directory exists:
			; [try to create the (og_dst+og_src_folder_name),start copying]
			.setup_and_start_copying:
				call .check_and_mark_if_og_dst_is_absolute_path
				call .normalize_file_paths_and_check_sub_dir	
				call .check_and_create_src_folder_inside_og_dst
				jmp .prepare_args_call_copy_dir_function


			.check_and_mark_if_og_dst_is_absolute_path:
			mov rdi, [rel original_dst_dir_address]
			cmp byte [rdi], '/'
			je .absolute_dst_path_passed

			.relative_dst_path_passed:
				mov [rel add_cwd_og_dst_path_flag], 1
				ret
			.absolute_dst_path_passed:
				mov [rel add_cwd_og_dst_path_flag], 0
				ret



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

			.add_cwd_og_src_file_path:
			; add csw  to src directory only if add_cwd_og_src_path_flag is 1
			cmp [rel add_cwd_og_src_path_flag], 1
			jne .add_cwd_og_dst_file_path

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
			jmp .add_cwd_og_dst_file_path


			.add_cwd_og_dst_file_path:
			
			; add csw  to dst directory only if add_cwd_og_src_path_flag is 1
			cmp [rel add_cwd_og_dst_path_flag], 1
			jne .normalize_src_dir

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



			.normalize_src_dir:

			; check if i need to use origianal src to make normalized or cwd added
			cmp [rel add_cwd_og_src_path_flag], 1
			je .use_cwd_added_to_og_src

			; else use og path to normalize
			mov rax, [rel original_src_dir_name_len]
			mov rdi, [rel original_src_dir_address]
			lea rsi, [rel normalized_src_dir_name]
			call _normalize_file_path

			cmp rax, 0
			jl .error_opening_file_one ; TODO : fix error invalid path

			mov [rel normalized_src_dir_name_len], rax
			jmp .normalize_dest_dir

			.use_cwd_added_to_og_src:
			mov rax, [rel original_src_combined_cwd_and_input_file_name_len]
			lea rdi, [rel original_src_combined_cwd_and_input_file_name]
			lea rsi, [rel normalized_src_dir_name]
			call _normalize_file_path
			cmp rax, 0
			jl .error_opening_file_one ; TODO : fix error invalid path
			mov [rel normalized_src_dir_name_len], rax


			.normalize_dest_dir:

			; check if i have to og filepath or cwd+og
			cmp [rel add_cwd_og_dst_path_flag], 1
			je .use_cwd_added_to_og_dst

			; else use og path to normalize
			mov rax, [rel original_dst_dir_name_len]
			mov rdi, [rel original_dst_dir_address]
			lea rsi, [rel normalized_dst_dir_name]
			call _normalize_file_path
			cmp rax, 0
			jl .error_opening_file_one ; TODO : fix error invalid path
			mov [rel normalized_dst_dir_name_len], rax
			jmp .check_subdir

			.use_cwd_added_to_og_dst:
			mov rax, [rel original_dst_combined_cwd_and_output_file_name_len]
			lea rdi, [rel original_dst_combined_cwd_and_output_file_name]
			lea rsi, [rel normalized_dst_dir_name]
			call _normalize_file_path

			mov [rel normalized_dst_dir_name_len], rax
			; TODO : fix error invalid path, same a sabove

			.check_subdir:
			; check_output_dir_not_a_sub_dir
			lea rdi, [rel normalized_src_dir_name]
			lea rsi, [rel normalized_dst_dir_name]
			call _check_fp2_is_sub_dir_fp1


			cmp rax, 0
			je .error_fp2_is_sub_dir_fp1_and_exit
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
			; /home/sarthak/dst_folder_that_already_exists/src_folder\0_
			; |a 													   |rax
			lea rcx, [rel normalized_dst_dir_name] 				; a
			sub rax, rcx
			sub rax, 1
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

			.before_call:

			call .start_copying_dir
			call _exit


	; STACK after init adds
	; rsp->0x1	|		local_dst_dir_name_length		| -> -40 bytes
	; 			|		local_src_dir_name_length  		| -> -32 bytes
	; 			|		total_size_sys_getdents64 		| -> -24 bytes
	; 			|		offset_for_getdents64 			| -> -16 bytes
	; 			|				fd  					| -> -8 bytes
	; 	rbp->	| 			old rbp x100 				| -> +0 bytes -> current rbp

	;function_receives
	; 		    | 			return address 				| -> +8 bytes
	;  			|     	actual_sys_getdents64_data		| -> +16 bytes
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

		.init:
		push rbp
		mov rbp, rsp
		
		mov [rel local_src_dir_name_len], rdx
		mov [rel local_dst_dir_name_len], rcx

		mov r8, rsi
		lea r9, [rbp + 16 + r8]
		mov [rel local_src_dir_address], r9

		add r8, rdx 					
		inc r8

		lea r9, [rbp + 16 + r8]
		mov [rel local_dst_dir_address], r9

		push rax
		push rdi
		push rsi
		push rdx
		push rcx

		; now i am free to use alll 5 registers

		.outer_loop:

		mov rax, [rbp - 16]
		cmp rax, [rbp - 24]

		je .get_more_data_for_dir
		jne .prepare_inner_loop

		.get_more_data_for_dir:
			mov rax, 217 					; sys_getdents64 syscall
			mov rdi, [rbp - 8]				; fd
			lea rsi, [rbp + 16] 			; move data to directly inside stack
			mov rdx, [rbp - 24]				; how much bytes to write
			syscall

			cmp rax, 0
			jl .print_error_opening_dir_and_move_out_of_directory
			jz .move_out_of_directory



		.prepare_inner_loop:
		; for this directory, innerloop expects
		; rax = size of getdent
		; r8 = offset for getdent

		mov r8, [rbp - 16]
		mov rax, [rbp - 24]

		.inner_loop:


			; check if next segment is available
			cmp r8, rax

			je .save_register_go_outer_loop
			jne .read_filetype

			.save_register_go_outer_loop:
				mov [rbp - 16], r8
				mov [rbp - 24], rax
				jmp .outer_loop


			.read_filetype:
			lea rdx, [rbp + 16] 						; address of getdentbuffer
			mov cl, [rdx + r8 + 18] 					; file type
			
			cmp cl, DT_DIR
			je .check_if_not_dots
			je .loopback
			
			cmp cl, DT_REG
			je .is_a_file

			; todo : give proper file name
			call .error_only_dir_file_copy_supported 		; not a dir, or file
			jmp .loopback 				; if not file/dir skip

			.check_if_not_dots:

			mov [rbp - 16], r8
			mov [rbp - 24], rax

			add rdx, r8
			add rdx, 19 			; addres of file name

			mov rax, 2 				; compare '.\0', thats why 2
			mov rdi, rdx
			lea rsi, [rel dot_file]
			call _cmp_equal_memory
			cmp rax, 0
			je .ignore_and_go_loop_again

			mov r8, [rbp - 16] 				; restore r8			

			.check_check:

			mov rax, 3 						; compare '..\0', thats why 3
			lea rdi, [rbp + 16] 						; address of getdentbuffer
			add rdi, r8
			add rdi, 19 					 			; addres of file name
			lea rsi, [rel double_dot_file]
			call _cmp_equal_memory
			cmp rax, 0
			je .ignore_and_go_loop_again

			jmp .handle_directory

			.ignore_and_go_loop_again:
				
				mov r8, [rbp - 16]
				mov rax, [rbp - 24]
				jmp .loopback
			
			.handle_directory:
				mov r8, [rbp - 16]
				mov rax, [rbp - 24]
				jmp .move_into_directory


		.is_a_file:

			; caluculate the size of file_name
			; first: get segment size : from d_reclen located at 16bytes
			; file size = [segment size - 19bytes - padding by compiler]

			lea rdx, [rbp + 16 + r8] 				; address of current segment
			movzx r9, word [rdx + 16] 			; 2bytes contain the segments size

			lea rdi, [rbp + 16]						; getdent buffer address
			add rdi, r8
			add rdi, 19 							; address of file_name
			xor r10, r10

		.count_loop:
			cmp [rdi + r10], 0
			je .done

			inc r10
			jmp .count_loop

		.done:
			; 	now r10 has the file_name size

			; 1)move into rec_src_file_path_name the directory name + '/'
			; 2)add the file name to rec_src_file_path_name
			; 3)value in fp1_address equals to address of rec_src_file_path_name

			mov [rbp - 16], r8
			mov [rbp - 24], rax
			push r10

			mov rax, [rbp - 32] 					; len of src_folder
			lea rdi, [rel rec_src_file_path_name]
			mov rsi, [rbp - 24] 				; size of getdent
			lea rsi, [rbp + 16 + rsi] 			; address of src 
			mov r8, 1
			mov rdx, '/'
			call _memcpy_with_end_char			; rax has address of next location
			pop r10
			mov r8, [rbp - 16]					; pop r8

			;mov rax, [rbp - 24]

			.check:
			;mov [rbp - 16], r8 						; push r8

			;2)
			mov rdi, rax
			mov rax, r10
			lea rsi, [rbp + 16] 				; addres of getdentbuf
			add rsi, r8
			add rsi, 19 						; idk why but at 18 you get file name
			mov r8, 1
			mov rdx, 0
			call _memcpy_with_end_char			; rax has address of next location

			.check2:

			; fp1_address
			lea rdx, [rel rec_src_file_path_name]
			mov [rel fp1_address], rdx

			; fp1 -> address ->  /home/current_folder/file_to_be_copied

			; 3)  TODO: subtract addres to find length , better way
			lea rdi, [rel rec_src_file_path_name]
			call _strlen
			; rax now has file of path

			; fp1_name_len
			mov [rel fp1_name_len], rax


			; fp2_address
			mov rdx, [rbp - 24] 				; size of getdent
			add rdx, [rbp - 32] 				; size of local_src_dir_name
			inc rdx 							; bec len does not iclude \0
			lea rdx, [rbp + 16 + rdx] 			; address of local_dst_dir_name
			mov [rel fp2_address], rdx

			; fp2 -> address -> /home/some_other_directory

			; fp2_name_len
			mov rdx, [rbp - 40]  				; local_dst_name_len
			mov [rel fp2_name_len], rdx

			.final_check:

			call .copy_file1_to_path

			mov r8, [rbp - 16]
			mov rax, [rbp - 24]
			
		.loopback:

			lea rsi, [rbp + 16]					; address getdentbuffer
			add rsi, r8
			add rsi, 16
			movzx ecx, word [rsi]
			add r8, rcx

			jmp .inner_loop


		.move_into_directory:


	; STACK after init adds
	; 			|		local_dst_dir_name_length		| -> -40 bytes
	; 			|		local_src_dir_name_length  		| -> -32 bytes
	; rsp->0x1	|		total_size_sys_getdents64 		| -> -24 bytes
	; 			|		offset_for_getdents64 			| -> -16 bytes
	; 			|				fd  					| -> -8 bytes
	; 	rbp->	| 			old rbp x100 				| -> +0 bytes -> current rbp

	; 		    | 			return address 				| -> +8 bytes
	;  			|     	actual_sys_getdents64_data		| -> +16 bytes
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


			; use temp_src_file_path as a temp buffer to create new dir name
			; then push that name into stack as src_dir_name_ending_with_'\0'

			; the dir name in inside getident buffer

			.create_sub_dir_src_name:

			; add the current dir name into temp_src_file_path

			mov rax, [rbp - 32] 				; len of local_src_dir_len
			lea rdi, [rel temp_src_file_path] 	; dest address
			mov rsi, [rbp - 24] 				; size of getdent
			lea rsi, [rbp + 16 + rsi] 			; address of src 
			mov dl, '/'
			mov r8, 1 							; append '/'
			call _memcpy_with_end_char

			push rax 							; temp storing the address of next byte
			mov r8, [rbp - 16] 					; load r8

			lea rdi, [rbp + 16] 				; addres of getdentbuf
			add rdi, r8
			add rdi, 19 						; address where dir_name_lives 
			call _strlen 						; rax has dir_name_len

			; rax has length
			pop rdi
			lea rsi, [rbp + 16] 				; addres of getdentbuf
			add rsi, r8
			add rsi, 19 						; address where dir_name_lives 
			mov dl, 0
			mov r8, 1
			call _memcpy_with_end_char

			lea rcx, [rel temp_src_file_path]
			sub rax, rcx
			sub rax, 1 								; rax has sub_dir_name_len
			mov [rel temp_src_file_name_len], rax

			mov r8, [rbp - 16] 					; load r8

			; create sub_dir_dst_name

			mov rax, [rbp - 40] 				; len of local_src_dir_len
			lea rdi, [rel temp_dst_file_path] 	; dest address
			mov rsi, [rbp - 24] 				; size of getdent
			add rsi, [rbp - 32] 				; size of local_src_dir_name
			inc rsi 							; bec len does not include \0
			lea rsi, [rbp + 16 + rsi] 			; address of local_dst_dir_name
			mov dl, '/'
			mov r8, 1 							; append '/'
			call _memcpy_with_end_char

			push rax 							; temp storing the address of next byte
			mov r8, [rbp - 16] 					; load r8

			; TODO: not good, why find length of new_dir_name again
			lea rdi, [rbp + 16] 				; addres of getdentbuf
			add rdi, r8
			add rdi, 19 						; address where dir_name_lives 
			call _strlen 						; rax has dir_name_len

			; rax has length
			pop rdi
			lea rsi, [rbp + 16] 				; addres of getdentbuf
			add rsi, r8
			add rsi, 19 						; address where dir_name_lives 
			mov dl, 0
			mov r8, 1
			call _memcpy_with_end_char

			lea rcx, [rel temp_dst_file_path]
			sub rax, rcx
			sub rax, 1 								; rax has sub_dir_name_len
			mov [rel temp_dst_file_name_len], rax

			mov r8, [rbp - 16] 					; load r8

			; make dst ls dir

			mov rax, 83          ; sys_mkdir
		    lea rdi, [rel temp_dst_file_path]     ; pathname
		    mov rsi, 0755o       ; permissions
		    syscall

		    cmp rax, 0
		    jl .loopback 
		    jmp .open_temp_src

		    call .error_creating_initial_directory  
		    ; Todo: print error then loop back
		    ; TODO: fix which directory is shown in error
		    ; todo: this error exit after printting fix that


			.open_temp_src:

			mov rax, 2
			lea rdi, [rel temp_src_file_path]
			mov rsi, 0 							; read only for src
			syscall

			cmp rax, 0
			jl .cannot_open_temp_initial_src_dir_exit ; TODO: give proper file name

			mov r12, rax 					; r12 fd in callee register safe

			jmp .getdent_init_src_temp_dir

			.cannot_open_temp_initial_src_dir_exit:
				call .error_opening_directory   ;TODO: fix display proper file	
				call _exit_with_status_code

			.getdent_init_src_temp_dir:

			mov rax, 217 					; sys_getdents64 syscall
			mov rdi, r12						; fd
			lea rsi, [rel getDentDirBuf] 	; buffer
			mov rdx, 4096					; how much bytes to write
			syscall

			cmp rax, 0
			jl .cannot_open_initial_src_dir_exit   ; TODO: maybe give proper error

			mov r13, rax 				; r13: size of getdent in callee register safe

			.prepare_stack2:

			; find how much space to need in stack
			mov r10, r13 							; size of get_dent_data			
			add r10, [rel temp_src_file_name_len]	; add len of src_file_name
			inc r10									; add space for '\0'
			add r10, [rel temp_dst_file_name_len] ; add len of dst_file_name
			inc r10									; add space for '\0'

			; reserve stack space
			sub rsp, r10

			.check_stack2:

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
			mov rax, [rel temp_src_file_name_len]
			lea rsi, [rel temp_src_file_path]
			mov dl, 0
			mov r8, 1
			call _memcpy_with_end_char
			;mov rsp, rax 								; move rsp forward

			; add the dst file name
			mov rdi, rax
			mov rax, [rel temp_dst_file_name_len]
			lea rsi, [rel temp_dst_file_path]
			mov dl, 0
			mov r8, 1
			call _memcpy_with_end_char

			.prepare_registers2:

			mov rsi, r13 								; rsi size of getdent_returned
			mov rax, r12 								; rax has fd
			mov rdi, 0 									; offset for getdent, init: 0
			mov rdx, [rel temp_src_file_name_len]
			mov rcx, [rel temp_dst_file_name_len]

			.before_call_recursive2:

			call .start_copying_dir
			

			; after the recursion call make sure to hve these variables back
			; r8, rax need to be restored as well

			mov r8, [rbp - 16] 					; load r8
			mov rax, [rbp - 24] 				; load rax

			jmp .loopback


		.move_out_of_directory:

			;[ VERY IMPORTANT line]
			mov rsp, rbp
			pop rbp
			ret

			call _exit  					; TODO: remove this later, rn placeholder


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
	je .dont_add_slash			; if the end of filepath2 is /

	mov dl, '/'									; when memcpy called, it will append 
	mov r8b, 1 									; set flag to apppend anything 			
	jmp .copy_dest_address_to_final_path


	.dont_add_slash:
		mov r8b, 0

	
	.copy_dest_address_to_final_path:
		lea rdi, [rel finalFilePath_temp]
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
		mov rdi, finalFilePath_temp					; address of filepath
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

	.error_fp2_is_sub_dir_fp1_and_exit:
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
%include "./dep/constants.inc"
%include "../dependencies/mystring.inc"
%include "../dependencies/dynamicarray.inc"

section .data
	path_address dq 0
	last_path_flag dq 0


section .rodata	
	error_path_env_not_found db "Error: 'PATH; env variable not present.", 0
	error_path_env_not_found_len equ $ - error_path_env_not_found

	dot db ".",0
	back_slash db "/"
	dot_back_slash db "./", 0
	dash db '-',0
	path_env_var db "PATH", 0


global shell_env_array_object
section .bss
	reusable_buffer_path resb 4096
	struct_for_stat resb 144
	number_buffer resb 32
	shell_env_array_object resb DYNAMICARRAY_OBJECT_SIZE

; funcs
extern _print
extern _print_with_new_line
extern _string_copy_including_null
extern _print_error_with_new_line
extern _strcmp
extern _cmp_equal_memory
extern _strlen
extern _mem_copy
extern _memcpy_with_end_char
extern _itoa

extern _default_dynamic_array_constructor
extern _default_dynamic_array_destructor
extern _dynamic_array_add_element
extern _dynamic_array_remove_element

extern _constructor_mystring
extern _destructor_mystring
extern _append_string_mystring
extern _mystring_clear

extern _malloc
extern _free


; vars
extern og_envp_stack_array_address
extern error_code
extern exit_status_code
extern curr_cwd
extern curr_cwd_len
extern old_cwd
extern old_cwd_len

extern address_argc_address_array
extern address_command
extern total_command_aruments

extern _exit
extern _exit_with_status_code


section .text

global _initialize_shell_env_array
global _check_if_cmd_is_in_path
global _find_var_in_shell_env
global _update_var_in_shell_env
global _unset_var_in_shell_env


global shell_env_array_object


; shell_env_array [ENV_STUCT, ENV_STRUCT]
; env_struct -> [string_object / 24bytes][exported or not / 8 bytes]
; string object -> [capacity / 8bytes][size / 8bytes][pointer / 8bytes]
; pointer -> The actual env string

; env_struct
; [String object] 24bytes  
; [exported or not] 8bytes, 0/1 -> 0: not exported, 1: exported
; total = 32bytes
; i will add env_struct to 

ENV_STRUCT_STRING_OBJ_OFF equ 0
ENV_STRUCT_EXPORTED_OFF equ MYSTRING_OBJECT_SIZE
ENV_STRUCT_SIZE equ MYSTRING_OBJECT_SIZE + 8


; REMEMBER: the array does not own the ENV_STRUCT
; so if you have to delete a ENV_STRUCT, make sure to free the string


; at start, og_envp_stack_array_address was initialized.
_initialize_shell_env_array:
	push rbp
	mov rbp, rsp
	push r12

	.get_a_lot_of_heap_memory:
		mov rdi, 16384  					; 16kb
		call _malloc

		test rax, rax
		jl .error_getting_heap_memory

		; immediately free this so i can use this chunk of memory
		; _free does not give the memory back to os, it keeps it
		mov rdi, rax
		call _free


	.create_array_env:
		lea rax, [rel shell_env_array_object]
		mov qword [rax + DYNAMICARRAY_CAPACITY_OFF], 40
		mov qword [rax + DYNAMICARRAY_SIZE_OFF], 0
		mov qword [rax + DYNAMICARRAY_ELEMENT_SIZE_OFF], ENV_STRUCT_SIZE
		mov qword [rax + DYNAMICARRAY_POINTER_OFF], 0
		mov rdi, rax
		call _default_dynamic_array_constructor

		test rax, rax
		jl .error_creating_array

	xor r12, r12 					; index fow which env var to copy

	.loop_populate_env_struct:

		mov rax, [rel og_envp_stack_array_address]
		mov rcx, r12
		shl rcx, 3
		add rax, rcx
		cmp qword [rax], 0
		je .done_populating

	.create_env_struct_object:
		sub rsp, ENV_STRUCT_SIZE
		; create string object
		mov qword [rsp + MYSTRING_CAPACITY_OFF], 24   ; assign 24 for each env var
		mov qword [rsp + MYSTRING_SIZE_OFF], 0
		mov qword [rsp + MYSTRING_POINTER_OFF], 0
		mov rdi, rsp
		call _constructor_mystring
		
		test rax, rax
		jl .error_creating_string_object

	.add_env_var_to_string:
		mov rax, [rel og_envp_stack_array_address]
		mov rcx, r12
		shl rcx, 3
		add rax, rcx
		mov rax, [rax] 					; the actual adddress of env variable

		mov rdi, rsp
		mov rsi, rax
		call _append_string_mystring

		test rax, rax
		jl .error_appending_to_string

	.set_exported_to_true:
		mov rax, rsp
		add rax, ENV_STRUCT_EXPORTED_OFF
		mov qword [rax], 1

	.add_env_struct_to_array:

		lea rdi, [rel shell_env_array_object]
		mov rsi, rsp
		call _dynamic_array_add_element

		test rax, rax
		jl .error_adding_env_struct

	.remove_string_object_from_stack:
		add rsp, ENV_STRUCT_SIZE

	.loopback:
		inc r12
		jmp .loop_populate_env_struct

	.done_populating:
		;call _print_env
		pop r12
		mov rsp, rbp
		pop rbp
		ret

	.error_adding_env_struct:
	.error_getting_heap_memory:
	.error_appending_to_string:
	.error_creating_string_object:
	.error_creating_array:
		; TODO: print proper errors
		mov [rel exit_status_code], rax
		call _exit_with_status_code




_print_shell_env:
	push rbp
	mov rbp, rsp

	push r12

	mov r12, 0
	mov r8, 1

	.loop_print_env_struct:
	lea r9, [rel shell_env_array_object]

	cmp r8, [r9 + DYNAMICARRAY_SIZE_OFF]
	jg .done

	push r8
	mov r9, [r9 + DYNAMICARRAY_POINTER_OFF]

	mov rax, r12
	mov rcx, ENV_STRUCT_SIZE
	mul rcx
	; rax has the offset for next env struct
	lea rax, [r9 + rax] 		; now rax points to the next env struct
	
	lea rcx, [rax + ENV_STRUCT_STRING_OBJ_OFF]

	mov rax, [rcx + MYSTRING_SIZE_OFF] 				; r14 has string size
	mov rsi, [rcx + MYSTRING_POINTER_OFF] 			; r13 has the actual string
	mov rdi, 1
	call _print_with_new_line

	pop r8
	inc r12
	inc r8

	jmp .loop_print_env_struct

	.done:
	pop r12
	mov rsp, rbp
	pop rbp
	ret


; rdi: address of the variable to check if it's in env or not
; rsi: len of the varible
; returns rax : address of env path variable if it exists
; 		      : -ve number on failure
; CHECKS the my shell_env weather the env variable exists or not

_find_var_in_shell_env:
	test rsi, rsi
	je .path_not_found

	xor r8 ,r8 							; this will store which env var i am checking

	.check_next_env_var:
		lea rax, [rel shell_env_array_object]

		cmp r8, [rax + DYNAMICARRAY_SIZE_OFF]
		je .path_not_found

		mov r9, [rax + DYNAMICARRAY_POINTER_OFF]

		mov rax, r8
		mov rcx, ENV_STRUCT_SIZE
		mul rcx
		; rax has the offset for next env struct
		lea rax, [r9 + rax] 		; now rax points to the next env struct
		
		lea rcx, [rax + ENV_STRUCT_STRING_OBJ_OFF]
		mov rcx, [rcx + MYSTRING_POINTER_OFF]  ; rax pointing to the actual string
		
		xor r9, r9 				; idx for going over the env var
	.check_this_address:

		cmp r9, rsi    			; r9 is index, rsi is length.
		je .check_if_env_name_ends_here

		mov al, byte [rcx + r9] 		; "PATH=usr/:"
		cmp byte [rdi + r9], al    ; compare byte of asking variable with current envp var
		jne .check_next_var

		inc r9
		jmp .check_this_address


	.check_next_var:
		inc r8
		jmp .check_next_env_var

	.check_if_env_name_ends_here:
		cmp byte [rcx + r9], '=' 		; if the next byte in my og_env_var is '=' 
		je .path_found

		jmp .check_next_var


	.path_found:
		mov rax, rcx
		add rax, rsi
		inc rax   ; if "PATH" was searched, i return "/bin/usr", not "PATH=/bin/usr"
		ret

	.path_not_found:
		mov rax, -1
		ret



; rules for env variables
; FOO=BAR
; FOO is of pattern [a-z A-Z _] [a-z A-Z 0-9 _]
; BAR is of pattern anything but null

; rdi: address of the variable to check and replace/add
; returns rax : address of env path variable if it exists
; 		      : -ve number on failure
; CHECKS the my shell_env weather the env variable exists or not
; if it exists, it will copy the path thats in rsi
; if not, it creates a new env var struct, marks it non exported and copied value from rsi

_update_var_in_shell_env:
	push rbp
	mov rbp, rsp
	push r12

	mov r12, rdi

	mov r10, rdi
	mov al, [r10]

	cmp al, '_'
	je .first_key_char_valid

	cmp al, 'A'
	jb .invaid_key

	cmp al, 'Z'
	jbe .first_key_char_valid

	cmp al, 'a'
	jb .invaid_key

	cmp al, 'z'
	jbe .first_key_char_valid

	
	jmp .invaid_key

	.first_key_char_valid:
		; now i have to  check the rest of the key
		inc r10
	.loop_check_key:

		mov al, [r10]

		cmp al, '='
		je .valid_key

		cmp al, '_'
		je .valid_key_byte

		cmp al, '0'
		jb .invaid_key

		cmp al, '9'
		jbe .valid_key_byte

		cmp al, 'A'
		jb .invaid_key

		cmp al, 'Z'
		jbe .valid_key_byte

		cmp al, 'a'
		jb .invaid_key

		cmp al, 'z'
		jbe .valid_key_byte
		
		jmp .invaid_key

		.valid_key_byte:
			inc r10
			jmp .loop_check_key

	.valid_key:
	; r10 points the '='
	; rdi points to starting of new still
	mov rsi, r10
	sub rsi, rdi   						; rsi is len of key

	xor r8 ,r8 							; this will store which env var i am checking

	.check_next_env_var:
		lea rax, [rel shell_env_array_object]

		cmp r8, [rax + DYNAMICARRAY_SIZE_OFF]
		je .key_not_found

		mov r9, [rax + DYNAMICARRAY_POINTER_OFF]

		mov rax, r8
		mov rcx, ENV_STRUCT_SIZE
		mul rcx
		; rax has the offset for next env struct
		lea rax, [r9 + rax] 		; now rax points to the next env struct
		
		lea rdx, [rax + ENV_STRUCT_STRING_OBJ_OFF]
		mov rcx, [rdx + MYSTRING_POINTER_OFF]  ; rax pointing to the actual string
		
		xor r9, r9 				; idx for going over the env var
	.check_this_address:

		cmp r9, rsi    			; r9 is index, rsi is length.
		je .check_if_env_name_ends_here

		mov al, byte [rcx + r9] 		; "PATH=usr/:"
		cmp byte [rdi + r9], al    ; compare byte of asking variable with current envp var
		jne .check_next_var

		inc r9
		jmp .check_this_address


	.check_next_var:
		inc r8
		jmp .check_next_env_var

	.check_if_env_name_ends_here:
		cmp byte [rcx + r9], '=' 		; if the next byte in my og_env_var is '=' 
		je .key_found

		jmp .check_next_var


	.key_found:
		; rdx points to the string object of the env struct which stores that env string
		push rdx
		mov rdi, rdx
		call _mystring_clear
		pop rdx

		mov rdi, rdx
		mov rsi, r12
		call _append_string_mystring

		test rax, rax
		jl .error_updating_env_variable

		xor rax, rax
		jmp .return_success

	.key_not_found:
		; create a new env struct, add it to array, mark it non exported

		; create a env object -> string object + 8 bytes
		call _strlen    

		sub rsp, ENV_STRUCT_SIZE
		lea rcx, [rsp + ENV_STRUCT_STRING_OBJ_OFF]
		mov qword [rcx + MYSTRING_CAPACITY_OFF], rax   ; capacity = len of env var
		mov qword [rcx + MYSTRING_SIZE_OFF], 0
		mov qword [rcx + MYSTRING_POINTER_OFF], 0
		mov rdi, rcx
		call _constructor_mystring

		test rax, rax
		jl .error_creating_string_object

		; add new env variable 
		lea rdi, [rsp + ENV_STRUCT_STRING_OBJ_OFF]
		mov rsi, r12
		call _append_string_mystring

		lea rcx, [rsp + ENV_STRUCT_EXPORTED_OFF]
		mov qword [rcx], 1 							; marking this as exported

		; add env object to shell_env_array

		lea rdi, [rel shell_env_array_object]
		mov rsi, rsp
		call _dynamic_array_add_element


		test rax, rax
		jl .error_adding_env_struct

		; remove object from tsack
		add rsp, ENV_STRUCT_SIZE

		xor rax, rax
		jmp .return_success


	.error_adding_env_struct:
		;cleanup up the string object
		mov rdi, rsp
		call _destructor_mystring

	.error_creating_string_object:	
		sub rsp, ENV_STRUCT_SIZE

	.invaid_key:
	.error_updating_env_variable:
		jmp .return_failure



	.return_failure:
		mov rax, -1
		pop r12
		mov rsp, rbp
		pop rbp
		ret
	.return_success:
		xor rax, rax
		pop r12
		mov rsp, rbp
		pop rbp
		ret


; rdi: address of the key part of variable
_unset_var_in_shell_env:

	mov r10, rdi
	mov al, [r10]

	cmp al, '_'
	je .first_key_char_valid

	cmp al, 'A'
	jb .invaid_key

	cmp al, 'Z'
	jbe .first_key_char_valid

	cmp al, 'a'
	jb .invaid_key

	cmp al, 'z'
	jbe .first_key_char_valid

	
	jmp .invaid_key

	.first_key_char_valid:
		; now i have to  check the rest of the key
		inc r10
	.loop_check_key:

		mov al, [r10]

		cmp al, '_'
		je .valid_key_byte

		cmp al, '0'
		jb .check_key

		cmp al, '9'
		jbe .valid_key_byte

		cmp al, 'A'
		jb .check_key

		cmp al, 'Z'
		jbe .valid_key_byte

		cmp al, 'a'
		jb .check_key

		cmp al, 'z'
		jbe .valid_key_byte
		
		jmp .check_key

		.valid_key_byte:
			inc r10
			jmp .loop_check_key

	.check_key:
	; r10 points the '='
	; rdi points to starting of new still
	mov rsi, r10
	sub rsi, rdi   						; rsi is len of key

	xor r8 ,r8 							; this will store which env var i am checking

	.check_next_env_var:
		lea rax, [rel shell_env_array_object]

		cmp r8, [rax + DYNAMICARRAY_SIZE_OFF]
		je .key_not_found

		mov r9, [rax + DYNAMICARRAY_POINTER_OFF]

		mov rax, r8
		mov rcx, ENV_STRUCT_SIZE
		mul rcx
		; rax has the offset for next env struct
		lea rax, [r9 + rax] 		; now rax points to the next env struct
		
		lea rdx, [rax + ENV_STRUCT_STRING_OBJ_OFF]
		mov rcx, [rdx + MYSTRING_POINTER_OFF]  ; rax pointing to the actual string
		
		xor r9, r9 				; idx for going over the env var
	.check_this_address:

		cmp r9, rsi    			; r9 is index, rsi is length.
		je .check_if_env_name_ends_here

		mov al, byte [rcx + r9] 		; "PATH=usr/:"
		cmp byte [rdi + r9], al    ; compare byte of asking variable with current envp var
		jne .check_next_var

		inc r9
		jmp .check_this_address


	.check_next_var:
		inc r8
		jmp .check_next_env_var

	.check_if_env_name_ends_here:
		cmp byte [rcx + r9], '=' 		; if the next byte in my og_env_var is '=' 
		je .key_found

		jmp .check_next_var


	.key_found:
		; rdx points to the string object element
		push r8        ; r8 stores the index which needs to be removed in array

		mov rdi, rdx
		call _destructor_mystring

		; now move the structs right to the current one to 
		lea rdi, [rel shell_env_array_object]
		pop rsi   						; the index of which element i want removed
		call _dynamic_array_remove_element

	.key_not_found:
	.invaid_key:
		ret




; returns address in rax, if exists or -1 if not
_check_if_cmd_is_in_path:
	
	; TODO: change this so i can check the env variables for individual commands
	; Rn i am checking from the original list on env var.

	lea rdi, [rel path_env_var]
	mov rsi, 4
	call _find_var_in_shell_env

	test rax, rax
	jl .error_path_env_not_found

	mov [rel path_address], rax
	call _parse_path_and_check_if_command_in_path

	test rax, rax
	jl .not_inside_path

	; rax already has address
	jmp .inside_path

	.error_path_env_not_found:
		mov rax, error_path_env_not_found_len
		mov rdi, 1
		lea rsi, [rel error_path_env_not_found]
		call _print_with_new_line

		jmp .not_inside_path


	.not_inside_path:
		mov rax, -1
		ret

	.inside_path:
		ret


; returns: rax : -1 -> if not exists, address of constructed path if exists
_parse_path_and_check_if_command_in_path:

	mov rax, [rel path_address]
	add rax, 5 							; 'PATH=' skipped

	mov r12, 5 					; idx for starting of new path 
	mov r13, 5 					; idx for total looping inside path var

	mov qword [rel last_path_flag], 0

	.loop_init:
		mov rax, [rel path_address]

	.loop_find_semi_colon_or_end:

		cmp byte [rax + r13], ':'
		je .end_of_path_found

		cmp byte [rax + r13], 0
		je .last_path

		inc r13
		jmp .loop_find_semi_colon_or_end

	.last_path:
		mov qword [rel last_path_flag], 1

	; r12 is start of path
	; r13 is at end of path + 1
	.end_of_path_found: 
		dec r13 					; r13 at end of path

		; two cases when to use curr dir as base path
		; 1) case when empty env variable,  "::", nothing in between semi-colons
		; 2) case when variable is ":.:", a dot in between 2 semi-colons

		;case 1
		cmp r13, r12
		je .add_current_dir 				; len = 0, add curr dir

		; case2
		mov rax, 13
		sub rax, r12
		inc rax

		cmp rax, 1
		jne .add_env_path 					; len not 1, add regular path

		cmp byte [rax], '.'
		je .add_current_dir 	; if len = 1, and path is '.' -> add curr working

		
		jmp .add_env_path

		.add_current_dir:
		mov rax, r13
		sub rax, r12  			
		inc rax  					; bec r12 r13 are 0 indexed, inc 1 for lenght
		lea rdi, [rel reusable_buffer_path]
		lea rsi, [rel curr_cwd]
		add rsi, r12
		mov rdx, '/'
		mov r8, 1
		call _memcpy_with_end_char 				; rax has address of next byte
		push rax
		jmp .add_command

		.add_env_path:
		mov rax, r13
		sub rax, r12  			
		inc rax  					; bec r12 r13 are 0 indexed, inc 1 for lenght
		lea rdi, [rel reusable_buffer_path]
		mov rsi, [rel path_address]
		add rsi, r12
		mov rdx, '/'
		mov r8, 1
		call _memcpy_with_end_char 				; rax has address of next byte
		push rax

		.add_command:
		mov rdi, [rel address_command]
		call _strlen
		pop rdi
		mov rsi, [rel address_command]
		mov rdx, 0
		mov r8, 1
		call _memcpy_with_end_char 
		; now i have constructed '/path/commandNULL'

		; find if this file exists

		mov rax, sys_stat
		lea rdi, [rel reusable_buffer_path]
		lea rsi, [rel struct_for_stat]
		syscall

		test rax, rax 						; if file doesn't exists, check next path
		jl .check_next_path
		jmp .in_path



	.check_next_path:
		cmp qword [rel last_path_flag], 1
		je .not_in_path

		add r13, 2
		mov r12, r13
		jmp .loop_init


	.not_in_path:
		mov rax, -1
		ret

	.in_path:
		lea rax, [rel reusable_buffer_path]
		ret

global error_code
section .data
    error_input_init_memory db "myShell: Error allocating memory for input buffer",0
    error_input_init_memory_len equ $ - error_input_init_memory

    error_getting_parse_memory db "myShell: Error getting memory for parse line", 0
    error_getting_parse_memory_len equ $ - error_getting_parse_memory

    error_reading_input db "myShell: Error reading input", 0
    error_reading_input_len equ $ - error_reading_input

    error_increasing_input_buffer_mem db "myShell: Error increasing input buffer storage", 0
    error_increasing_input_buffer_mem_len equ $ - error_increasing_input_buffer_mem

    error_overriding_custom_handler db "myShell: Error overriding custom handler: ", 0
    error_overriding_custom_handler_len equ $ - error_overriding_custom_handler

    error_setting_non_con_mode db "Error setting mode to non canonical", 0
    error_setting_non_con_mode_len equ $ - error_setting_non_con_mode

    error_getting_cwd db "myShell: Error getting cwd",0
    error_getting_cwd_len equ $ - error_getting_cwd

    error_forking db "myShell: Error forking",0
    error_forking_len equ $ - error_forking

    error_executing_process db "myShell: Error executing: ", 0
    error_executing_process_len equ $ - error_executing_process
    error_code dq 0


extern _print
extern _print_with_new_line
extern _print_error_with_new_line
extern _itoa
extern _strlen

extern error_custom_handler_number
extern reusable_buffer
extern address_command


section .text

global print_error_input_init_memory
global print_error_reading_input
global print_error_increasing_input_mem
global print_error_getting_parse_memory
global print_error_getting_cwd
global print_error_overriding_custom_handler
global print_error_forking
global print_error_executing_process
global print_error_setting_non_con_mode


print_error_input_init_memory:
    mov rax, error_input_init_memory_len
    mov rdi, 1
    lea rsi, [rel error_input_init_memory]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_reading_input:
    mov rax, error_reading_input_len
    mov rdi, 1
    lea rsi, [rel error_reading_input]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_getting_parse_memory:
    mov rax, error_getting_parse_memory_len
    mov rdi, 1
    lea rsi, [rel error_getting_parse_memory]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_increasing_input_mem:
    mov rax, error_increasing_input_buffer_mem_len    
    mov rdi, 1
    lea rsi , [rel error_increasing_input_buffer_mem]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_overriding_custom_handler:
    mov rax, error_overriding_custom_handler_len
    mov rdi, 1
    lea rsi , [rel error_overriding_custom_handler]
    call _print

    mov rax, [rel error_custom_handler_number]
    lea rdi, [rel reusable_buffer]
    call _itoa                          ; rax has len of number in bytes

    mov rdi, 1
    lea rsi, [rel reusable_buffer]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_setting_non_con_mode:
    mov rax, error_setting_non_con_mode_len
    mov rdi, 1
    lea rsi , [rel error_setting_non_con_mode]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret



print_error_getting_cwd:
    mov rax, error_getting_cwd_len
    mov rdi, 1
    lea rsi , [rel error_getting_cwd]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_forking:
    mov rax, error_forking_len
    mov rdi, 1
    lea rsi , [rel error_forking]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_executing_process:
    mov rax, error_executing_process_len
    mov rdi, 1
    lea rsi , [rel error_executing_process]
    call _print


    mov rdi, [rel address_command]
    call _strlen
    
    mov rdi, 1
    mov rsi, [rel address_command]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

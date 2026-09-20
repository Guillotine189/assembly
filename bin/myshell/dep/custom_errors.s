global error_code

section .data
    error_code dq 0
    
section .rodata
    error_input_init_memory db "MyShell: Error allocating memory for input buffer: ",0
    error_input_init_memory_len equ $ - error_input_init_memory

    error_getting_parse_memory db "MyShell: Error getting memory for parse line: ", 0
    error_getting_parse_memory_len equ $ - error_getting_parse_memory

    error_reading_input db "MyShell: Error reading input: ", 0
    error_reading_input_len equ $ - error_reading_input

    error_increasing_input_buffer_mem db "MyShell: Error increasing input buffer storage: ", 0
    error_increasing_input_buffer_mem_len equ $ - error_increasing_input_buffer_mem

    error_overriding_custom_handler db "MyShell: Error overriding custom handler: ", 0
    error_overriding_custom_handler_len equ $ - error_overriding_custom_handler

    error_setting_non_con_mode db "Error setting mode to non canonical:", 0
    error_setting_non_con_mode_len equ $ - error_setting_non_con_mode

    error_getting_cwd db "MyShell: Error getting cwd:",0
    error_getting_cwd_len equ $ - error_getting_cwd

    error_getting_pgid db "Error getting shells group id", 0
    error_getting_pgid_len equ $ - error_getting_pgid

    error_command_not_found0 db "MyShell: Error executing ", 0
    error_command_not_found0_len equ $ - error_command_not_found0
    error_command_not_found1 db ": Command not found", 0
    error_command_not_found1_len equ $ - error_command_not_found1

    error_allocating_memory_for_history db "MyShell: Error allocating memory for history: ", 0
    error_allocating_memory_for_history_len equ $ - error_allocating_memory_for_history

    error_getting_mem_for_cmd_in_history db "MyShell: Error allocating memory for command for history.",0
    error_getting_mem_for_cmd_in_history_len equ $ - error_getting_mem_for_cmd_in_history

    error_getting_pipes db "MyShell: Error executing process: Error creating pipe: ", 0
    error_getting_pipes_len equ $ - error_getting_pipes 

    error_forking db "MyShell: Error forking",0
    error_forking_len equ $ - error_forking

    child_error_executing_process db "MyShell: Error executing ", 0
    child_error_executing_process_len equ $ - child_error_executing_process

    parent_error_closing_read_pipe db "MyShell: Error creating pipe for child:", 0
    parent_error_closing_read_pipe_len equ $ - parent_error_closing_read_pipe

    parent_error_setting_gpid_for_child db "MyShell: Error setting gpid for child process:", 0
    parent_error_setting_gpid_for_child_len equ $ - parent_error_setting_gpid_for_child

    parent_error_moving_child_to_fg db "MyShell: Error moving child to foreground:", 0
    parent_error_moving_child_to_fg_len equ $ - parent_error_moving_child_to_fg

    parent_error_synchronizing_with_child db "MyShell: Error synchronizing with child process:", 0
    parent_error_synchronizing_with_child_len equ $ - parent_error_synchronizing_with_child

    parent_error_closing_write_pipe db "MyShell: Error closing parent write pipe: ", 0
    parent_error_closing_write_pipe_len equ $ - parent_error_closing_write_pipe

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
global child_print_error_executing_process
global print_error_command_not_found
global print_error_setting_non_con_mode
global print_error_getting_pgid
global print_error_allocating_memory_for_history
global print_error_getting_mem_for_cmd_in_history
global print_error_getting_pipes
global parent_print_error_closing_read_pipe
global parent_print_error_setting_gpid_for_child
global parent_print_error_moving_child_to_fg
global parent_print_error_synchronizing_with_child
global parent_print_error_closing_write_pipe

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


child_print_error_executing_process:
    mov rax, child_error_executing_process_len
    mov rdi, 1
    lea rsi , [rel child_error_executing_process]
    call _print

    mov rdi, [rel address_command]
    call _strlen
    
    mov rdi, 1
    mov rsi, [rel address_command]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

parent_print_error_closing_read_pipe:
    mov rax, parent_error_closing_read_pipe_len
    mov rdi, 1
    lea rsi, [rel parent_error_closing_read_pipe]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

parent_print_error_setting_gpid_for_child:
    mov rax, parent_error_setting_gpid_for_child_len
    mov rdi, 1
    lea rsi, [rel parent_error_setting_gpid_for_child]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

parent_print_error_moving_child_to_fg:
    mov rax, parent_error_moving_child_to_fg_len
    mov rdi, 1
    lea rsi, [rel parent_error_moving_child_to_fg]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

parent_print_error_synchronizing_with_child:
    mov rax, parent_error_synchronizing_with_child_len
    mov rdi, 1
    lea rsi, [rel parent_error_synchronizing_with_child]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

parent_print_error_closing_write_pipe:
    mov rax, parent_error_closing_write_pipe_len
    mov rdi, 1
    lea rsi, [rel parent_error_closing_write_pipe]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_command_not_found:
    mov rax, error_command_not_found0_len
    mov rdi, 1
    lea rsi, [rel error_command_not_found0]
    call _print

    mov rdi, [rel address_command]
    call _strlen
    
    mov rdi, 1
    mov rsi, [rel address_command]
    call _print

    mov rax, error_command_not_found1_len
    mov rdi, 1
    lea rsi, [rel error_command_not_found1]
    call _print_with_new_line
    ret


print_error_allocating_memory_for_history:
    mov rax, error_allocating_memory_for_history_len
    mov rdi, 1
    lea rsi , [rel error_allocating_memory_for_history]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_getting_mem_for_cmd_in_history:
    mov rax, error_getting_mem_for_cmd_in_history_len
    mov rdi, 1
    lea rsi , [rel error_getting_mem_for_cmd_in_history]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_getting_pipes:
    mov rax, error_getting_pipes_len
    mov rdi, 1
    lea rsi , [rel error_getting_pipes]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_getting_pgid:
    mov rax, error_getting_pgid_len
    mov rdi, 1
    lea rsi , [rel error_getting_pgid]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret

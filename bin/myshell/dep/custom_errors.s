global error_code

section .data
    error_code dq 0
    
section .rodata
    
    single_quote db "'", 0
    double_quote db '"', 0

    ; --------------------------------  MAIN ---------------------------------
    error_input_init_memory db "MyShell: Error allocating memory for input buffer: ",0
    error_input_init_memory_len equ $ - error_input_init_memory

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


    ; ----------------------------- READ INPUT ---------------------------------
    error_reading_input db "MyShell: Error reading input: ", 0
    error_reading_input_len equ $ - error_reading_input

    error_increasing_input_buffer_mem db "MyShell: Error increasing input buffer storage: ", 0
    error_increasing_input_buffer_mem_len equ $ - error_increasing_input_buffer_mem





    ; --------------------------- PROCESS TOKENS ---------------------------------

    error_dq_left_open0 db "MyShell: Expected a closing '", 0
    error_dq_left_open0_len equ $ - error_dq_left_open0
    error_dq_left_open1 db "' in the end.", 0
    error_dq_left_open1_len equ $ - error_dq_left_open1
    
    error_sq_left_open0 db 'MyShell: Expected a closing "', 0
    error_sq_left_open0_len equ $ - error_sq_left_open0
    error_sq_left_open1 db '" in the end.', 0
    error_sq_left_open1_len equ $ - error_sq_left_open1

    error_initializing_command_array db "MyShell: Error executing command. Error initializing command array:", 0
    error_initializing_command_array_len equ $ - error_initializing_command_array

    error_initializing_argv_array db "MyShell: Error executing command. Error initializing argv array:", 0
    error_initializing_argv_array_len equ $ - error_initializing_argv_array

    error_initializing_envp_array db "MyShell: Error executing command. Error initializing envp array:", 0
    error_initializing_envp_array_len equ $ - error_initializing_envp_array

    error_redirect_in_expects_word db "MyShell: Unexpected token near '<'", 0
    error_redirect_in_expects_word_len equ $ - error_redirect_in_expects_word

    error_redirect_out_expects_word db "MyShell: Unexpected token near '>'", 0
    error_redirect_out_expects_word_len equ $ - error_redirect_out_expects_word

    error_adding_to_argc db "MyShell: Error executing command. Error adding argv variable:", 0
    error_adding_to_argc_len equ $ - error_adding_to_argc

    error_adding_custom_env_var db "MyShell: Error executing command. Error adding custom env varriable:", 0
    error_adding_custom_env_var_len equ $ - error_adding_custom_env_var

    error_adding_command_stuct db "MyShell: Error executing command. Error chaining command: ", 0
    error_adding_command_stuct_len equ $ - error_adding_command_stuct

    error_invalid_token_after_pipe db "MyShell: Unexpected token near '|'", 0
    error_invalid_token_after_pipe_len equ $ - error_invalid_token_after_pipe

    error_command_name_not_found_for_last_command db "MyShell: Unexpected end of token. Command name not found.", 0
    error_command_name_not_found_for_last_command_len equ $ - error_command_name_not_found_for_last_command

    error_unknow_token db "MyShell: Error executing command. Error unknown token value", 0
    error_unknow_token_len equ $ - error_unknow_token

    ; ---------------------------- EXECUTE PROCESS ---------------------------------
    error_getting_pipes db "MyShell: Error executing process: Error creating pipe: ", 0
    error_getting_pipes_len equ $ - error_getting_pipes 

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

    ; ---------------------------- EXECUTE PROCESS ---------------------------------
    error_initializing_common_env_array_obj db "MyShell: Error executing command. Error initializing common env array obj:", 0
    error_initializing_common_env_array_obj_len equ $ - error_initializing_common_env_array_obj

    error_initializing_pipe_array db "MyShell: Error executing command. Error initializing pipe array obj:", 0
    error_initializing_pipe_array_len equ $ - error_initializing_pipe_array

    error_adding_to_common_env_array db "MyShell: Error executing command. Error adding shell env var to common env array:", 0
    error_adding_to_common_env_array_len equ $ - error_adding_to_common_env_array

    error_getting_sync_pipes db "MyShell: Error executing process: Error getting sync pipe:", 0
    error_getting_sync_pipes_len equ $ - error_getting_sync_pipes

    error_getting_redirection_pipe db "MyShell: Error executing command. Error getting redirectionn pipe:", 0
    error_getting_redirection_pipe_len equ $ - error_getting_redirection_pipe

    error_getting_pipe_array_element db "MyShell: Error executing command. Error getting pipe array element:", 0
    error_getting_pipe_array_element_len equ $ - error_getting_pipe_array_element

    error_appending_pipe_array db "MyShell: Error executing command. Error appending pipe array:", 0
    error_appending_pipe_array_len equ $ - error_appending_pipe_array

    error_changing_child_pgid db "MyShell: Error executing command. Shell unable to change gpid for child process:", 0
    error_changing_child_pgid_len equ $ - error_changing_child_pgid

    error_forking db "MyShell: Error executing command. Error forking:",0
    error_forking_len equ $ - error_forking

    error_moving_child_to_fg db "MyShell: Error executing command. Error moving child to foreground:", 0
    error_moving_child_to_fg_len equ $ - error_moving_child_to_fg

    error_writing_to_pipe_for_syncing db "MyShell: Error executing command. Error writing bytes to pipe for sync: ", 0
    error_writing_to_pipe_for_syncing_len equ $ - error_writing_to_pipe_for_syncing

    error_putting_shell_into_fg db "MyShell: Error putting shell into foreground: ", 0
    error_putting_shell_into_fg_len equ $ - error_putting_shell_into_fg




section .bss
    reusable_buffer_error resb 1024


extern _print
extern _print_with_new_line
extern _print_error_with_new_line
extern _itoa
extern _strlen

extern error_custom_handler_number
extern address_command


section .text

global print_error_input_init_memory
global print_error_reading_input
global print_error_increasing_input_mem
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

; ---- process token
global print_error_dq_left_open
global print_error_sq_left_open
global print_error_initializing_command_array
global print_error_initializing_argv_array
global print_error_initializing_envp_array
global print_error_redirect_in_expects_word
global print_error_redirect_out_expects_word
global print_error_adding_to_argc
global print_error_adding_custom_env_var
global print_error_adding_command_stuct
global print_error_invalid_token_after_pipe
global print_error_command_name_not_found_for_last_command
global print_error_unknow_token

; ---- Execute commands
global print_error_initializing_common_env_array_obj
global print_error_initializing_pipe_array
global print_error_adding_to_common_env_array
global print_error_getting_sync_pipes
global print_error_getting_redirection_pipe
global print_error_getting_pipe_array_element
global print_error_appending_pipe_array
global print_error_changing_child_pgid
global print_error_forking
global print_error_moving_child_to_fg
global print_error_writing_to_pipe_for_syncing
global print_error_putting_shell_into_fg


print_error_input_init_memory:
    mov rax, error_input_init_memory_len
    mov rdi, 2
    lea rsi, [rel error_input_init_memory]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_reading_input:
    mov rax, error_reading_input_len
    mov rdi, 2
    lea rsi, [rel error_reading_input]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_increasing_input_mem:
    mov rax, error_increasing_input_buffer_mem_len    
    mov rdi, 2
    lea rsi , [rel error_increasing_input_buffer_mem]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_overriding_custom_handler:
    mov rax, error_overriding_custom_handler_len
    mov rdi, 2
    lea rsi , [rel error_overriding_custom_handler]
    call _print

    mov rax, [rel error_custom_handler_number]
    lea rdi, [rel reusable_buffer_error]
    call _itoa                          ; rax has len of number in bytes

    mov rdi, 2
    lea rsi, [rel reusable_buffer_error]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_setting_non_con_mode:
    mov rax, error_setting_non_con_mode_len
    mov rdi, 2
    lea rsi , [rel error_setting_non_con_mode]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret



print_error_getting_cwd:
    mov rax, error_getting_cwd_len
    mov rdi, 2
    lea rsi , [rel error_getting_cwd]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret


; ------------------------------ EXECUTE PROCESS NEW---------------



print_error_initializing_common_env_array_obj:
    mov rax, error_initializing_common_env_array_obj_len
    mov rdi, 2
    lea rsi , [rel error_initializing_common_env_array_obj]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_initializing_pipe_array:
    mov rax, error_initializing_pipe_array_len
    mov rdi, 2
    lea rsi , [rel error_initializing_pipe_array]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_adding_to_common_env_array:
    mov rax, error_adding_to_common_env_array_len
    mov rdi, 2
    lea rsi , [rel error_adding_to_common_env_array]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_getting_sync_pipes:
    mov rax, error_getting_sync_pipes_len
    mov rdi, 2
    lea rsi , [rel error_getting_sync_pipes]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_getting_redirection_pipe:
    mov rax, error_getting_redirection_pipe_len
    mov rdi, 2
    lea rsi , [rel error_getting_redirection_pipe]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_getting_pipe_array_element:
    mov rax, error_getting_pipe_array_element_len
    mov rdi, 2
    lea rsi , [rel error_getting_pipe_array_element]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_appending_pipe_array:
    mov rax, error_appending_pipe_array_len
    mov rdi, 2
    lea rsi , [rel error_appending_pipe_array]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_changing_child_pgid:
    mov rax, error_changing_child_pgid_len
    mov rdi, 2
    lea rsi, [rel error_changing_child_pgid]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_forking:
    mov rax, error_forking_len
    mov rdi, 2
    lea rsi , [rel error_forking]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_moving_child_to_fg:
    mov rax, error_moving_child_to_fg_len
    mov rdi, 2
    lea rsi, [rel error_moving_child_to_fg]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_writing_to_pipe_for_syncing:
    mov rax, error_writing_to_pipe_for_syncing_len
    mov rdi, 2
    lea rsi, [rel error_writing_to_pipe_for_syncing]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_putting_shell_into_fg:
    mov rax, error_putting_shell_into_fg_len
    mov rdi, 2
    lea rsi, [rel error_putting_shell_into_fg]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret




; ------------------------------ EXECUTE PROCESS OLD---------------


print_error_forking2:
    mov rax, error_forking_len
    mov rdi, 2
    lea rsi , [rel error_forking]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

; rdi: expects the addres of command name
child_print_error_executing_process:
    push r12
    mov r12, rdi
    
    mov rax, child_error_executing_process_len
    mov rdi, 2
    lea rsi , [rel child_error_executing_process]
    call _print

    mov rdi, r12
    call _strlen
    
    mov rdi, 2
    mov rsi, r12
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line

    pop r12
    ret

parent_print_error_closing_read_pipe:
    mov rax, parent_error_closing_read_pipe_len
    mov rdi, 2
    lea rsi, [rel parent_error_closing_read_pipe]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

parent_print_error_setting_gpid_for_child:
    mov rax, parent_error_setting_gpid_for_child_len
    mov rdi, 2
    lea rsi, [rel parent_error_setting_gpid_for_child]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

parent_print_error_moving_child_to_fg:
    mov rax, parent_error_moving_child_to_fg_len
    mov rdi, 2
    lea rsi, [rel parent_error_moving_child_to_fg]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

parent_print_error_synchronizing_with_child:
    mov rax, parent_error_synchronizing_with_child_len
    mov rdi, 2
    lea rsi, [rel parent_error_synchronizing_with_child]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

parent_print_error_closing_write_pipe:
    mov rax, parent_error_closing_write_pipe_len
    mov rdi, 2
    lea rsi, [rel parent_error_closing_write_pipe]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_command_not_found:
    mov rax, error_command_not_found0_len
    mov rdi, 2
    lea rsi, [rel error_command_not_found0]
    call _print

    mov rdi, [rel address_command]
    call _strlen
    
    mov rdi, 2
    mov rsi, [rel address_command]
    call _print

    mov rax, error_command_not_found1_len
    mov rdi, 2
    lea rsi, [rel error_command_not_found1]
    call _print_with_new_line
    ret


print_error_allocating_memory_for_history:
    mov rax, error_allocating_memory_for_history_len
    mov rdi, 2
    lea rsi , [rel error_allocating_memory_for_history]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_getting_mem_for_cmd_in_history:
    mov rax, error_getting_mem_for_cmd_in_history_len
    mov rdi, 2
    lea rsi , [rel error_getting_mem_for_cmd_in_history]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_getting_pipes:
    mov rax, error_getting_pipes_len
    mov rdi, 2
    lea rsi , [rel error_getting_pipes]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_getting_pgid:
    mov rax, error_getting_pgid_len
    mov rdi, 2
    lea rsi , [rel error_getting_pgid]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret



; ---------------------- PROCESS TOKENS ----------------------

print_error_dq_left_open:
    mov rax, error_dq_left_open0_len
    mov rdi, 2
    lea rsi, [rel error_dq_left_open0]
    call _print

    mov rax, 1
    mov rdi, 2
    lea rsi, [rel double_quote]
    call _print

    mov rax, error_dq_left_open1_len
    mov rdi, 2
    lea rsi, [rel error_dq_left_open1]
    call _print_with_new_line
    ret


print_error_sq_left_open:
    mov rax, error_sq_left_open0_len
    mov rdi, 2
    lea rsi, [rel error_sq_left_open0]
    call _print

    mov rax, 1
    mov rdi, 2
    lea rsi, [rel single_quote]
    call _print

    mov rax, error_sq_left_open1_len
    mov rdi, 2
    lea rsi, [rel error_sq_left_open1]
    call _print_with_new_line
    ret

print_error_initializing_command_array:
    mov rax, error_initializing_command_array_len
    mov rdi, 2
    lea rsi , [rel error_initializing_command_array]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_initializing_argv_array:
    mov rax, error_initializing_argv_array_len
    mov rdi, 2
    lea rsi , [rel error_initializing_argv_array]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_initializing_envp_array:
    mov rax, error_initializing_envp_array_len
    mov rdi, 2
    lea rsi , [rel error_initializing_envp_array]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret


print_error_redirect_in_expects_word:
    mov rax, error_redirect_in_expects_word_len
    mov rdi, 2
    lea rsi , [rel error_redirect_in_expects_word]
    call _print_with_new_line
    ret

print_error_redirect_out_expects_word:
    mov rax, error_redirect_out_expects_word_len
    mov rdi, 2
    lea rsi , [rel error_redirect_out_expects_word]
    call _print_with_new_line
    ret

print_error_adding_to_argc:
    mov rax, error_adding_to_argc_len
    mov rdi, 2
    lea rsi , [rel error_adding_to_argc]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_adding_custom_env_var:
    mov rax, error_adding_custom_env_var_len
    mov rdi, 2
    lea rsi , [rel error_adding_custom_env_var]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_adding_command_stuct:
    mov rax, error_adding_command_stuct_len
    mov rdi, 2
    lea rsi , [rel error_adding_command_stuct]
    call _print

    mov rdi, [rel error_code]
    call _print_error_with_new_line
    ret

print_error_invalid_token_after_pipe:
    mov rax, error_invalid_token_after_pipe_len
    mov rdi, 2
    lea rsi , [rel error_invalid_token_after_pipe]
    call _print_with_new_line
    ret

print_error_command_name_not_found_for_last_command:
    mov rax, error_command_name_not_found_for_last_command_len
    mov rdi, 2
    lea rsi , [rel error_command_name_not_found_for_last_command]
    call _print_with_new_line
    ret

    
print_error_unknow_token:
    mov rax, error_unknow_token_len
    mov rdi, 2
    lea rsi , [rel error_unknow_token]
    call _print_with_new_line
    ret
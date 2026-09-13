section .data
    prefix_line db "myshell> ",0
    prefix_line_len equ $ - prefix_line

    capacity_input_buffer_len dq 4096
    filled_size_input_buffer_len dq 0


    error_input_init_memory db "Error allocating memory for input buffer",0
    error_input_init_memory_len equ $ - error_input_init_memory

    error_reading_input db "Error reading input", 0
    error_reading_input_len equ $ - error_reading_input

    error_increasing_input_buffer_mem db "Error increasing input buffer storage", 0
    error_increasing_input_buffer_mem_len equ $ - error_increasing_input_buffer_mem

    exit_status_code dq 0
    error_code dq 0
    exit_flag dq 0

section .bss
    input_buffer_address resq 1         ; address from malloc




sys_read            equ 0   
sys_write           equ 1   
sys_open            equ 2   
sys_close           equ 3   
sys_stat            equ 4   
sys_rt_sigaction    equ 13  
sys_rt_sigreturn    equ 15  
sys_getdents        equ 78  
sys_getcwd          equ 79  




section .text

extern _print
extern _print_with_new_line
extern _strlen
extern _itoa
extern _mem_copy
extern _malloc
extern _free
extern _print_error_with_new_line


global _start



_get_and_set_memory_for_input_buffer:
    mov rdi, [rel capacity_input_buffer_len]
    call _malloc

    test rax, rax
    jl .handle_init_memory_error_and_exit

    mov [rel input_buffer_address], rax
    ret

    .handle_init_memory_error_and_exit:
        mov [rel error_code], rax
        call _errors.print_error_input_init_memory
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code


_init:
    call _get_and_set_memory_for_input_buffer
    ret


_print_prefix_line:
    mov rax, prefix_line_len
    mov rdi, 1
    lea rsi, [rel prefix_line]
    call _print
    ret


_read_input:
    ; make a read call

    mov qword [rel filled_size_input_buffer_len], 0

    .read_input_loop:
        mov rax, sys_read
        mov rdi, 0                              ; fd 0
        mov rsi, [rel input_buffer_address]     ; addres of buffer
        add rsi, [rel filled_size_input_buffer_len]
        mov rdx, [rel capacity_input_buffer_len]
        sub rdx, [rel filled_size_input_buffer_len]
        syscall 


        test rax, rax
        jl .handle_error_reading_input_and_exit
        jz  .handle_eof                            ; rax == 0, ctrl+d 

        add [rel filled_size_input_buffer_len], rax

        mov rcx, [rel filled_size_input_buffer_len]
        cmp rcx, [rel capacity_input_buffer_len]
        je .get_more_buffer_size

        ret


    .get_more_buffer_size:

        mov rdi, [rel capacity_input_buffer_len]
        shl rdi, 1            ; basically 2*capacity_input_buffer_len
        call _malloc

        test rax, rax
        jl .handle_error_increasing_input_buffer_and_exit

        push rax
        ; copy old buffer data into new buffer
        mov rdi, rax                                    ; new address : Dest
        mov rsi, [rel input_buffer_address]             ; old address : Src
        mov rdx, [rel filled_size_input_buffer_len]                ; total bytes to copy
        call _mem_copy

        mov rdi, [rel input_buffer_address]                ; free old address memory
        call _free 

        pop rax
        mov [rel input_buffer_address], rax             ; update input address
        
        ; rn its: old_cap*2
        mov rax, [rel capacity_input_buffer_len]        ; update buffer_capacity
        shl rax, 1
        mov [rel capacity_input_buffer_len], rax

        jmp .read_input_loop


    .handle_error_reading_input_and_exit:
        mov [rel error_code], rax
        call _errors.print_error_reading_input
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code

    .handle_error_increasing_input_buffer_and_exit:
        mov [rel error_code], rax
        call _errors.print_error_increasing_input_mem
        mov [rel exit_status_code], 1
        jmp _exit_with_status_code
    .handle_eof:
        mov [rel exit_flag], 1
        ret


_parse_input:
    mov rax, [rel filled_size_input_buffer_len]
    mov rdi, 1
    mov rsi, [rel input_buffer_address]
    call _print_with_new_line

    ret


_start:
    mov rbp, rsp 

    call _init

    .loop_main:
        call _print_prefix_line
        call _read_input
        call _parse_input

        cmp qword [rel exit_flag], 1
        je _exit

        jmp .loop_main



_errors:
.print_error_input_init_memory:
    mov rax, error_input_init_memory_len
    mov rdi, 1
    lea rsi, [rel error_input_init_memory]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


.print_error_reading_input:
    mov rax, error_reading_input_len
    mov rdi, 1
    lea rsi, [rel error_reading_input]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret
.print_error_increasing_input_mem:
    mov rax, error_increasing_input_buffer_mem_len    
    mov rdi, 1
    lea rsi , [rel error_increasing_input_buffer_mem]
    call _print

    mov rax, [rel error_code]
    call _print_error_with_new_line
    ret


_exit_with_status_code:
    mov rax, 60
    mov rdi, [rel exit_status_code]
    syscall

_exit:
    mov rax, 60
    mov rdi, 0
    syscall
section .rodata
    
    string1 db "grep", 0
    string1_len equ $ - string1
    string2 db "grep", 0
    string2_len equ $ - string2
    string3 db "The big brown fox2", 0
    string3_len equ $ - string3
    string4 db "Jumps over the lazy dog2", 0
    string4_len equ $ - string4

section .text
; rdi: address of string
; rsi: len of string
; returns
; 	rax: the hash of string
hash_string:
    mov     rax, 0xCBF29CE484222325 ; FNV offset basis
    mov     rcx, 0                 ; i = 0

.loop:
    cmp     rcx, rsi               ; i >= len?
    jae     .done                  ; if yes, finish

    movzx   rdx, byte [rdi + rcx]  ; rdx = str[i]
    xor     rax, rdx               ; hash ^= str[i]
    mov     rdx, 0x100000001B3     ; FNV prime
    imul    rax, rdx               ; hash *= prime (64-bit)

    inc     rcx                    ; i++
    jmp     .loop

.done:
    ret



global _start

_start:
    lea rdi, [rel string1]
    mov rsi, string1_len
    call hash_string

    xor rdx, rdx
    mov rdi, 1024
    div rdi

    .bp1:

    lea rdi, [rel string2]
    mov rsi, string2_len
    call hash_string

    xor rdx, rdx
    mov rdi, 1024
    div rdi

    .bp2:

    lea rdi, [rel string3]
    mov rsi, string3_len
    call hash_string

    xor rdx, rdx
    mov rdi, 1024
    div rdi

    .bp3:

    lea rdi, [rel string4]
    mov rsi, string4_len
    call hash_string

    xor rdx, rdx
    mov rdi, 1024
    div rdi

    jmp _exit


_exit:
    mov rax, 60
    mov rdi, 0
    syscall
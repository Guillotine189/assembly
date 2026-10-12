; this program prints the env variables passed inside the stack in process start

;		RSP
;		    │
;		    ▼
;		┌──────────────────────────────┐
;		│ argc                         │  ← 8-byte value in the x86-64 stack
;		├──────────────────────────────┤
;		│ argv[0 address]              │  ← char * (8 bytes)
;		│ argv[1 address]              │
;		│ ...                          │
;		│ argv[argc-1 address]         │
;		│ NULL                         │  ← terminates argv[]
;		├──────────────────────────────┤
;		│ envp[0 address]              │  ← char *
;		│ envp[1 address]              │
;		│ ...                          │
;		│ envp[n-1 address]            │
;		│ NULL                         │  ← terminates envp[]
;		├──────────────────────────────┤
;		│ auxv[0].type                 │  ← 8 bytes
;		│ auxv[0].value                │  ← 8 bytes
;		├──────────────────────────────┤
;		│ auxv[1].type                 │
;		│ auxv[1].value                │
;		├──────────────────────────────┤
;		│ ...                          │
;		├──────────────────────────────┤
;		│ AT_NULL                      │  ← type = 0
;		│ 0                            │  ← value = 0
;		├──────────────────────────────┤
;		│ padding/alignment (possible) │
;		├──────────────────────────────┤
;		│ environment strings          │
;		│ "PATH=/usr/bin\0"            │
;		│ "HOME=/home/me\0"            │
;		│ "USER=me\0"                  │
;		│ ...                          │
;		├──────────────────────────────┤
;		│ argument strings             │
;		│ "./program\0"                │
;		│ "hello\0"                    │
;		│ "world\0"                    │
;		│ ...                          │
;		└──────────────────────────────┘
;		    │
;		HIGH ADDRESSES



extern _strlen
extern _print

section .text

global _start

_start:

	mov rax, [rsp] 						; store how many args passed
	add rax, 2 							; initial argc 8 bytes + 8 bytes for null

	mov rbx, rax 							; rbx will store how many 8bytes to skip from rsp

	.loop:
		
		; check if null
		mov rdi, [rsp + rbx*8]					; store the address/NULL(0x00)
		test rdi, rdi 								; just AND rdi and rdi, and update flags
		; if rdi is 0, 		rdi & rdi -> ZF = 1
		; if rdi is not 0,  rdi & rdi -> ZF = 0

		je _done
		call _strlen								; len of env in rax

		mov rdi, [rsp + rbx*8]					; store the address
		mov rsi, rax							; how many bytes to print, recv from prev func
		call _print

		inc rbx
		jmp .loop


_done:
	mov rax, 60
	mov rdi, 0
	syscall
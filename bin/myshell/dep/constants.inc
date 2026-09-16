sys_read            equ 0   
sys_write           equ 1   
sys_open            equ 2   
sys_close           equ 3   
sys_stat            equ 4   
sys_rt_sigaction    equ 13  
sys_rt_sigreturn    equ 15  
sys_ioctl		    equ 16
sys_fork            equ 57
sys_execve          equ 59
sys_wait4           equ 61
sys_getcwd          equ 79
sys_setpgid  		equ 109	    ; set process group id
sys_getpgrp 		equ 111  	; get process group id
sys_getdents64      equ 217

EINTR equ -4         

SIGABRT     equ  6
SIGALRM     equ  14
SIGBUS      equ 7
SIGCHLD     equ  17
SIGCONT     equ  18
SIGFPE      equ 8
SIGHUP      equ 1
SIGILL      equ 4
SIGINT      equ 2
SIGPOLL     equ  29
SIGIO       equ  SIGPOLL
SIGIOT      equ  SIGABRT
SIGPIPE     equ  13
SIGPROF     equ  27
SIGPWR      equ  30
SIGQUIT     equ  3
SIGSEGV     equ  11
SIGSTKFLT   equ  16
SIGSTKSZ    equ  8192
SIGSYS      equ  31
SIGTERM     equ  15
SIGTRAP     equ  5
SIGTSTP     equ  20
SIGTTIN     equ  21
SIGTTOU     equ  22
SIGURG      equ  23
SIGUSR1     equ  10
SIGUSR2     equ  12
SIGVTALRM   equ  26
SIGWINCH    equ  28
SIGXCPU     equ  24
SIGXFSZ     equ  25

; for signal handling
SA_RESTORER equ 0x04000000  ;flag value to tell kernal that restorer function is seperate
SA_RESTART equ 0x10000000   ; if a syscall was in progress, restart that syscall
SA_RESETHAND equ 0x80000000 ; after rec the interrupt once, reset the handler to default.


; for noncanonical
C_LFLAG   equ 12
TIOCSPGRP equ 0x5410    ; for group pid changing
TCGETS    equ 0x5401
TCSETS    equ 0x5402

; stat
O_RDONLY    equ 0
O_WRONLY    equ 1
O_RDWR      equ 2

O_CREAT     equ 64      ; (0x40)
O_EXCL      equ 128     ; (0x80)
O_TRUNC     equ 512     ; (0x200)
O_APPEND    equ 1024    ; (0x400)
O_NONBLOCK  equ 2048    ; (0x800)
O_DIRECTORY equ 65536   ; (0x10000)

; getdents64
DT_UNKNOWN  equ 0
DT_FIFO     equ 1
DT_CHR      equ 2
DT_DIR      equ 4
DT_BLK      equ 6
DT_REG      equ 8
DT_LNK      equ 10
DT_SOCK     equ 12
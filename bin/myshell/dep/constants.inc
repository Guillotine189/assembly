sys_read            equ 0   
sys_write           equ 1   
sys_open            equ 2   
sys_close           equ 3   
sys_stat            equ 4   
sys_rt_sigaction    equ 13  
sys_rt_sigreturn    equ 15  
sys_ioctl		    equ 16
sys_pipe 			equ 22
sys_dup2			equ 33
sys_fork            equ 57
sys_execve          equ 59
sys_wait4           equ 61
sys_kill  			equ 62
sys_getcwd          equ 79
sys_setpgid  		equ 109	    ; set process group id
sys_getpgrp 		equ 111  	; get process group id
sys_getdents64      equ 217
    

SIGHUP      equ 1
SIGINT      equ 2
SIGQUIT     equ 3
SIGILL      equ 4
SIGTRAP     equ 5
SIGABRT     equ 6
SIGBUS      equ 7
SIGFPE      equ 8
SIGKILL     equ 9
SIGUSR1     equ 10
SIGSEGV     equ 11
SIGUSR2     equ 12
SIGPIPE     equ 13
SIGALRM     equ 14
SIGTERM     equ 15
SIGSTKFLT   equ 16
SIGCHLD     equ 17
SIGCONT     equ 18
SIGTSTP     equ 20
SIGTTIN     equ 21
SIGTTOU     equ 22
SIGURG      equ 23
SIGXCPU     equ 24
SIGXFSZ     equ 25
SIGVTALRM   equ 26
SIGPROF     equ 27
SIGWINCH    equ 28
SIGPOLL     equ 29
SIGPWR      equ 30
SIGSYS      equ 31
SIGIO       equ  SIGPOLL
SIGIOT      equ  SIGABRT




; for signal handling
SA_RESTORER equ 0x04000000  ;flag value to tell kernal that restorer function is seperate
SA_RESTART equ 0x10000000   ; if a syscall was in progress, restart that syscall
SA_RESETHAND equ 0x80000000 ; after rec the interrupt once, reset the handler to default.


; for ioctl
C_LFLAG     equ 12
TIOCGWINSZ  equ 0x5413 		; get window size of terminal
TIOCSWINSZ  equ 0x5414 		; set window size of terminal
TIOCGPGRP   equ 0x540F 		; get the current pgid for terminal
TIOCSPGRP   equ 0x5410      ; change group pid of an terminal
TCGETS      equ 0x5401  	; signal interrupt get old info
TCSETS      equ 0x5402  	; signal interrupt set

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


; error code os returns when syscall fails
EPERM           equ 1
ENOENT          equ 2
ESRCH           equ 3
EINTR           equ 4
EIO             equ 5
ENXIO           equ 6
E2BIG            equ 7
ENOEXEC         equ 8
EBADF           equ 9
ECHILD          equ 10
EAGAIN          equ 11
EWOULDBLOCK     equ 11
ENOMEM          equ 12
EACCES          equ 13
EFAULT          equ 14
ENOTBLK         equ 15
EBUSY           equ 16
EEXIST          equ 17
EXDEV           equ 18
ENODEV          equ 19
ENOTDIR         equ 20
EISDIR          equ 21
EINVAL          equ 22
ENFILE          equ 23
EMFILE          equ 24
ENOTTY          equ 25
ETXTBSY         equ 26
EFBIG           equ 27
ENOSPC          equ 28
ESPIPE          equ 29
EROFS           equ 30
EMLINK          equ 31
EPIPE           equ 32
EDOM            equ 33
ERANGE          equ 34
EDEADLK         equ 35
EDEADLOCK       equ 35
ENAMETOOLONG    equ 36
ENOLCK          equ 37
ENOSYS          equ 38
ENOTEMPTY       equ 39
ELOOP           equ 40
ENOMSG          equ 42
EIDRM           equ 43
ECHRNG          equ 44
EL2NSYNC        equ 45
EL3HLT          equ 46
EL3RST          equ 47
ELNRNG          equ 48
EUNATCH         equ 49
ENOCSI          equ 50
EL2HLT          equ 51
EBADE           equ 52
EBADR           equ 53
EXFULL          equ 54
ENOANO          equ 55
EBADRQC         equ 56
EBADSLT         equ 57
EBFONT          equ 59
ENOSTR          equ 60
ENODATA         equ 61
ETIME           equ 62
ENOSR           equ 63
ENONET          equ 64
ENOPKG          equ 65
EREMOTE         equ 66
ENOLINK         equ 67
EADV            equ 68
ESRMNT          equ 69
ECOMM           equ 70
EPROTO          equ 71
EMULTIHOP       equ 72
EDOTDOT         equ 73
EBADMSG         equ 74
EOVERFLOW       equ 75
ENOTUNIQ        equ 76
EBADFD          equ 77
EREMCHG         equ 78
ELIBACC         equ 79
ELIBBAD         equ 80
ELIBSCN         equ 81
ELIBMAX         equ 82
ELIBEXEC        equ 83
EILSEQ          equ 84
ERESTART        equ 85
ESTRPIPE        equ 86
EUSERS          equ 87
ENOTSOCK        equ 88
EDESTADDRREQ    equ 89
EMSGSIZE        equ 90
EPROTOTYPE      equ 91
ENOPROTOOPT     equ 92
EPROTONOSUPPORT equ 93
ESOCKTNOSUPPORT equ 94
EOPNOTSUPP      equ 95
ENOTSUP         equ 95
EPFNOSUPPORT    equ 96
EAFNOSUPPORT    equ 97
EADDRINUSE      equ 98
EADDRNOTAVAIL   equ 99
ENETDOWN        equ 100
ENETUNREACH     equ 101
ENETRESET       equ 102
ECONNABORTED    equ 103
ECONNRESET      equ 104
ENOBUFS         equ 105
EISCONN         equ 106
ENOTCONN        equ 107
ESHUTDOWN       equ 108
ETOOMANYREFS    equ 109
ETIMEDOUT       equ 110
ECONNREFUSED    equ 111
EHOSTDOWN       equ 112
EHOSTUNREACH    equ 113
EALREADY        equ 114
EINPROGRESS     equ 115
ESTALE          equ 116
EUCLEAN         equ 117
ENOTNAM         equ 118
ENAVAIL         equ 119
EISNAM          equ 120
EREMOTEIO       equ 121
EDQUOT          equ 122
ENOMEDIUM       equ 123
EMEDIUMTYPE     equ 124
ECANCELED       equ 125
ENOKEY          equ 126
EKEYEXPIRED     equ 127
EKEYREVOKED     equ 128
EKEYREJECTED    equ 129
EOWNERDEAD      equ 130
ENOTRECOVERABLE equ 131
ERFKILL         equ 132
EHWPOISON       equ 133
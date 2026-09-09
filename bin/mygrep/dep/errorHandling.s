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


%macro CHECK_ERRNO 2
    cmp rax, %1
    je %2
%endmacro


%macro PRINT_ERRNO 1
.errno_%1:
    mov rax, errno_%1_msg_len
    mov rdi, 1
    lea rsi, [rel errno_%1_msg]
    call _print_with_new_line
    ret
%endmacro

section .data

    errno_1_msg db " Operation not permitted", 0
    errno_1_msg_len equ $ - errno_1_msg

    errno_2_msg db " No such file or directory", 0
    errno_2_msg_len equ $ - errno_2_msg

    errno_3_msg db " No such process", 0
    errno_3_msg_len equ $ - errno_3_msg

    errno_4_msg db " Interrupted system call", 0
    errno_4_msg_len equ $ - errno_4_msg

    errno_5_msg db " Input/output error", 0
    errno_5_msg_len equ $ - errno_5_msg

    errno_6_msg db " No such device or address", 0
    errno_6_msg_len equ $ - errno_6_msg

    errno_7_msg db " Argument list too long", 0
    errno_7_msg_len equ $ - errno_7_msg

    errno_8_msg db " Exec format error", 0
    errno_8_msg_len equ $ - errno_8_msg

    errno_9_msg db " Bad file descriptor", 0
    errno_9_msg_len equ $ - errno_9_msg

    errno_10_msg db " No child processes", 0
    errno_10_msg_len equ $ - errno_10_msg

    errno_11_msg db " Resource temporarily unavailable", 0
    errno_11_msg_len equ $ - errno_11_msg

    errno_12_msg db " Cannot allocate memory", 0
    errno_12_msg_len equ $ - errno_12_msg

    errno_13_msg db " Permission denied", 0
    errno_13_msg_len equ $ - errno_13_msg

    errno_14_msg db " Bad address", 0
    errno_14_msg_len equ $ - errno_14_msg

    errno_15_msg db " Block device required", 0
    errno_15_msg_len equ $ - errno_15_msg

    errno_16_msg db " Device or resource busy", 0
    errno_16_msg_len equ $ - errno_16_msg

    errno_17_msg db " File exists", 0
    errno_17_msg_len equ $ - errno_17_msg

    errno_18_msg db " Invalid cross-device link", 0
    errno_18_msg_len equ $ - errno_18_msg

    errno_19_msg db " No such device", 0
    errno_19_msg_len equ $ - errno_19_msg

    errno_20_msg db " Not a directory", 0
    errno_20_msg_len equ $ - errno_20_msg

    errno_21_msg db " Is a directory", 0
    errno_21_msg_len equ $ - errno_21_msg

    errno_22_msg db " Invalid argument", 0
    errno_22_msg_len equ $ - errno_22_msg

    errno_23_msg db " Too many open files in system", 0
    errno_23_msg_len equ $ - errno_23_msg

    errno_24_msg db " Too many open files", 0
    errno_24_msg_len equ $ - errno_24_msg

    errno_25_msg db " Inappropriate ioctl for device", 0
    errno_25_msg_len equ $ - errno_25_msg

    errno_26_msg db " Text file busy", 0
    errno_26_msg_len equ $ - errno_26_msg

    errno_27_msg db " File too large", 0
    errno_27_msg_len equ $ - errno_27_msg

    errno_28_msg db " No space left on device", 0
    errno_28_msg_len equ $ - errno_28_msg

    errno_29_msg db " Illegal seek", 0
    errno_29_msg_len equ $ - errno_29_msg

    errno_30_msg db " Read-only file system", 0
    errno_30_msg_len equ $ - errno_30_msg

    errno_31_msg db " Too many links", 0
    errno_31_msg_len equ $ - errno_31_msg

    errno_32_msg db " Broken pipe", 0
    errno_32_msg_len equ $ - errno_32_msg

    errno_33_msg db " Numerical argument out of domain", 0
    errno_33_msg_len equ $ - errno_33_msg

    errno_34_msg db " Numerical result out of range", 0
    errno_34_msg_len equ $ - errno_34_msg

    errno_35_msg db " Resource deadlock avoided", 0
    errno_35_msg_len equ $ - errno_35_msg

    errno_36_msg db " File name too long", 0
    errno_36_msg_len equ $ - errno_36_msg

    errno_37_msg db " No locks available", 0
    errno_37_msg_len equ $ - errno_37_msg

    errno_38_msg db " Function not implemented", 0
    errno_38_msg_len equ $ - errno_38_msg

    errno_39_msg db " Directory not empty", 0
    errno_39_msg_len equ $ - errno_39_msg

    errno_40_msg db " Too many levels of symbolic links", 0
    errno_40_msg_len equ $ - errno_40_msg

    errno_42_msg db " No message of desired type", 0
    errno_42_msg_len equ $ - errno_42_msg

    errno_43_msg db " Identifier removed", 0
    errno_43_msg_len equ $ - errno_43_msg

    errno_44_msg db " Channel number out of range", 0
    errno_44_msg_len equ $ - errno_44_msg

    errno_45_msg db " Level 2 not synchronized", 0
    errno_45_msg_len equ $ - errno_45_msg

    errno_46_msg db " Level 3 halted", 0
    errno_46_msg_len equ $ - errno_46_msg

    errno_47_msg db " Level 3 reset", 0
    errno_47_msg_len equ $ - errno_47_msg

    errno_48_msg db " Link number out of range", 0
    errno_48_msg_len equ $ - errno_48_msg

    errno_49_msg db " Protocol driver not attached", 0
    errno_49_msg_len equ $ - errno_49_msg

    errno_50_msg db " No CSI structure available", 0
    errno_50_msg_len equ $ - errno_50_msg

    errno_51_msg db " Level 2 halted", 0
    errno_51_msg_len equ $ - errno_51_msg

    errno_52_msg db " Invalid exchange", 0
    errno_52_msg_len equ $ - errno_52_msg

    errno_53_msg db " Invalid request descriptor", 0
    errno_53_msg_len equ $ - errno_53_msg

    errno_54_msg db " Exchange full", 0
    errno_54_msg_len equ $ - errno_54_msg

    errno_55_msg db " No anode", 0
    errno_55_msg_len equ $ - errno_55_msg

    errno_56_msg db " Invalid request code", 0
    errno_56_msg_len equ $ - errno_56_msg

    errno_57_msg db " Invalid slot", 0
    errno_57_msg_len equ $ - errno_57_msg

    errno_59_msg db " Bad font file format", 0
    errno_59_msg_len equ $ - errno_59_msg

    errno_60_msg db " Device not a stream", 0
    errno_60_msg_len equ $ - errno_60_msg

    errno_61_msg db " No data available", 0
    errno_61_msg_len equ $ - errno_61_msg

    errno_62_msg db " Timer expired", 0
    errno_62_msg_len equ $ - errno_62_msg

    errno_63_msg db " No streams resources", 0
    errno_63_msg_len equ $ - errno_63_msg

    errno_64_msg db " Machine is not on the network", 0
    errno_64_msg_len equ $ - errno_64_msg

    errno_65_msg db " Package not installed", 0
    errno_65_msg_len equ $ - errno_65_msg

    errno_66_msg db " Object is remote", 0
    errno_66_msg_len equ $ - errno_66_msg

    errno_67_msg db " Link has been severed", 0
    errno_67_msg_len equ $ - errno_67_msg

    errno_68_msg db " Advertise error", 0
    errno_68_msg_len equ $ - errno_68_msg

    errno_69_msg db " Srmount error", 0
    errno_69_msg_len equ $ - errno_69_msg

    errno_70_msg db " Communication error on send", 0
    errno_70_msg_len equ $ - errno_70_msg

    errno_71_msg db " Protocol error", 0
    errno_71_msg_len equ $ - errno_71_msg

    errno_72_msg db " Multihop attempted", 0
    errno_72_msg_len equ $ - errno_72_msg

    errno_73_msg db " RFS specific error", 0
    errno_73_msg_len equ $ - errno_73_msg

    errno_74_msg db " Bad message", 0
    errno_74_msg_len equ $ - errno_74_msg

    errno_75_msg db " Value too large for defined data type", 0
    errno_75_msg_len equ $ - errno_75_msg

    errno_76_msg db " Name not unique on network", 0
    errno_76_msg_len equ $ - errno_76_msg

    errno_77_msg db " File descriptor in bad state", 0
    errno_77_msg_len equ $ - errno_77_msg

    errno_78_msg db " Remote address changed", 0
    errno_78_msg_len equ $ - errno_78_msg

    errno_79_msg db " Cannot access a needed shared library", 0
    errno_79_msg_len equ $ - errno_79_msg

    errno_80_msg db " Accessing a corrupted shared library", 0
    errno_80_msg_len equ $ - errno_80_msg

    errno_81_msg db " .lib section in a.out corrupted", 0
    errno_81_msg_len equ $ - errno_81_msg

    errno_82_msg db " Attempting to link in too many shared libraries", 0
    errno_82_msg_len equ $ - errno_82_msg

    errno_83_msg db " Cannot exec a shared library directly", 0
    errno_83_msg_len equ $ - errno_83_msg

    errno_84_msg db " Invalid or incomplete multibyte or wide character", 0
    errno_84_msg_len equ $ - errno_84_msg

    errno_85_msg db " Interrupted system call should be restarted", 0
    errno_85_msg_len equ $ - errno_85_msg

    errno_86_msg db " Streams pipe error", 0
    errno_86_msg_len equ $ - errno_86_msg

    errno_87_msg db " Too many users", 0
    errno_87_msg_len equ $ - errno_87_msg

    errno_88_msg db " Socket operation on non-socket", 0
    errno_88_msg_len equ $ - errno_88_msg

    errno_89_msg db " Destination address required", 0
    errno_89_msg_len equ $ - errno_89_msg

    errno_90_msg db " Message too long", 0
    errno_90_msg_len equ $ - errno_90_msg

    errno_91_msg db " Protocol wrong type for socket", 0
    errno_91_msg_len equ $ - errno_91_msg

    errno_92_msg db " Protocol not available", 0
    errno_92_msg_len equ $ - errno_92_msg

    errno_93_msg db " Protocol not supported", 0
    errno_93_msg_len equ $ - errno_93_msg

    errno_94_msg db " Socket type not supported", 0
    errno_94_msg_len equ $ - errno_94_msg

    errno_95_msg db " Operation not supported", 0
    errno_95_msg_len equ $ - errno_95_msg

    errno_96_msg db " Protocol family not supported", 0
    errno_96_msg_len equ $ - errno_96_msg

    errno_97_msg db " Address family not supported by protocol", 0
    errno_97_msg_len equ $ - errno_97_msg

    errno_98_msg db " Address already in use", 0
    errno_98_msg_len equ $ - errno_98_msg

    errno_99_msg db " Cannot assign requested address", 0
    errno_99_msg_len equ $ - errno_99_msg

    errno_100_msg db " Network is down", 0
    errno_100_msg_len equ $ - errno_100_msg

    errno_101_msg db " Network is unreachable", 0
    errno_101_msg_len equ $ - errno_101_msg

    errno_102_msg db " Network dropped connection on reset", 0
    errno_102_msg_len equ $ - errno_102_msg

    errno_103_msg db " Software caused connection abort", 0
    errno_103_msg_len equ $ - errno_103_msg

    errno_104_msg db " Connection reset by peer", 0
    errno_104_msg_len equ $ - errno_104_msg

    errno_105_msg db " No buffer space available", 0
    errno_105_msg_len equ $ - errno_105_msg

    errno_106_msg db " Transport endpoint is already connected", 0
    errno_106_msg_len equ $ - errno_106_msg

    errno_107_msg db " Transport endpoint is not connected", 0
    errno_107_msg_len equ $ - errno_107_msg

    errno_108_msg db " Cannot send after transport endpoint shutdown", 0
    errno_108_msg_len equ $ - errno_108_msg

    errno_109_msg db " Too many references: cannot splice", 0
    errno_109_msg_len equ $ - errno_109_msg

    errno_110_msg db " Connection timed out", 0
    errno_110_msg_len equ $ - errno_110_msg

    errno_111_msg db " Connection refused", 0
    errno_111_msg_len equ $ - errno_111_msg

    errno_112_msg db " Host is down", 0
    errno_112_msg_len equ $ - errno_112_msg

    errno_113_msg db " No route to host", 0
    errno_113_msg_len equ $ - errno_113_msg

    errno_114_msg db " Operation already in progress", 0
    errno_114_msg_len equ $ - errno_114_msg

    errno_115_msg db " Operation now in progress", 0
    errno_115_msg_len equ $ - errno_115_msg

    errno_116_msg db " Stale file handle", 0
    errno_116_msg_len equ $ - errno_116_msg

    errno_117_msg db " Structure needs cleaning", 0
    errno_117_msg_len equ $ - errno_117_msg

    errno_118_msg db " Not a XENIX named type file", 0
    errno_118_msg_len equ $ - errno_118_msg

    errno_119_msg db " No XENIX semaphores available", 0
    errno_119_msg_len equ $ - errno_119_msg

    errno_120_msg db " Is a named type file", 0
    errno_120_msg_len equ $ - errno_120_msg

    errno_121_msg db " Remote I/O error", 0
    errno_121_msg_len equ $ - errno_121_msg

    errno_122_msg db " Disk quota exceeded", 0
    errno_122_msg_len equ $ - errno_122_msg

    errno_123_msg db " No medium found", 0
    errno_123_msg_len equ $ - errno_123_msg

    errno_124_msg db " Wrong medium type", 0
    errno_124_msg_len equ $ - errno_124_msg

    errno_125_msg db " Operation canceled", 0
    errno_125_msg_len equ $ - errno_125_msg

    errno_126_msg db " Required key not available", 0
    errno_126_msg_len equ $ - errno_126_msg

    errno_127_msg db " Key has expired", 0
    errno_127_msg_len equ $ - errno_127_msg

    errno_128_msg db " Key has been revoked", 0
    errno_128_msg_len equ $ - errno_128_msg

    errno_129_msg db " Key was rejected by service", 0
    errno_129_msg_len equ $ - errno_129_msg

    errno_130_msg db " Owner died", 0
    errno_130_msg_len equ $ - errno_130_msg

    errno_131_msg db " State not recoverable", 0
    errno_131_msg_len equ $ - errno_131_msg

    errno_132_msg db " Operation not possible due to RF-kill", 0
    errno_132_msg_len equ $ - errno_132_msg

    errno_133_msg db " Memory page has hardware error", 0
    errno_133_msg_len equ $ - errno_133_msg


section .text

extern _print_with_new_line


global _print_error_with_new_line


; rax: error number -ve (the original one)
_print_error_with_new_line:
	neg rax 			; because ei pass -ve error and i need to compare with positive

    CHECK_ERRNO EPERM,           .errno_1
    CHECK_ERRNO ENOENT,          .errno_2
    CHECK_ERRNO ESRCH,           .errno_3
    CHECK_ERRNO EINTR,           .errno_4
    CHECK_ERRNO EIO,             .errno_5
    CHECK_ERRNO ENXIO,           .errno_6
    CHECK_ERRNO E2BIG,            .errno_7
    CHECK_ERRNO ENOEXEC,          .errno_8
    CHECK_ERRNO EBADF,            .errno_9
    CHECK_ERRNO ECHILD,           .errno_10
    CHECK_ERRNO EAGAIN,           .errno_11
    CHECK_ERRNO ENOMEM,           .errno_12
    CHECK_ERRNO EACCES,           .errno_13
    CHECK_ERRNO EFAULT,           .errno_14
    CHECK_ERRNO ENOTBLK,          .errno_15
    CHECK_ERRNO EBUSY,            .errno_16
    CHECK_ERRNO EEXIST,           .errno_17
    CHECK_ERRNO EXDEV,            .errno_18
    CHECK_ERRNO ENODEV,           .errno_19
    CHECK_ERRNO ENOTDIR,          .errno_20
    CHECK_ERRNO EISDIR,           .errno_21
    CHECK_ERRNO EINVAL,           .errno_22
    CHECK_ERRNO ENFILE,           .errno_23
    CHECK_ERRNO EMFILE,           .errno_24
    CHECK_ERRNO ENOTTY,           .errno_25
    CHECK_ERRNO ETXTBSY,          .errno_26
    CHECK_ERRNO EFBIG,            .errno_27
    CHECK_ERRNO ENOSPC,           .errno_28
    CHECK_ERRNO ESPIPE,           .errno_29
    CHECK_ERRNO EROFS,            .errno_30
    CHECK_ERRNO EMLINK,           .errno_31
    CHECK_ERRNO EPIPE,            .errno_32
    CHECK_ERRNO EDOM,             .errno_33
    CHECK_ERRNO ERANGE,           .errno_34
    CHECK_ERRNO EDEADLK,          .errno_35
    CHECK_ERRNO ENAMETOOLONG,     .errno_36
    CHECK_ERRNO ENOLCK,           .errno_37
    CHECK_ERRNO ENOSYS,           .errno_38
    CHECK_ERRNO ENOTEMPTY,        .errno_39
    CHECK_ERRNO ELOOP,            .errno_40

    CHECK_ERRNO ENOMSG,           .errno_42
    CHECK_ERRNO EIDRM,            .errno_43
    CHECK_ERRNO ECHRNG,           .errno_44
    CHECK_ERRNO EL2NSYNC,         .errno_45
    CHECK_ERRNO EL3HLT,           .errno_46
    CHECK_ERRNO EL3RST,           .errno_47
    CHECK_ERRNO ELNRNG,           .errno_48
    CHECK_ERRNO EUNATCH,          .errno_49
    CHECK_ERRNO ENOCSI,           .errno_50
    CHECK_ERRNO EL2HLT,           .errno_51
    CHECK_ERRNO EBADE,            .errno_52
    CHECK_ERRNO EBADR,            .errno_53
    CHECK_ERRNO EXFULL,           .errno_54
    CHECK_ERRNO ENOANO,           .errno_55
    CHECK_ERRNO EBADRQC,          .errno_56
    CHECK_ERRNO EBADSLT,          .errno_57

    CHECK_ERRNO EBFONT,           .errno_59
    CHECK_ERRNO ENOSTR,           .errno_60
    CHECK_ERRNO ENODATA,          .errno_61
    CHECK_ERRNO ETIME,            .errno_62
    CHECK_ERRNO ENOSR,            .errno_63
    CHECK_ERRNO ENONET,           .errno_64
    CHECK_ERRNO ENOPKG,           .errno_65
    CHECK_ERRNO EREMOTE,          .errno_66
    CHECK_ERRNO ENOLINK,          .errno_67
    CHECK_ERRNO EADV,             .errno_68
    CHECK_ERRNO ESRMNT,           .errno_69
    CHECK_ERRNO ECOMM,            .errno_70
    CHECK_ERRNO EPROTO,           .errno_71
    CHECK_ERRNO EMULTIHOP,        .errno_72
    CHECK_ERRNO EDOTDOT,          .errno_73
    CHECK_ERRNO EBADMSG,          .errno_74
    CHECK_ERRNO EOVERFLOW,        .errno_75
    CHECK_ERRNO ENOTUNIQ,         .errno_76
    CHECK_ERRNO EBADFD,           .errno_77
    CHECK_ERRNO EREMCHG,          .errno_78
    CHECK_ERRNO ELIBACC,          .errno_79
    CHECK_ERRNO ELIBBAD,          .errno_80
    CHECK_ERRNO ELIBSCN,          .errno_81
    CHECK_ERRNO ELIBMAX,          .errno_82
    CHECK_ERRNO ELIBEXEC,         .errno_83
    CHECK_ERRNO EILSEQ,           .errno_84
    CHECK_ERRNO ERESTART,         .errno_85
    CHECK_ERRNO ESTRPIPE,         .errno_86
    CHECK_ERRNO EUSERS,           .errno_87
    CHECK_ERRNO ENOTSOCK,         .errno_88
    CHECK_ERRNO EDESTADDRREQ,     .errno_89
    CHECK_ERRNO EMSGSIZE,         .errno_90
    CHECK_ERRNO EPROTOTYPE,       .errno_91
    CHECK_ERRNO ENOPROTOOPT,      .errno_92
    CHECK_ERRNO EPROTONOSUPPORT,  .errno_93
    CHECK_ERRNO ESOCKTNOSUPPORT,  .errno_94
    CHECK_ERRNO EOPNOTSUPP,       .errno_95
    CHECK_ERRNO EPFNOSUPPORT,     .errno_96
    CHECK_ERRNO EAFNOSUPPORT,     .errno_97
    CHECK_ERRNO EADDRINUSE,       .errno_98
    CHECK_ERRNO EADDRNOTAVAIL,    .errno_99
    CHECK_ERRNO ENETDOWN,         .errno_100
    CHECK_ERRNO ENETUNREACH,      .errno_101
    CHECK_ERRNO ENETRESET,        .errno_102
    CHECK_ERRNO ECONNABORTED,     .errno_103
    CHECK_ERRNO ECONNRESET,       .errno_104
    CHECK_ERRNO ENOBUFS,          .errno_105
    CHECK_ERRNO EISCONN,          .errno_106
    CHECK_ERRNO ENOTCONN,         .errno_107
    CHECK_ERRNO ESHUTDOWN,        .errno_108
    CHECK_ERRNO ETOOMANYREFS,     .errno_109
    CHECK_ERRNO ETIMEDOUT,        .errno_110
    CHECK_ERRNO ECONNREFUSED,     .errno_111
    CHECK_ERRNO EHOSTDOWN,        .errno_112
    CHECK_ERRNO EHOSTUNREACH,     .errno_113
    CHECK_ERRNO EALREADY,         .errno_114
    CHECK_ERRNO EINPROGRESS,      .errno_115
    CHECK_ERRNO ESTALE,           .errno_116
    CHECK_ERRNO EUCLEAN,          .errno_117
    CHECK_ERRNO ENOTNAM,          .errno_118
    CHECK_ERRNO ENAVAIL,          .errno_119
    CHECK_ERRNO EISNAM,           .errno_120
    CHECK_ERRNO EREMOTEIO,        .errno_121
    CHECK_ERRNO EDQUOT,           .errno_122
    CHECK_ERRNO ENOMEDIUM,        .errno_123
    CHECK_ERRNO EMEDIUMTYPE,      .errno_124
    CHECK_ERRNO ECANCELED,        .errno_125
    CHECK_ERRNO ENOKEY,           .errno_126
    CHECK_ERRNO EKEYEXPIRED,      .errno_127
    CHECK_ERRNO EKEYREVOKED,      .errno_128
    CHECK_ERRNO EKEYREJECTED,     .errno_129
    CHECK_ERRNO EOWNERDEAD,       .errno_130
    CHECK_ERRNO ENOTRECOVERABLE,  .errno_131
    CHECK_ERRNO ERFKILL,          .errno_132
    CHECK_ERRNO EHWPOISON,        .errno_133

    ret ; if no error was found handle later


	PRINT_ERRNO 1
	PRINT_ERRNO 2
	PRINT_ERRNO 3
	PRINT_ERRNO 4
	PRINT_ERRNO 5
	PRINT_ERRNO 6
	PRINT_ERRNO 7
	PRINT_ERRNO 8
	PRINT_ERRNO 9
	PRINT_ERRNO 10
	PRINT_ERRNO 11
	PRINT_ERRNO 12
	PRINT_ERRNO 13
	PRINT_ERRNO 14
	PRINT_ERRNO 15
	PRINT_ERRNO 16
	PRINT_ERRNO 17
	PRINT_ERRNO 18
	PRINT_ERRNO 19
	PRINT_ERRNO 20
	PRINT_ERRNO 21
	PRINT_ERRNO 22
	PRINT_ERRNO 23
	PRINT_ERRNO 24
	PRINT_ERRNO 25
	PRINT_ERRNO 26
	PRINT_ERRNO 27
	PRINT_ERRNO 28
	PRINT_ERRNO 29
	PRINT_ERRNO 30
	PRINT_ERRNO 31
	PRINT_ERRNO 32
	PRINT_ERRNO 33
	PRINT_ERRNO 34
	PRINT_ERRNO 35
	PRINT_ERRNO 36
	PRINT_ERRNO 37
	PRINT_ERRNO 38
	PRINT_ERRNO 39
	PRINT_ERRNO 40

	PRINT_ERRNO 42
	PRINT_ERRNO 43
	PRINT_ERRNO 44
	PRINT_ERRNO 45
	PRINT_ERRNO 46
	PRINT_ERRNO 47
	PRINT_ERRNO 48
	PRINT_ERRNO 49
	PRINT_ERRNO 50
	PRINT_ERRNO 51
	PRINT_ERRNO 52
	PRINT_ERRNO 53
	PRINT_ERRNO 54
	PRINT_ERRNO 55
	PRINT_ERRNO 56
	PRINT_ERRNO 57

	PRINT_ERRNO 59
	PRINT_ERRNO 60
	PRINT_ERRNO 61
	PRINT_ERRNO 62
	PRINT_ERRNO 63
	PRINT_ERRNO 64
	PRINT_ERRNO 65
	PRINT_ERRNO 66
	PRINT_ERRNO 67
	PRINT_ERRNO 68
	PRINT_ERRNO 69
	PRINT_ERRNO 70
	PRINT_ERRNO 71
	PRINT_ERRNO 72
	PRINT_ERRNO 73
	PRINT_ERRNO 74
	PRINT_ERRNO 75
	PRINT_ERRNO 76
	PRINT_ERRNO 77
	PRINT_ERRNO 78
	PRINT_ERRNO 79
	PRINT_ERRNO 80
	PRINT_ERRNO 81
	PRINT_ERRNO 82
	PRINT_ERRNO 83
	PRINT_ERRNO 84
	PRINT_ERRNO 85
	PRINT_ERRNO 86
	PRINT_ERRNO 87
	PRINT_ERRNO 88
	PRINT_ERRNO 89
	PRINT_ERRNO 90
	PRINT_ERRNO 91
	PRINT_ERRNO 92
	PRINT_ERRNO 93
	PRINT_ERRNO 94
	PRINT_ERRNO 95
	PRINT_ERRNO 96
	PRINT_ERRNO 97
	PRINT_ERRNO 98
	PRINT_ERRNO 99
	PRINT_ERRNO 100
	PRINT_ERRNO 101
	PRINT_ERRNO 102
	PRINT_ERRNO 103
	PRINT_ERRNO 104
	PRINT_ERRNO 105
	PRINT_ERRNO 106
	PRINT_ERRNO 107
	PRINT_ERRNO 108
	PRINT_ERRNO 109
	PRINT_ERRNO 110
	PRINT_ERRNO 111
	PRINT_ERRNO 112
	PRINT_ERRNO 113
	PRINT_ERRNO 114
	PRINT_ERRNO 115
	PRINT_ERRNO 116
	PRINT_ERRNO 117
	PRINT_ERRNO 118
	PRINT_ERRNO 119
	PRINT_ERRNO 120
	PRINT_ERRNO 121
	PRINT_ERRNO 122
	PRINT_ERRNO 123
	PRINT_ERRNO 124
	PRINT_ERRNO 125
	PRINT_ERRNO 126
	PRINT_ERRNO 127
	PRINT_ERRNO 128
	PRINT_ERRNO 129
	PRINT_ERRNO 130
	PRINT_ERRNO 131
	PRINT_ERRNO 132
	PRINT_ERRNO 133

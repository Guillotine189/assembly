%ifndef _MYMALLOC_INC
%define  _MYMALLOC_INC

MYMALLOC_SIZE_OFF 		equ 0
MYMALLOC_USED_OFF 		equ 8
MYMALLOC_PREV_OFF 		equ 16
MYMALLOC_NEXT_OFF 		equ 24


extern _malloc
extern _free
extern _print_malloc_segments_info
extern _print_more_malloc_info
extern _print_detailed_malloc
extern _print_free_list_info

%endif
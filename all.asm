FORMAT MZ
HEAP 0
include "macros.asm"
include "stack64.asm"
include "stack32.asm"
include "data64.asm"
include "data32.asm"
include "stack16.asm"
include "data16.asm"
include "code64.asm"
include "code32.asm"
include "code16.asm"

USE64
SEGMENT U64 USE64
a_proc_64:
	nop
	nop
	nop
	nop 
	nop
	nop
	xor rax,rax
	ret

USE32

SEGMENT U32 USE32
a_proc_32:
    nop
	nop
	nop
	ret
USE16
SEGMENT U16 USE16
ORG 0

start16:
	CLI
	mov ax,DATA16
	mov ds,ax

	mov ax,STACK16
	mov sp,stack16_end
	mov ss,ax

	call far CODE16:F_InstallVector50
	STI

	mov ax,DATA16
	mov ds,ax
	mov ax,0x0900
	mov dx, msg_hello
	int 21h


; Initialize 
	mov eax,1
	int 50h

; Enter Unreal
	mov eax,2
	int 50h

; Call a far proc
	mov eax,3
	linear edx,a_proc_32,U32
	int 50h

; Call a long proc

	mov eax,4
	xor ecx,ecx
	linear edx,a_proc_64,U64
	int 50h

; End
	mov ax,0x4c00
	int 21h

entry U16:start16

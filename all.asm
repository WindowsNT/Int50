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

	; Call a long proc from pmode
;	mov eax,4
;	xor ecx,ecx
;	linear edx,a_proc_64,U64
;	xchg bx,bx
;	int 50h
;	xchg bx,bx
	ret
USE16
SEGMENT U16 USE16
ORG 0

Thread16_1:
	db 4096 dup (144) ; fill NOPs for alignment
	
	mov ax,DATA16
	mov ds,ax
	mov dx, msg_hello2
	mov ax,0x0900
	int 21h
	hlt
	hlt

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


; Initialize 
	mov eax,1
	int 50h

; Enter Unreal
	mov eax,2
	int 50h

 ; A thread
	mov eax,5
	linear edx,Thread16_1,U16
	mov ebx,1
	int 50h
	MOV AH,86H
	MOV CX,100
	MOV DX,10*1000 
	INT 15H

; Call a far proc
	mov eax,3
	linear edx,a_proc_32,U32
	int 50h

; Call a long proc
	mov eax,4
	xor ecx,ecx
	linear edx,a_proc_64,U64
	int 50h

; Message
	mov ax,0x0900
	mov dx, msg_hello
	int 21h


; End
	mov ax,0x4c00
	int 21h

entry U16:start16

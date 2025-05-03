USE16
SEGMENT CODE16 USE16
ORG 0h


include "r0.asm"

F_Handler50:

include "r1.asm"
include "r2.asm"
include "r3.asm"
include "r4.asm"
iret

F_InstallVector50:

	; Install the vector for the 50h interrupt
	; This is the interrupt for the V86 mode
	; This is used to install the V86 mode handler

	mov ax,0x3550
	int 0x21
	push ds
	push cs
	pop ds
	mov dx,F_Handler50
	mov ax,0x2550
	int 0x21
	pop ds
	retf




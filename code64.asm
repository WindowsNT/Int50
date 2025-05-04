; --------------------------------------- 64 bit Code ---------------------------------------
SEGMENT DMMI_CODE
ORG 0h
CODE64 = DMMI_CODE
USE64

include "l0.asm"
L_Handler50:
include "l1.asm"
include "l7.asm"
include "l10.asm"
iretq


; --------------------------------------- 64 bit Code ---------------------------------------
Start64:

xor rax,rax
mov ax,stack64_idx
mov ss,ax
nop
nop
nop
nop

; set the interrupts
linear rax,idt_LM_start,DMMI_DATA
lidt [rax]
sti

mov rax,1
int 0x50

; ecx:edx is the address to call
xor rax,rax
mov eax,ecx
shl rax,32
mov eax,edx
call rax

; End long mode

push code32_idx    ; The selector of the compatibility code segment
xor rcx,rcx    
mov ecx,Back32From64    ; The address must be an 64-bit address,
                  ; so upper 32-bits of RCX are zero.
push rcx
retf
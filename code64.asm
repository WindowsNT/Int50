; --------------------------------------- 64 bit Code ---------------------------------------
SEGMENT CODE64 USE64
ORG 0h


include "l0.asm"
L_Handler50:
include "l1.asm"
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
linear rax,idt_LM_start,DATA16
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
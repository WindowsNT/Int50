USE16

; AX = 3
; Call 32-bit protected mode function
; EDX = linear address of far function

cmp ax,3
jnz F_Handler50_No3

; Enter PM
cli
mov ax,DATA16
mov ds,ax
mov [current_sp_16],sp
lidt fword [idt_PM_start]
mov ebx,3
mov eax,cr0
or eax,1
mov cr0,eax
jmp code32_idx:start32_3

F_GoingBackFrom3: ; PM here 16 bit
	cli
	mov eax,cr0
	and eax,0fffffffeh
	mov cr0,eax
	mov ax,DATA16
	mov ds,ax
	mov ax,[current_sp_16]
	xor esp,esp
	mov sp,ax
	mov ax,STACK16
	mov ss,ax
	lidt fword [save_rm_idt]
	sti
	db 0xEA               ; Opcode for JMP FAR ptr16:16
	dw F_GoingBackFrom3b  ; Offset
	dw CODE16             ; Segment
F_GoingBackFrom3b:
	iret

F_Handler50_No3:

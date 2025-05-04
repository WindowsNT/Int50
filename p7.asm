USE32

; AX = 7
; Call 16-bit real mode function
; CX:DX seg:ofs

cmp ax,7
jnz P_Handler50_No7

; RM32 -> RM16 -> PM 16, run and then switch back to PM

    ; RM32 here
	cli
	JMP code32as16_idx:tt0

	USE16
	; RM16 here
	tt0:
	nop
	nop
	nop
	mov eax,cr0
	and eax,0fffffffeh
	mov cr0,eax
	db 0xEA               
	dw tt1 ; Offset
	dw CODE32             ; Segment

	; RM here
	USE16
	tt1:
	nop
	nop
	nop
	mov ax,DMMI_DATA
	mov ds,ax
	xor eax,eax
	mov ax,STACK_SEGMENT
	shl eax,4
	sub esp,eax
	mov ax,STACK_SEGMENT
	mov ss,ax
	lidt fword [save_rm_idt]
	sti

	; call it
	; to return here
	push cs
	push tt1a

	; to call it
	push cx
	push dx
	retf

	tt1a:
	cli
	mov ax,DMMI_DATA
	mov ds,ax
	lidt fword [idt_PM_start]
	mov eax,cr0
	or eax,1
	mov cr0,eax
	jmp code32_idx:tt2

	USE32
	tt2:
	linear ebp,esp,STACK_SEGMENT
	mov esp,ebp
	mov ax,stack32_idx
	mov ss,ax
	sti



iretd
P_Handler50_No7:

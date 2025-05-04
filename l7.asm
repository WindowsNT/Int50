USE64

; AX = 7
; Call 16-bit real mode function
; CX:DX seg:ofs

cmp ax,7
jnz L_Handler50_No7

	cli

	; Jump to compatibility
	push code64as32_idx    ; The selector of the compatibility code segment
	xor rsi,rsi    
	mov esi,tl1    ; The address must be an 64-bit address so upper 32-bits of RCX are zero.
	push rsi
	retf

	tl1:
	USE32
	nop
	nop
	nop
	; disable paging
	mov eax, cr0 ; Read CR0.
	and eax,7fffffffh ; Set PE=0.
	mov cr0, eax ; Write CR0.
	; PM32 here
	JMP code64as16_idx:tl2
	tl2:
	USE16
	; PM16 here
	nop
	nop
	nop
	mov eax,cr0
	and eax,0fffffffeh
	mov cr0,eax

	db 0xEA               
	dw tl1x ; Offset
	dw CODE64 
	; RM here
	USE16
	tl1x:
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
	push tl2aa

	; to call it
	push cx
	push dx
	retf

	tl2aa:
	cli
	mov ax,DMMI_DATA
	mov ds,ax
	lidt fword [idt_PM_start]
	mov eax,cr0
	or eax,1
	mov cr0,eax
	; PM16 here
	jmp code64as32_idx:tl4

	USE32
	tl4:
	; PM32 here
	nop
	nop
	nop
	; Enable paging
	mov eax, cr0 ; Read CR0.
	or eax,80000000h ; Set PE=1 
	mov cr0, eax ; Write CR0.
	; Compatibility mode here
	db 0eah
	LinearAddressOfReturn64:
	dd 0
	dw code64_idx

	tl4lm:
	USE64
	nop
	nop
	nop
	linear rbp,rsp,STACK_SEGMENT
	mov rsp,rbp
	mov ax,stack64_idx
	mov ss,ax
	sti


iretq
L_Handler50_No7:

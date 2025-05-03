USE16

PrepareGDT16:
	
	mov ax,DATA16
	mov ds,ax

	gdt_initialize32 0,code64_descriptor
	gdt_initialize32 0,data64_descriptor
	gdt_initialize32 CODE32,code32_descriptor
	gdt_initialize32 0,flatcode32_descriptor
	gdt_initialize32 DATA32,data32_descriptor
	gdt_initialize32 0,flatdata32_descriptor
	gdt_initialize32 STACK32,stack32_descriptor
	gdt_initialize32 CODE16,code16_descriptor
	gdt_initialize32 DATA16,data16_descriptor
	gdt_initialize32 STACK16,stack16_descriptor

	; Set gdt ptr
	linear eax,dummy_descriptor,DATA16
	mov dword [gdt_ptr],eax

	; Set GDT
	mov bx, gdt_start
	lgdt [ds:bx]
	ret

PrepareIDTFor32:
	
	mov ax,DATA16
	mov ds,ax
	sidt fword [save_rm_idt]

	push es
	push ds
	pop es
	mov di, interruptsall
	mov cx, 256 * 4      ; 4 words (8 bytes) per entry  1024 words
	xor ax, ax
	rep stosw
	pop es

	 ; Build INT 0x50 entry in the future protected mode IDT
    mov eax, P_Handler50                        ; full 64-bit handler address
    mov word [interruptsall + 0x50*8], ax       ; offset low (bits 0–15)
    mov word [interruptsall + 0x50*8 + 2], code32_idx ; selector
    mov byte [interruptsall + 0x50*8 + 4], 0    ; zero byte
    mov byte [interruptsall + 0x50*8 + 5], 10001110b ; type: 32-bit interrupt gate, present
    shr eax, 16
    mov word [interruptsall + 0x50*8 + 6], ax   ; offset high (bits 16–31)

    ; Initialize IDT pointer for protected mode (6 bytes: limit + base)
    mov word [idt_PM_start], idt_size32           ; limit
    mov dword [idt_PM_ptr], interruptsall       ; linear address of IDT base
	
	xor eax,eax
	mov     ax,DATA16
	shl     eax,4
	add     ax,interruptsall
	mov     [idt_PM_ptr],eax

	
	ret


PrepareIDTFor64:
	
	mov ax,DATA16
	mov ds,ax
	push es
	push ds
	pop es
	mov di, interruptsall64
	mov cx, 256 * 8      ; 8 words (16 bytes) per entry  
	xor ax, ax
	rep stosw
	pop es

	 ; Build INT 0x50 entry in the future protected mode IDT
    linear eax, L_Handler50,CODE64                        ; full 64-bit handler address
    mov word [interruptsall64 + 0x50*16], ax       ; offset low (bits 0–15)
    mov word [interruptsall64 + 0x50*16 + 2], code64_idx ; selector
    mov byte [interruptsall64 + 0x50*16 + 4], 0    ; zero byte
    mov byte [interruptsall64 + 0x50*16 + 5], 10001110b ; type: 32-bit interrupt gate, present
    shr eax, 16
    mov word [interruptsall64 + 0x50*16 + 6], ax   ; offset high (bits 16–31)

    ; Initialize IDT pointer for longmode (6 bytes: limit + base)
    mov word [idt_LM_start], idt_size64           ; limit
    mov dword [idt_LM_ptr], interruptsall64       ; linear address of IDT base
	
	xor eax,eax
	mov     ax,DATA16
	shl     eax,4
	add     ax,interruptsall64
	mov     [idt_LM_ptr],eax

	
	ret


PrepareLong:

	; and the linear 64 start
	push es
	mov ax,CODE32
	mov es,ax
	mov edi,LinearAddressOfStart64
	linear eax,Start64,CODE64
	mov [es:edi],eax
	pop es
	ret



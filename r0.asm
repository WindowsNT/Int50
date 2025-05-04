USE16

;
; EnableA20
; -------------------------------
;
WaitKBC:
mov cx,0ffffh
A20L:
in al,64h
test al,2
loopnz A20L
ret
EnableA20:
call WaitKBC
mov al,0d1h
out 64h,al
call WaitKBC
mov al,0dfh
out 60h,al
ret
;
; -------------------------------
;



PrepareGDT16:
	
	mov ax,DMMI_DATA
	mov ds,ax
	call EnableA20

	gdt_initialize32 0,code64_descriptor
	gdt_initialize32 0,data64_descriptor
	gdt_initialize32 0,stack64_descriptor
	gdt_initialize32 CODE32,code32_descriptor
	gdt_initialize32 0,flatcode32_descriptor
	gdt_initialize32 0,flatdata32_descriptor
	gdt_initialize32 0,flatstack32_descriptor
	gdt_initialize32 CODE16,code16_descriptor
	gdt_initialize32 DMMI_DATA,data16_descriptor

	; Set gdt ptr
	linear eax,dummy_descriptor,DMMI_DATA
	mov dword [gdt_ptr],eax

	; Set GDT
	mov bx, gdt_start
	lgdt [ds:bx]
	ret

PrepareIDTFor32:
	
	mov ax,DMMI_DATA
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
	mov     ax,DMMI_DATA
	shl     eax,4
	add     ax,interruptsall
	mov     [idt_PM_ptr],eax

	
	ret


PrepareIDTFor64:
	
	mov ax,DMMI_DATA
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
	mov     ax,DMMI_DATA
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


; Returns APIC in EBX
; implemented as FAR to allow calling from elsewhere
GetMyApic16f:
	push eax
	push ecx
	push edx
	mov eax,1
	cpuid
	bt edx,9
	jc ApicFound
	xor ebx,ebx
	ApicFound:
	and ebx,0xff000000
	shr ebx,24
	pop edx
	pop ecx
	pop eax
retf

;-------------------------------------------------------------------------------------------
; Function ChecksumValid : Check the sum. EDI physical addr, ECX count
;-------------------------------------------------------------------------------------------		
ChecksumValid:
	PUSH ECX
	PUSH EDI
	XOR EAX,EAX
	.St:
	ADD EAX,[FS:EDI]
	INC EDI
	DEC ECX
	JECXZ .End
	JMP .St
	.End:
	TEST EAX,0xFF
	JNZ .F
	MOV EAX,1
	.F:
	POP EDI
	POP ECX
	RETF

;-------------------------------------------------------------------------------------------
; Function FillACPI : Finds RDSP, and then RDST or XDST
;-------------------------------------------------------------------------------------------	
FillACPI:
	push es
	mov es,[fs:040eh]
	xor edi,edi
	mov di,[es:0]
	pop es
	mov edi, 0x000E0000	
	.s:
	cmp edi, 0x000FFFFF	; 
	jge .noACPI			; Fail.
	mov eax,[fs:edi]
	add edi,4
	mov edx,[fs:edi]
	add edi,4
	cmp eax,0x20445352
	jnz .s
	cmp edx,0x20525450
	jnz .s
	jmp .found
	.noACPI:
	mov EAX,0xFFFFFFFF
RETF
	.found:

	; Found at EDI
	sub edi,8
	mov esi,edi
	; 36 bytes for ACPI 2
	mov ecx,36
	push cs
	call ChecksumValid
	cmp eax,1
	jnz .noACPI2
	mov eax,[fs:edi + 24]
	mov dword [ds:XsdtAddress],eax
	mov eax,[fs:edi + 28]
	mov dword [ds:XsdtAddress + 4],eax
	mov edi,dword [ds:XsdtAddress]
	mov eax,[fs:edi]
	cmp eax, 'XSDT'			; Valid?
	jnz .noACPI2
RETF
	.noACPI2:
	mov edi,esi
	mov ecx,20
	push cs
	call ChecksumValid
	cmp eax,1
	jnz .noACPI
	mov eax,[fs:edi + 16]
	mov dword [ds:XsdtAddress],eax
	mov edi,dword [ds:XsdtAddress]
	mov eax,[fs:edi]
	cmp eax, 'RSDT'			; Valid?
	jnz .noACPI

	mov edi,dword [ds:XsdtAddress]
	mov dword [ds:XsdtAddress],0
	mov dword [ds:RsdtAddress],edi
RETF


;-------------------------------------------------------------------------------------------
; Function FindACPITableX : Finds EAX Table,  edi is rsdt/xsdt address and ecx is 4 or 8
;-------------------------------------------------------------------------------------------		
FindACPITableX:
	cmp edi,0
	jz .f

	; len, must be more than 36
	mov ebx,[fs:edi + 4]
	cmp ebx,36
	jle .f
	sub ebx,36 
	xor edx,edx

	.loop:
	cmp edx,ebx
	jz .f
	mov esi,[fs:edi + 36 + edx]
	cmp eax,[fs:esi]
	jnz .c
	mov eax,esi
RETF
	.c:
	add edx,ecx
	jmp .loop
	.f:
	mov eax,0ffffffffh
RETF

	
;-------------------------------------------------------------------------------------------
; Function DumpMadt : Fills from  EAX MADT
;-------------------------------------------------------------------------------------------		
DumpMadt: ; EAX
		
	pushad
	mov edi,eax
	mov [ds:numcpus],0

	mov ecx,[fs:edi + 4] ; length
	mov eax,[fs:edi + 0x24] ; Local APIC 
	mov [ds:LocalApic],eax

	add edi,0x2C
	sub ecx,0x2C
	.l1:
			
		xor ebx,ebx
		mov bl,[fs:edi + 1] ; length
		cmp bl,0
		jz .end ; duh
		sub ecx,ebx
			
		mov al,[fs:edi] ; type
		cmp al,0
		jnz .no0
			
		; This is a CPU!
		xor eax,eax
		mov al,[ds:numcpus]
		inc [ds:numcpus]
		mov edx,cpusstructize
		mul edx
		xor esi,esi
		mov si,cpus
		add esi,eax
		mov al,[fs:edi + 2]; ACPI id
		mov byte [ds:si],al
		mov al,[fs:edi + 3]; APIC id
		mov byte [ds:si + 4],al
			

		.no0:
			
		add edi,ebx
		
	jecxz .end
	jmp .l1
	.end:

	popad
RETF


PrepareACPI:

	mov ax,DMMI_DATA
	mov ds,ax
	push cs
	call GetMyApic16f
	mov [ds:MainCPUAPIC],bl

	mov ax, 0 
	mov fs, ax

	push cs
	call FillACPI
	cmp eax,0xFFFFFFFF
	jnz .coo
	jmp .noacpi
	.coo:

	cmp eax, 'XSDT'
	jz .ac2

	mov eax,'APIC'
	push cs
	mov ecx,4
	mov edi,[RsdtAddress]
	call FindACPITableX
	jmp .eac

	.ac2:
	mov eax,'APIC'
	push cs
	mov ecx,8
	mov edi,dword [XsdtAddress]
	call FindACPITableX

	.eac:
	cmp eax,0xFFFFFFFF
	jnz .coo2
	jmp .noacpi
	.coo2:
	push cs
	call DumpMadt
	.noacpi:

	ret


macro qlock16 trg,del = -1
	{
	push ds
	push di
	push ecx
	MOV DI,DMMI_DATA
	MOV DS,DI
	MOV DI,trg
	dec byte [ds:di]
	pop ecx
	pop di
	pop ds
	}

macro qunlock16 trg
	{
	push ds
	push di
	MOV DI,DMMI_DATA
	MOV DS,DI
	MOV DI,trg
	cmp byte [ds:di],0xFF
	jz .unlk
	inc byte [ds:di]
	.unlk:
	pop di
	pop ds
	}

qwait16:
	; ax = target mutex in DMMI_DATA
	push ds
	push di
	MOV DI,DMMI_DATA
	MOV DS,DI
	MOV DI,ax

	.Loop1:		
	CMP byte [ds:di],0xff
	JZ .OutLoop1
	pause 
	JMP .Loop1
	.OutLoop1:
	
	pop di
	pop ds
retf

qwaitlock16:
	; ax = target mutex in DMMI_DATA
	push bx
	push ds
	push di
	MOV DI,DMMI_DATA
	MOV DS,DI
	MOV DI,ax

	.Loop1:		
	CMP byte [ds:di],0xff
	JZ .OutLoop1
	pause 
	JMP .Loop1
	.OutLoop1:
	
	; Lock is free, can we grab it?
	mov bl,0xfe
	MOV AL,0xFF
	LOCK CMPXCHG [DS:DI],bl
	JNZ .Loop1 ; Write failed

	.OutLoop2: ; Lock Acquired

	pop di
	pop ds
	pop bx
retf


;-------------------------------------------------------------------------------------------
; Function SendSIPIf : Sends SIPI. EBX = CPU Index, EAX = linear
;-------------------------------------------------------------------------------------------		
SendSIPIf:
	PUSHAD
	PUSH DS
	mov cx,DMMI_DATA
	mov ds,cx
		
	XOR ECX,ECX
	; Spurious
	MOV EDI,[DS:LocalApic]
	ADD EDI,0x0F0
	MOV EDX,[FS:EDI]
	OR EDX,0x1FF
	MOV [FS:EDI],EDX
	; Vector
	.L1:
	MOV ECX,EAX
	TEST EAX,0xFFF
	JZ .L2
	INC EAX
	JMP .L1
	.L2:
	MOV ESI,EAX
	SHR ESI,12
	; Init
	MOV ECX,0x04500
	OR ECX,ESI
	push cs
	call SendIPI16
	; Delay 10 ms  = 0,01 s = (100 Hz)
	; 1193182/100
;		sleep16 11931
	MOV AH,86H
	MOV CX,0
	MOV DX,10*1000 ;10 ms
	INT 15H
	; SIPI 1
	MOV ECX,0x05600
	OR ECX,ESI
	push cs
	call SendIPI16
	; Delay 200 us = 0,2 ms = 0,0002 s = (5000 Hz)
	; 1193182/5000
;		sleep16 238
	MOV AH,86H
	MOV CX,0
	MOV DX,200 ; 200us
	INT 15H
	; SIPI 2
	MOV ECX,0x05600
	OR ECX,ESI
	push cs
	call SendIPI16
	POP DS
	POPAD
RETF


;-------------------------------------------------------------------------------------------
; Function SendIPI16 : Sends IPI. EBX = CPU Index, ECX = IPI
;-------------------------------------------------------------------------------------------		
SendIPI16: ; EBX = CPU INDEX, ECX = IPI
	PUSHAD
	; Lock Mutex		
	mov ax,mut_ipi
	push cs
	call qwaitlock16

		
	; Write it to 0x310
	; EBX is CPU INDEX
	; MAKE IT APIC ID
	xor eax,eax
	mov ax,cpusstructize
	mul bx
	add ax,cpus
	mov di,ax
	add di,4
	mov bl,[ds:di]
	MOV EDI,[DS:LocalApic]
	ADD EDI,0x310
	MOV EDX,[FS:EDI]
	AND EDX,0xFFFFFF
	XOR EAX,EAX
	MOV AL,BL
	SHL EAX,24
	OR EDX,EAX
	MOV [FS:EDI],EDX
		
		
	; Write it to 0x300
	MOV EDI,[DS:LocalApic]
	ADD EDI,0x300
	MOV [FS:EDI],ECX
	; Verify it got delivered
	.Verify:
	 PAUSE
	MOV EAX,[FS:EDI];
	SHR EAX,12
	TEST EAX,1
	JNZ .Verify
	; Write it to 0xB0 (EOI)
 
;	MOV EDI,[DS:LocalApic]
;	ADD EDI,0xB0
;    MOV dword [FS:EDI],0
		
	; Release Mutex
	qunlock16 mut_ipi
	POPAD
RETF




USE32


;-------------------------------------------------------------------------------------------
; Function SendSIPIf32 : Sends SIPI. EBX = CPU Index, EAX = linear
;-------------------------------------------------------------------------------------------		
SendSIPIf32:
	PUSHAD
	PUSH DS
	mov cx,flatdata32_idx
	mov ds,cx
		
	XOR ECX,ECX
	; Spurious
	linear eax,LocalApic,DMMI_DATA
	MOV EDI,[DS:EAX]
	ADD EDI,0x0F0
	MOV EDX,[DS:EDI]
	OR EDX,0x1FF
	MOV [DS:EDI],EDX
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
	call SendIPI32
	; Delay 10 ms  = 0,01 s = (100 Hz)

	; SIPI 1
	MOV ECX,0x05600
	OR ECX,ESI
	call SendIPI32

	; SIPI 2
	MOV ECX,0x05600
	OR ECX,ESI
	call SendIPI32
	POP DS
	POPAD
RET


;-------------------------------------------------------------------------------------------
; Function SendIPI32 : Sends IPI. EBX = CPU Index, ECX = IPI
;-------------------------------------------------------------------------------------------		
SendIPI32: ; EBX = CPU INDEX, ECX = IPI
	PUSHAD
	PUSH DS
	mov ax,flatdata32_idx
	mov ds,ax

	; Write it to 0x310
	; EBX is CPU INDEX
	; MAKE IT APIC ID
	xor eax,eax
	linear eax,cpusstructize,DMMI_DATA
	mul bx
	add ax,cpus
	mov di,ax
	add di,4
	mov bl,[ds:di]
	linear eax,LocalApic,DMMI_DATA
	MOV EDI,[DS:eax]
	ADD EDI,0x310
	MOV EDX,[DS:EDI]
	AND EDX,0xFFFFFF
	XOR EAX,EAX
	MOV AL,BL
	SHL EAX,24
	OR EDX,EAX
	MOV [DS:EDI],EDX
		
		
	; Write it to 0x300
	linear eax,LocalApic,DMMI_DATA
	MOV EDI,[DS:EAX]
	ADD EDI,0x300
	MOV [DS:EDI],ECX
	; Verify it got delivered
	.Verify:
	 PAUSE
	MOV EAX,[DS:EDI];
	SHR EAX,12
	TEST EAX,1
	JNZ .Verify
	; Write it to 0xB0 (EOI)
 
;	linear eax,LocalApic,DMMI_DATA
;	MOV EDI,[DS:EAX]
;	ADD EDI,0xB0
;    MOV dword [DS:EDI],0
		
	POP DS
	POPAD
RET


USE16


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
		
	POPAD
RETF




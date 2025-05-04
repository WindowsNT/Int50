USE64

; AX = 10, VMX operations

cmp ax,10
jnz L_Handler50_No10
jmp L_Handler50_Yes10



; ---------------- Init the structures ----------------
VMX_Init_Structures:

	 ; Read MSR
	 xor eax,eax
	 mov ecx,0480h
	 rdmsr

	 linear ecx,VMXRevision,DMMI_DATA
	 ; EAX holds the revision
	 ; EDX lower 13 bits hold the max size
	 mov [ecx],eax
	 and edx,8191
	 linear ecx,VMXStructureSize,DMMI_DATA
	 mov [ecx],edx
	 ; Initialize 4096 structure datas for VMX
	 xor eax,eax
	 mov ax,DMMI_DATA
	 shl eax,4 ; physical
	 Loop5X:
	 test eax,01fffh
	 jz Loop5End
	 inc eax
	 jmp Loop5X
	 Loop5End:
	 linear ecx,VMXStructureData1,DMMI_DATA
	 mov dword [ecx],eax
	 add eax,4096
	 linear ecx,VMXStructureData2,DMMI_DATA
	 mov dword [ecx],eax
RET

VMX_Enable:
	; cr4
	mov rax,cr4
	bts rax,13
	mov cr4,rax

    ; Load the revision
	linear rdi,VMXRevision,DMMI_DATA
	mov ebx,[edi];
	
	; Initialize the VMXON region
	linear rdi,VMXStructureData1,DMMI_DATA
	mov rcx,[rdi];  Get address of data1
	mov rsi,rdi
	mov rdi,rcx

	; CR0 bit 5
	mov rax,cr0
	bts rax,5
	mov cr0,rax
 
	; MSR 0x3ah lock bit 0
	mov ecx,03ah
	rdmsr
	test eax,1
	jnz .VMX_LB_Enabled
	or eax,1
	wrmsr
	.VMX_LB_Enabled:

	; Execute the VMXON
	mov [rdi],ebx ; // Put the revision
	mov rax,[rsi]
	VMXON [rsi]

RET

VMX_Initialize_VMX_Controls:
    ; edx = 0x82 for unrestricted guestm, 0x2 if simple with EPT

	vmw32 0x4012,0x11FF ; Entry. Ideally, we must read 0x484 MSR to learn what to put here
	; bit 9 - Guest is in long mode
	; bit 10 - Guest is in SMM
	; bit 11 - Deactivate Dual monitor treatment
	
	; We can use also 0x4014 to control MSRs -> if different than the host (mighty)
	vmw32 0x4000,0x1F ; PIN, Intel 3B Chapter 20.6.1
	; vmw32 0x4002,0x8401e9f2; Proc, Intel 3B Chapter 20.6.2
	vmw32 0x4002,0x840069F2; Proc, Intel 3B Chapter 20.6.2, Leave CR3 access so we can enable long mode

	vmw32 0x401E,edx
	vmw32 0x400C,0x36FFF
RET


VMX_Initialize_Host:
	; We initialize
	; CR0, CR3 , CR4
	; CS:RIP for entry after VMExit
	; SS:RSP for entry after VMExit
	; DS,ES,TR
	; GDTR,IDTR
	; RCX = IP

	; CRX

	vmw64 0x6C00,cr0
	vmw64 0x6C02,cr3
	vmw64 0x6C04,cr4

	; CS:RIP
	vmw16 0xC02,cs
	vmw64 0x6C16,rcx

	; SS:RSP
	vmw16 0xC04,ss
	vmw64 0x6C14,rsp

	; DS,ES,FS,GS,TR
	vmw16 0xC06,ds
	vmw16 0xC00,es
	vmw16 0xC08,fs
	vmw16 0xC0A,gs
;	vmw16 0xC0C,tssd32_idx //*

	; GDTR, IDTR
	linear rdi,TempData,DMMI_DATA
	sgdt [rdi] ; 10 bytes : 2 limit and 8 item
	mov rax,[rdi + 2]
	mov rbx,0x6C0C
	vmwrite rbx,rax

	linear rdi,TempData,DMMI_DATA
	sidt [rdi] ; 10 bytes : 2 limit and 8 item
	mov rax,[rdi + 2]
	mov rbx,0x6C0E
	vmwrite rbx,rax

	; EFER
	mov ecx, 0c0000080h ; EFER MSR number. 
	rdmsr ; Read EFER.
	mov rbx,0x2C02
	vmwrite rbx,rax
RET


VMX_InitializeEPT:
	xor rdi,rdi
	linear rax,PhysicalEptOffset64,DMMI_DATA
	mov rdi,[rax]
 
	; Clear everything
	push rdi
	xor rax,rax
	mov ecx,8192
	rep stosq
	pop rdi
	; RSI to PDPT
	mov rsi,rdi
	add rsi,8*512

	; first pml4t entry
	xor rax,rax
	mov rax,rsi ; RAX now points to the RSI (First PDPT entry)
	shl rax,12 ; So we move it to bit 12
	shr rax,12 ; We remove the lower 4096 bits
	or rax,7 ; Add the RWE bits
	mov [rdi],rax ; Store the PML4T entry. We only need 1 entry

	
	; First PDPT entry (1st GB)
	xor rax,rax
	or rax,7 ; Add the RWE bits
	bts rax,7 ; Add the 7th "S" bit to tell the CPU that this doesn't refer to a PDT
	mov [rsi],rax ; Store the PMPT entry for 1st GB

	; Second PDPT entry (2nd GB)
	add rsi,8
	xor rax,rax
	mov rax,1024*1024*1024*1
	shr rax,12
	shl rax,12
	or rax,7 ; Add the RWE bits
	bts rax,7 ; Add the 7th "S" bit to tell the CPU that this doesn't refer to a PDT
	mov [rsi],rax ; Store the PMPT entry for 2nd GB

	; Third PDPT entry (3rd GB)
	add rsi,8
	xor rax,rax
	mov rax,1024*1024*1024*2
	shr rax,12
	shl rax,12
	or rax,7 ; Add the RWE bits
	bts rax,7 ; Add the 7th "S" bit to tell the CPU that this doesn't refer to a PDT
	mov [rsi],rax ; Store the PMPT entry for 3rd GB

	; Fourh PDPT entry (4th GB)
	add rsi,8
	xor rax,rax
	mov rax,1024*1024*1024*3
	shr rax,12
	shl rax,12
	or rax,7 ; Add the RWE bits
	bts rax,7 ; Add the 7th "S" bit to tell the CPU that this doesn't refer to a PDT
	mov [rsi],rax ; Store the PMPT entry for 4th GB


RET


; ---------------- Disable VMX ----------------
VMX_Disable:
	VMXOFF
	mov rax,cr4
	btc rax,13
	mov cr4,rax
RET


; ---------------- VMX Host Exit ----------------
VMX_VMExit:
	nop
	; Disable
	call VMX_Disable
RET



VMXInit:
	
	; Load the revision
	atlinear rbx,VMXRevision,DMMI_DATA

	; Initialize the region
	linear rdi,VMXStructureData2,DMMI_DATA
	mov rcx,[rdi];  Get address of data1
	mov rsi,rdi
	mov rdi,rcx
	mov [rdi],ebx ; // Put the revision
	VMCLEAR [rsi]
	mov [rdi],ebx ; // Put the revision
	VMPTRLD [rsi] 
	mov [rdi],ebx ; // Put the revision

RET


VMXInit2:

	; The EPT initialization for the guest
	linear rax,PhysicalEptOffset64,DMMI_DATA
	mov rax,[rax]
	or rax,0 ; Memory Type 0
	or rax,0x18 ; Page Walk Length 3
	mov rbx,0x201A ; EPTP
	vmwrite rbx,rax
 
	; The Link Pointer -1 initialization
	mov rax,0xFFFFFFFFFFFFFFFF
	mov rbx,0x2800 ; LP
	vmwrite rbx,rax
 
	; One more RSP initialization of the host
	xor rax,rax
	mov rbx,0x6c14 ; RSP
	mov rax,rsp
	add rax,8 ; because we are in a function call
	vmwrite rbx,rax

RET



L_Handler50_Yes10:
; BX = 0 , Existance test
cmp bx,0
jnz .nbx0
	MOV RAX,1
	CPUID
	XOR RAX,RAX
	BTC ECX,5
	JNC .f
	MOV RAX,1
	.f:
	iretq
.nbx0:



iretq
L_Handler50_No10:

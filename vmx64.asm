SEGMENT VMX16 
USE16



; VMX Entry for our Virtual Machine
; This is a Real Mode segment

; Note that since the memory is see through, BIOS and DOS interrupts work here!

StartVM:

; Remember we used a protected mode selector to get here?
; Jump to a real mode segment now so CS gets a proper value


nop
nop
vmcall ; Forces exit



SEGMENT VMX_DATA
ORG 0
; VMX DATA
PhysicalEptOffset64 dq 0

ALIGN 4096
VMXStructureData db 20000 dup (0)
ALIGN 4096
VMXStructureData1 dq 0 ; Used for VMXON
ALIGN 4096
VMXStructureData2 dq 0 ; First VMCS
VMXRevision dd 0 ; Save Revision here
VMXStructureSize dd 0 ; Save structure size here
TempData db 128 dup(0)
vmt1 db 0 ; existence
vmt2 db 0 ; protected mode guest
vmt3 db 0 ; unrestricted guest
vmm1 db "[VMX] ","$"
vmm2 db "[VMX Launch] ","$"
vmx_entry_point dq 0





SEGMENT VMXFUNCTIONS
ORG 0
USE64

; ---------------- Init the structures ----------------
VMX_Init_Structures:
	 ; Read MSR
	 xor eax,eax
	 mov ecx,0480h
	 rdmsr

	 linear ecx,VMXRevision,VMX_DATA
	 ; EAX holds the revision
	 ; EDX lower 13 bits hold the max size
	 mov [ecx],eax
	 and edx,8191
	 linear ecx,VMXStructureSize,VMX_DATA
	 mov [ecx],edx
	 ; Initialize 4096 structure datas for VMX
	 xor eax,eax
	 mov ax,VMX_DATA
	 shl eax,4 ; physical
	 Loop5X:
	 test eax,01fffh
	 jz Loop5End
	 inc eax
	 jmp Loop5X
	 Loop5End:
	 linear ecx,VMXStructureData1,VMX_DATA
	 mov dword [ecx],eax
	 add eax,4096
	 linear ecx,VMXStructureData2,VMX_DATA
	 mov dword [ecx],eax
RET

VMX_Enable:
	; cr4
	mov rax,cr4
	bts rax,13
	mov cr4,rax

    ; Load the revision
	linear rdi,VMXRevision,VMX_DATA
	mov ebx,[edi];
	
	; Initialize the VMXON region
	linear rdi,VMXStructureData1,VMX_DATA
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
	mov dx, cs
	and dx, 0xFFF8  ; Clear RPL and TI
	vmw16 0xC02, dx
	vmw64 0x6C16,rcx

	; SS:RSP
	mov dx, ss
	and dx, 0xFFF8
	vmw16 0xC04, dx ; SS
	vmw64 0x6C14,rsp

	; DS,ES,FS,GS,TR
	mov dx,ds
	and dx, 0xFFF8
	vmw16 0xC06,dx
	mov dx,es
	and dx, 0xFFF8
	vmw16 0xC00,dx
	mov dx,fs
	and dx, 0xFFF8
	vmw16 0xC08,dx
	mov dx,gs
	and dx, 0xFFF8
	vmw16 0xC0A,dx
	vmw16 0xC0C,tssd32_idx

	; GDTR, IDTR
	linear rdi,TempData,VMX_DATA
	sgdt [rdi] ; 10 bytes : 2 limit and 8 item
	mov rax,[rdi + 2]
	mov rbx,0x6C0C
	vmwrite rbx,rax

	mov ax, [rdi] ; Limit
	movzx rax, ax
	mov rbx,0x6C0A
	vmwrite rbx, rax ; GDTR limit

	linear rdi,TempData,VMX_DATA
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
	linear rax,PhysicalEptOffset64,VMX_DATA
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
	nop
	nop
	; Disable
	call VMX_Disable
RET



VMXInit:
	
	; Load the revision
	atlinear rbx,VMXRevision,VMX_DATA

	; Initialize the region
	linear rdi,VMXStructureData2,VMX_DATA
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
	linear rax,PhysicalEptOffset64,VMX_DATA
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








; A real mode guest
VMX_Initialize_UnrestrictedGuest:

	; cr0,cr3,cr4 real mode
	; cs ss:rip
	; flags

	xor rax,rax

	; CRx
	mov ebx,0x6800 ; CR0
	mov eax,0x60000030 ; And the NX bit must be set
	vmwrite rbx,rax
	mov ebx,0x6802 ; CR3
	mov eax,0
	vmwrite rbx,rax
	mov ebx,0x6804 ; CR4
	mov eax,0
	bts eax,13 ; the 13th bit of CR4 must be set in VMX mode
	vmwrite rbx,rax

	; Flags
	mov ebx,0x6820 ; RFLAGS
	mov rax,2
	vmwrite rbx,rax

	; Startup from VMX16 : StartVM


	; cs stuff
	xor rax,rax
	mov ax,code32_idx
	mov ebx,0x802 ; CS selector
	vmwrite rbx,rax

	xor rax,rax
	mov rax,0xffff
	mov ebx,0x4802 ; CS limit
	vmwrite rbx,rax

	mov rax,09fh
	mov ebx,0x4816 ; CS access
	vmwrite rbx,rax

	xor rax,rax
	mov rax,r9
	shl rax,4
	mov ebx,0x6808 ; CS base
	vmwrite rbx,rax


	mov ebx,0x681E ; IP
	xor rax,rax
	mov rax,r10
	vmwrite rbx,rax
	
	; MCS field "Activity State"
	mov rbx,0x4826
	mov rax,0
	vmwrite rbx,rax

	; RSP
	mov rax, 200; Or wherever the guest stack should begin
	mov rbx, 0x681C
	vmwrite rbx, rax


	; GDTR,IDTR
	mov ebx,0x6816 ; GDTR Base
	mov rax,0
	vmwrite rbx,rax
	mov ebx,0x4810 ; Limit
	mov rax,0xFFFF
	vmwrite rbx,rax
	mov ebx,0x6818 ; IDTR Base
	mov rax,0
	vmwrite rbx,rax
	mov ebx,0x4812 ; Limit
	mov rax,0xFFFF
	vmwrite rbx,rax

	; DR7
	mov ebx,0x681A ; DR7
	mov rax,0x400
	vmwrite rbx,rax

	; SEGMENT registers


	; es,ss,ds,fs,gs
	vmw16 0x800,flatdata32_idx
	vmw16 0x804,flatdata32_idx
	vmw16 0x806,flatdata32_idx
	vmw16 0x808,flatdata32_idx
	vmw16 0x80A,flatdata32_idx

	; Limits
	vmw32 0x4800,0xFFFF
	vmw32 0x4804,0xFFFF
	vmw32 0x4806,0xFFFF
	vmw32 0x4808,0xFFFF
	vmw32 0x480A,0xFFFF

	; Access
	vmw16 0x4814,0x93
	vmw16 0x4818,0x93
	vmw16 0x481A,0x93
	vmw16 0x481C,0x93
	vmw16 0x481E,0x93

	; base
	mov rax,r9
	shl rax,4
	vmw64 0x6806,rax
	vmw64 0x680A,rax
	vmw64 0x680C,rax
	vmw64 0x680E,rax
	vmw64 0x6810,rax


	; LDT (Dummy)
	xor rax,rax
	mov ax,ldt_idx
	mov ebx,0x80C ; LDT selector
	vmwrite rbx,rax
	mov rax,0xffffffff
	mov ebx,0x480C ; LDT limit
	vmwrite rbx,rax
	mov rax,0x10000
	mov ebx,0x4820 ; LDT access
	vmwrite rbx,rax
	mov rax,0
	mov ebx,0x6812 ; LDT base
	vmwrite rbx,rax

	; TR (Dummy)
	xor rax,rax
	mov ax,tssd32_idx
	mov ebx,0x80E ; TR selector
	vmwrite rbx,rax
	mov rax,0xff
	mov ebx,0x480E ; TR limit
	vmwrite rbx,rax
	mov rax,0x8b
	mov ebx,0x4822 ; TR access
	vmwrite rbx,rax
	mov rax,0
	mov ebx,0x6814 ; TR base
	vmwrite rbx,rax

RET


; ---------------- Host Start ----------------
VMX_Host:
	linear rbx,vmt1,VMX_DATA
	mov byte [rbx],0

	linear rbx,vmt1,VMX_DATA
	mov byte [rbx],1

	; Init structures
	call VMX_Init_Structures

	; Enable
	call VMX_Enable

    ; Real mode guest (unrestricted)
	call VMXInit  
	call VMX_InitializeEPT
	xor rdx,rdx
	bts rdx,1
	bts rdx,7
	call VMX_Initialize_VMX_Controls
	linear rcx,VMX_VMExit,VMXFUNCTIONS
	call VMX_Initialize_Host
	mov r9,VMX16
	mov r10,StartVM
	call VMX_Initialize_UnrestrictedGuest
	call VMXInit2

	; RDX load with the address
	linear rdx,vmx_entry_point,VMX_DATA
	mov rdx,[rdx]
	; Launch it!!
	VMLAUNCH

	; If we get here, VMLAUNCH failed
	; Disable
	call VMX_Disable

RET



; RDX linear to run
VMX_Run:
	call VMX_Host
RET
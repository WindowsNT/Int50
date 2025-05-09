FORMAT MZ
HEAP 0
include "macros.asm"
include "stack.asm"
include "dmmi_data.asm"
include "dmmi_code.asm"

SEGMENT MY_DATA
mymut_1 db 0xFF
msg_hello1 db "Hello",0xd,0xa,"$"
msg_hello2 db "Hello from thread",0xd,0xa,"$"
msg_hello3 db "Hello from thread 3",0xd,0xa,"$"
msg_hello4 db "Hello from VM",0xd,0xa,"$"

SEGMENT MY_CODE
USE16

a_virtual_64:
	nop
	nop
	nop
	CLI

	; Set interrupts
	mov ax,DMMI_DATA
	mov ds,ax
	xor eax,eax
	lidt fword [save_rm_idt]
	sti

	; Try int 21
	mov ax,MY_DATA
	mov ds,ax
	mov ax,0x0900
	mov dx, msg_hello4
	int 21h


	nop
	retf

USE64

a_proc_64v:
	nop
	nop
	mov eax,1
	int 50h

	; Is VMX supported?
	mov eax,10
	mov ebx, 0
	int 50h ; should return RAX = 1

	; Run VMX
	mov eax,10
	mov ebx, 1
	mov dx,a_virtual_64
	mov cx,MY_CODE
	int 50h 

	ret


a_proc_64:
	nop
	nop
	xor rax,rax

	; Init
	mov eax,1
	int 50h

	; Call real mode proc from pmode
	mov eax,7
	mov cx,MY_CODE
	mov dx,Func_Real
	int 50h

	ret

USE32
a_proc_32:
    nop
	nop

	; Start a thread from PM
	 mov eax,5
	 linear edx,Thread16_2,MY_CODE
	 mov ebx,1
	 int 50h

	; Call real mode proc from pmode
	mov eax,7
	mov cx,MY_CODE
	mov dx,Func_Real
	int 50h

	; Call a long proc from pmode
	mov eax,4
	xor ecx,ecx
	linear edx,a_proc_64,MY_CODE
	int 50h
	ret


USE16
Func_Real:
	nop
	nop
	push ds
	mov ax,MY_DATA
	mov ds,ax
	mov ax,0x0900
	mov dx, msg_hello3
	int 21h
	pop ds
	retf

Thread16_2:
	db 4096 dup (144) ; fill NOPs for alignment
	xchg bx,bx
	hlt
	hlt

Thread16_1:
	db 4096 dup (144) ; fill NOPs for alignment

	; Thread 1 Stack
	mov ax,STACK_SEGMENT
	mov ss,ax
	mov sp,stack_t2_end

	; Show message
	mov ax,MY_DATA
	mov ds,ax
	mov dx, msg_hello2
	mov ax,0x0900
	int 21h

	; Initialize Int 50
	mov eax,1
	int 0x50

	; Enter unreal, no ACPI init
	mov eax,2
	xor edx,edx
	int 50h

	; Call a 32-bit proc
	mov eax,3
	linear edx,a_proc_32,MY_CODE
	int 50h

	; Call a 64-bit proc
	mov eax,4
	xor ecx,ecx
	linear edx,a_proc_64,MY_CODE
	int 50h

	; Unlock mutex
	mov ax,MY_DATA
	mov es,ax
	mov di,mymut_1
	mov eax,6
	mov ebx,2
	int 0x50

	; Thread end
	hlt
	hlt

start16:
	CLI

	mov ax,STACK_SEGMENT
	mov sp,stack_end
	mov ss,ax

	call far CODE16:F_InstallVector50
	STI


; Initialize 
	mov eax,1
	int 50h

; Enter Unreal
	mov eax,2
	mov dx,1 ; and init acpi
	int 50h

; Call a 32-bit proc
	mov eax,3
	linear edx,a_proc_32,MY_CODE
	int 50h

; Call a 64-bit proc
	mov eax,4
	xor ecx,ecx
	linear edx,a_proc_64,MY_CODE
	int 50h


 ; A thread

	 ; Create the mutex
	 mov ax,MY_DATA
	 mov es,ax
	 mov di,mymut_1
	 mov eax,6
	 mov ebx,0
	 int 0x50

	 ; Lock it
	 mov eax,6
	 mov ebx,1
	 int 0x50

	 ; run it
	 mov eax,5
	 linear edx,Thread16_1,MY_CODE
	 mov ebx,1
	 int 50h

	 ; wait
	 mov ax,MY_DATA
	 mov es,ax
	 mov di,mymut_1
	 mov eax,6
	 mov ebx,3
	 int 0x50


; Call an 64-bit proc that starts a VM
	mov eax,4
	xor ecx,ecx
	linear edx,a_proc_64v,MY_CODE
	int 50h


; Message
	mov ax,MY_DATA
	mov ds,ax
	mov ax,0x0900
	mov dx, msg_hello1
	int 21h


; End
	mov ax,0x4c00
	int 21h

entry MY_CODE:start16

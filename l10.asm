USE64

; AX = 10, VMX operations

cmp ax,10
jnz L_Handler50_No10
jmp L_Handler50_Yes10





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

; BX = 1, Run VM
cmp bx,1
jnz .nbx1

linear rax,VMX_Run,VMXFUNCTIONS
call rax

.nbx1:
iretq
L_Handler50_No10:

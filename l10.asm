USE64

; AX = 10, VMX operations

cmp ax,10
jnz L_Handler50_No10


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

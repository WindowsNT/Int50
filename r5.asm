USE16

; AX = 5
; Start Thread
; EBX = CPU index
; EDX = linear address

cmp ax,5
jnz F_Handler50_No5


	mov eax,edx
	call far CODE16:SendSIPIf

iret
F_Handler50_No5:

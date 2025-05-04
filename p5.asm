USE32

; AX = 5
; Start Thread
; EBX = CPU index
; EDX = linear address

cmp ax,5
jnz P_Handler50_No5


	mov eax,edx
	call SendSIPIf32

iretd
P_Handler50_No5:

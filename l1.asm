USE64

; AX = 1 
; Test 0x50 vector installation
; Returns AX = 0x5050

cmp ax,1
jnz L_Handler50_No1

; Return
mov ax,0x5050
iretq

L_Handler50_No1:

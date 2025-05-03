USE16

; AX = 1 
; Test 0x50 vector installation
; Returns AX = 0x5050

cmp ax,1
jnz F_Handler50_No1

; Prepare GDT
call PrepareGDT16

; Prepare IDT
call PrepareIDTFor32
call PrepareIDTFor64

; Prepare Long
call PrepareLong

; Return
mov ax,0x5050
iret	

F_Handler50_No1:

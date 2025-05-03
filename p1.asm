USE32
; AX = 1 
; Test 0x50 vector installation
; Returns AX = 0x5050

cmp ax,1
jnz P_Handler50_No1

; Prepare Flat Paging for Long
call CreateFlatPagingForLong

; Return
mov ax,0x5050
iretd

P_Handler50_No1:

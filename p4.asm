USE32

; AX = 4
; Call 64-bit long mode function
; ECX:EDX = linear address of far function

cmp ax,4
jnz P_Handler50_No4

cli
mov ax,data32_idx
mov ds,ax
jmp code32_idx:start32_4



iretd
P_Handler50_No4:

USE32

; AX = 4
; Call 64-bit long mode function
; ECX:EDX = linear address of far function

cmp ax,4
jnz P_Handler50_No4

cli
mov ax,flatdata32_idx
mov ds,ax
linear eax,long_from_protected,DMMI_DATA
mov byte [ds:eax],1
jmp code32_idx:start32_4_from_pm_already



iretd
P_Handler50_No4:

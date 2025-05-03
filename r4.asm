USE16

; AX = 4
; Call 64-bit long mode function
; ECX:EDX = linear address of far function

cmp ax,4
jnz F_Handler50_No4

; Enter PM
cli
mov ax,DATA32
mov ds,ax
mov ax,DATA16
mov ds,ax
mov ebx,4
mov eax,cr0
or eax,1
mov cr0,eax
jmp code32_idx:start32_4



iret
F_Handler50_No4:

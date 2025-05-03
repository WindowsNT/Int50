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
mov dword [current_sp_32],0
mov ax,DATA16
mov ds,ax
mov [current_sp_16],sp
mov ebx,4
mov eax,cr0
or eax,1
mov cr0,eax
jmp code32_idx:start32_4



iret
F_Handler50_No4:

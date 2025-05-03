USE16

; AX = 2
; Enter Unreal Mode

cmp ax,2
jnz F_Handler50_No2

; Enable Unreal Mode
cli
mov eax,cr0
or eax,1
mov cr0,eax
mov eax,1
jmp $ + 2
mov ax,data32_idx
mov fs, ax
mov gs, ax
mov ds, ax
mov es, ax
mov eax,cr0
and eax,0FFFFFFFEh
mov cr0,eax
jmp far CODE16:F_Handler50_2_Return
F_Handler50_2_Return:
sti

; Prepare ACPI
cmp dx,1
jnz nopa
call PrepareACPI
nopa:

iret

F_Handler50_No2:

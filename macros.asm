macro linear reg,trg,seg
	{
;	xor reg,reg
	mov reg,seg
	shl reg,4
	add reg,trg
	}
    
struc GDT_STR s0_15,b0_15,b16_23,flags,access,b24_31
        {
		.s0_15   dw s0_15
		.b0_15   dw b0_15
		.b16_23  db b16_23
		.flags   db flags
		.access  db access
		.b24_31  db b24_31
        }

struc IDT_STR o0_15,se0_15,zb,flags,o16_31
        {
		.o0_15   dw o0_15
		.se0_15  dw se0_15
		.zb      db zb
		.flags   db flags
		.o16_31  dw o16_31
        }
struc IDT_STR64 o0_15,se0_15,zb,flags,o16_31,o32_63,zr
        {
		.o0_15   dw o0_15
		.se0_15  dw se0_15
		.zb      db zb
		.flags   db flags
		.o16_31  dw o16_31
		.o32_63  dd o32_63
		.zr      dd zr
        }

macro gdt_initialize32 a_seg,a_desc
{
    xor eax, eax
    mov ax, a_seg
    shl eax, 4

    ; Base 0–15
    mov word [a_desc + 2], ax

    ; Base 16–23
    shr eax, 16
    mov byte [a_desc + 4], al

    ; Base 24–31
    shr eax, 8
    mov byte [a_desc + 7], al
}



USE32

CreateFlatPagingForLong: 

	; We will use MB MB_PAGE_UPPER to place the paging table
    pushad
	push ds
	push es
	mov ax,flatdata32_idx
	mov ds,ax
	mov es,ax
	mov esi,MB_PAGE_UPPER*1024*1024

    ; clear
    mov     edi,esi
	xor eax,eax
    mov     ecx,0x3000 / 4
    rep     stosd

	; Put the PML4T to 0x0000, these are 512 entries, so it takes 0x1000 bytes
	; We only want the first PML4T 
	mov eax,esi
	add eax,0x1000 ; point it to the first PDPT
	or eax,3 ; Present, Readable/Writable
	mov [es:esi + 0x0000],eax
			
	mov ecx,4 ; Map 4GB (512*1GB).  
	mov eax,0x83 ; Also bit 7
	mov edi,esi
	add edi,0x1000
	.lxf1:
	mov     [es:edi],eax
	add     eax,1024*1024*1024
	add edi,8
	loop .lxf1

	pop es
	pop ds
	popad
	ret






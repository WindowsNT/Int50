USE32
SEGMENT CODE32 USE32
ORG 0

include "p0.asm"

P_Handler50:
include "p1.asm"
include "p4.asm"
iretd


; Function 4: Execute 64-bit linear proc
start32_4: ; 
cli
mov ax,data32_idx
mov ds,ax
mov ax,stack32_idx
mov sp,stack32_end
mov ss,ax

; Disable paging, assuming that we are in a see-through.
push ecx
push edx
mov eax, cr0 ; Read CR0.
and eax,7FFFFFFFh; Set PE=0
mov cr0, eax ; Write CR0.
mov eax, cr4
bts eax, 5
mov cr4, eax ; Set PAE
mov ecx, 0c0000080h ; EFER MSR number. 
rdmsr ; Read EFER.
bts eax, 8 ; Set LME=1.
wrmsr ; Write EFER.
mov eax,MB_PAGE_UPPER*1024*1024 ; upper MB_PAGE_UPPER
mov cr3,eax
; Enable Paging to activate Long Mode. Assuming that CR3 is loaded with the physical address of the page table.
mov eax, cr0 ; Read CR0.
or eax,80000000h ; Set PE=1 
pop edx
pop ecx
mov cr0, eax ; Write CR0.
; We are in compatibility mode
db 0eah
LinearAddressOfStart64:
dd 0
dw code64_idx

Back32From64:

; Disable Paging to get out of Long Mode
mov eax, cr0 ; Read CR0.
and eax,7fffffffh ; Set PE=0.
mov cr0, eax ; Write CR0.

; Deactivate Long Mode
mov ecx, 0c0000080h ; EFER MSR number. 
rdmsr ; Read EFER.
btc eax, 8 ; Set LME=0.
wrmsr ; Write EFER.

; If we have saved ESP, we go back to 32-bit PM
; else rM
mov ax,data32_idx
mov ds,ax
cmp dword [current_sp_32],0
jz mustreal

; must return to pmode
mov ax,stack32_idx
mov ss,ax
mov ax,data32_idx
mov ds,ax
mov esp,[current_sp_32]
iretd

mustreal:
JMP code16_idx:F_GoingBackFrom3


; Function 3 : Execute 32-bit linear proc
start32_3a: ; linear 
	mov eax,1
	int 0x50
	call edx	
	; jump first to the 16-bit code segment to clear the CS from 32-bit
	JMP code16_idx:F_GoingBackFrom3

start32_3:
	cli
	mov ax,data32_idx
	mov ds,ax
	mov ax,stack32_idx
	mov sp,stack32_end
	mov ss,ax
	sti

	; EDX = linear address of far function
	linear eax,start32_3a,CODE32
	push word flatcode32_idx
	push eax
	retf



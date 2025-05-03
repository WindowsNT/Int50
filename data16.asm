SEGMENT DATA16 USE16

; --------------------------------------- GDT ---------------------------------------
gdt_start dw gdt_size
gdt_ptr dd 0
dummy_descriptor   GDT_STR 0,0,0,0,0,0
code32_descriptor  GDT_STR 0ffffh,0,0,9ah,0cfh,0 ; 4GB 32-bit code , 9ah = 10011010b = Present, DPL 00,No System, Code Exec/Read. 0cfh access = 11001111b = Big,32bit,<resvd 0>,1111 more size
data32_descriptor  GDT_STR 0ffffh,0,0,92h,0cfh,0 ; 4GB 32-bit data,   92h = 10010010b = Presetn , DPL 00, No System, Data Read/Write
stack32_descriptor GDT_STR 0ffffh,0,0,92h,0cfh,0 ; 4GB 32-bit stack
code16_descriptor  GDT_STR 0ffffh,0,0,9ah,0,0    ; 64k 16-bit code
data16_descriptor  GDT_STR 0ffffh,0,0,92h,0,0    ; 64k 16-bit data
stack16_descriptor GDT_STR 0ffffh,0,0,92h,0,0    ; 64k 16-bit data
flatcode32_descriptor GDT_STR 0ffffh,0,0,9ah,0cfh,0 ; 4GB 32-bit code , 9ah = 10011010b = Present, DPL 00,No System, Code Exec/Read. 0cfh access = 11001111b = Big,32bit,<resvd 0>,1111 more size
flatdata32_descriptor  GDT_STR 0ffffh,0,0,92h,0cfh,0 ; 4GB 32-bit data,   92h = 10010010b = Presetn , DPL 00, No System, Data Read/Write
code64_descriptor  GDT_STR 0ffffh,0,0,9ah,0afh,0 ; 16TB 64-bit code, 08cfh access = 01001111b = Big,64bit (0), 1111 more size
data64_descriptor  GDT_STR 0ffffh,0,0,92h,0afh,0 ; 16TB 64-bit data, 08cfh access = 10001111b = Big,64bit (0), 1111 more size
gdt_size = $-(dummy_descriptor)

dummy_idx       = 0h    ; dummy selector
code32_idx      =       08h             ; offset of 32-bit code  segment in GDT
data32_idx      =       10h             ; offset of 32-bit data  segment in GDT
stack32_idx     =       18h             ; offset of 32-bit stack segment in GDT
code16_idx      =       20h             ; offset of 16-bit code segment in GDT
data16_idx      =       28h             ; offset of 16-bit data segment in GDT
stack16_idx     =       30h             ; offset of 16-bit stack segment in GDT
flatcode32_idx  =       38h             ; offset of 32-bit code  segment in GDT
flatdata32_idx  =       40h             ; offset of 32-bit data segment in GDT
code64_idx      =       48h             ; offset of 64-bit code segment in GDT
data64_idx      =       50h             ; offset of 64-bit data segment in GDT


; --------------------------------------- RM IDT ---------------------------------------
save_rm_idt      dw 0
dd 0



; --------------------------------------- IDT32 ---------------------------------------
idt_PM_start      dw             idt_size32
idt_PM_ptr dd 0
interruptsall:
	times 256*8 db 0 
idt_size32=$-(interruptsall)

; --------------------------------------- IDT64 ---------------------------------------
idt_LM_start      dw             idt_size64
idt_LM_ptr dd 0
dd 0
interruptsall64:
	times 256*16 db 0 
idt_size64=$-(interruptsall64)


current_sp_16 dw 0	

; -- Paging

PhysicalPagingOffset64 dd 0

; -- APIC -- 
struc A_CPU a,b,c,d
        {
        .acpi   dd a
        .apic   dd b
        .flags  dd c
		.handle dd d
        }


numcpus db 0
somecpu A_CPU 0,0,0,0
cpusstructize = $-(somecpu)
CpusOfs:
cpus db cpusstructize*64 dup(0)
MainCPUAPIC db 0 
LocalApic dd 0xFEE00000
RsdtAddress dd 0
XsdtAddress dq 0
mut_ipi db 0xFF
mut_1 db 0xFF

msg_hello db "Hello",0xd,0xa,"$"
msg_hello2 db "Hello from thread",0xd,0xa,"$"


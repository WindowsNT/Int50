# Int50 simplified DMMI interface

Int 0x50 interfaces for your DOS apps. See all.asm:

```asm
FORMAT MZ
HEAP 0
include "macros.asm"
include "stack.asm"
include "dmmi_data.asm"
include "dmmi_code.asm"
```

* Install interrupt

Modes: Real

```asm
call far CODE16:F_InstallVector50
```


* Initialize Int 0x50. This must be called from all entry points (start, thread, protected mode, long mode functions)

Modes: Real, Protected, Long

```asm
mov eax,1
int 50h
```


* Enable Unreal mode. This also initializes ACPI structures.

Modes: Real

```asm
mov eax,2
int 50h
```

* Call 32-bit protected mode function

Modes: Real

EDX = linear address of your proc

```asm
mov eax,3
linear edx,a_proc_32,MY_CODE
int 50h
```

* Call 64-bit long mode function

Modes: Real, Protected

ECX:EDX = linear address of your proc

```asm
mov eax,4
xor ecx,ecx
linear edx,a_proc_64,MY_CODE
int 50h
```

* Call 16-bit real mode function

Modes: Protected, Long

CD:DX = seg:ofs of real mode proc

```asm
mov eax,7
mov cx,MY_CODE
mov dx,Func_Real
int 50h
```

* Start 16-bit thread. This thread can call Int 50x functions to switch to protected or long mode.
 
Modes: Real. 

EBX = cpu index
EDX = linear address of the thread proc

```asm
mov eax,5
linear edx,Thread16_1,MY_CODE
mov ebx,1
int 50h
```

A thread must begin with 4096 NOPs for call alignment

```asm
db 4096 dup (144) ; fill NOPs for alignment
```

* Mutex functions

Modes: Real, Protected, Long
 
AX = 6
BX operation 0 create 1 lock 2 unlock 3 wait 4 wait and lock
ES:DI = mutex address (byte)

```asm
; Create the mutex
mov ax,MY_DATA
mov es,ax
mov di,mymut_1
mov eax,6
mov ebx,0
int 0x50

; Lock it
mov eax,6
mov ebx,1
int 0x50

; wait
mov ax,MY_DATA
mov es,ax
mov di,mymut_1
mov eax,6
mov ebx,3
int 0x50

; Another thread
; Unlock mutex and end
mov ax,MY_DATA
mov es,ax
mov di,mymut_1
mov eax,6
mov ebx,2
int 0x50
hlt 
hlt

```

* Start 16-bit virtualized function (Available from long mode). To call this function, first call a long mode function.

CD:DX = linear address of the real mode proc.
```asm
; Is VMX supported?
mov eax,10
mov ebx, 0
int 50h; should return RAX = 1

; Run VMX
mov eax,10
mov ebx, 1
mov dx,a_virtual_64
mov cx,MY_CODE
int 50h;

;
```


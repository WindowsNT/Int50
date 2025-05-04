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
```asm
call far CODE16:F_InstallVector50
```


* Initialize Int 0x50 (Available from real, protected, long mode)
```asm
mov eax,1
int 50h
```

This must be called from all entry points (start, thread, protected mode, long mode functions )

* Enable Unreal mode (Available from Real mode)
```asm
mov eax,2
int 50h
```

* Call 32-bit protected mode function (Available from real mode)
EDX = linear address of your proc

```asm
mov eax,3
linear edx,a_proc_32,MY_CODE
int 50h
```

* Call 64-bit long mode function (Available from real and protected mode)
ECX:EDX = linear address of your proc
```asm
mov eax,4
xor ecx,ecx
linear edx,a_proc_64,MY_CODE
int 50h
```

* Call 16-bit real mode function (Available from protected and long mode)
CD:DX = seg:ofs of real mode proc
```asm
mov eax,7
mov cx,MY_CODE
mov dx,Func_Real
int 50h
```
R

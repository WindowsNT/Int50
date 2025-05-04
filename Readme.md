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


* Initialize Int 0x50
```asm
	mov eax,1
	int 50h
```

This must be called from all entry points (start, thread, protected mode, long mode functions )




USE16

; AX = 6
; Mutex functions
; BX operation 0 create 1 lock 2 unlock 3 wait 4 wait and lock
; ES:DI = mutex address (byte)

cmp ax,6
jnz .F_Handler50_No6

; Create mutex
cmp bx,0
jnz .nobx0
mov byte [es:di],0xFF
iret
.nobx0:

; Lock mutex
cmp bx,1
jnz .nobx1
dec byte [es:di]
iret
.nobx1:

; Unlock mutex
cmp bx,2
jnz .nobx2
cmp byte [es:di],0xFF
jz .nolock2
inc byte [es:di]
.nolock2:
iret
.nobx2:

; Wait mutex
cmp bx,3
jnz .nobx3
.Loop1X:		
CMP byte [es:di],0xff
JZ .OutLoop1
pause 
JMP .Loop1X
.OutLoop1:
iret
.nobx3:

; Wait and lock mutex
cmp bx,4
jnz .nobx4

.LoopA:		
CMP byte [es:di],0xff
JZ .OutLoop1F
pause 
JMP .LoopA
.OutLoop1F:
; Lock is free, can we grab it?
mov bl,0xfe
MOV AL,0xFF
LOCK CMPXCHG [ES:DI],bl
JNZ .LoopA ; Write failed
.OutLoop2F: ; Lock Acquired

iret
.nobx4:
iret
.F_Handler50_No6:

@echo off
del all.exe
g:\progs\fasm\fasm all.asm all.exe

del d.iso
mkdir CD
copy /y all.exe  .\CD\
copy /y runx.bat .\CD\
powershell -ExecutionPolicy RemoteSigned -File "iso.ps1"

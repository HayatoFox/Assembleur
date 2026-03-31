@echo off
c:\masm32\bin\ml /c /Zd /coff C_c.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE C_c.obj
pause
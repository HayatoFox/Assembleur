@echo off
c:\masm32\bin\ml /c /Zd /coff C_a_b.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE C_a_b.obj
pause
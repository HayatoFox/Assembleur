@echo off
c:\masm32\bin\ml /c /Zd /coff B_b.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE B_b.obj
pause
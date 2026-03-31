@echo off
c:\masm32\bin\ml /c /Zd /coff D_b.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE D_b.obj
pause
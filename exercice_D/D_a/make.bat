@echo off
c:\masm32\bin\ml /c /Zd /coff D_a.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE D_a.obj
pause
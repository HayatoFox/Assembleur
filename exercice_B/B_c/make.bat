@echo off
c:\masm32\bin\ml /c /Zd /coff B_c.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE B_c.obj
pause
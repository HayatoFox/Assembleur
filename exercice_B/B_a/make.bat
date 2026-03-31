@echo off
c:\masm32\bin\ml /c /Zd /coff B_a.asm
c:\masm32\bin\Link /SUBSYSTEM:CONSOLE B_a.obj
pause
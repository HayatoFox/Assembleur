.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc

includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\kernel32.lib

.DATA
messageText db "Bonjour depuis l'assembleur", 0
messageTitle db "Exercice A - question d", 0

.CODE
start:
        push 0
        push offset messageTitle
        push offset messageText
        push 0
        call MessageBoxA

        push 0
        call ExitProcess

end start
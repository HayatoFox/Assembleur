.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\msvcrt.lib

.DATA
promptN  db "Entrer n pour n!: ", 0
fmtIn    db "%u", 0
fmtOut   db "%u! = %u", 10, 0
nValue   dd 0
strPause db "pause", 0

.CODE
fact:
        push ebp
        mov ebp, esp

        mov eax, [ebp+8]
        cmp eax, 1
        jbe fact_base

        dec eax
        push eax
        call fact

        mov edx, [ebp+8]
        imul eax, edx
        jmp fact_end

fact_base:
        mov eax, 1

fact_end:
        pop ebp
        ret 4

start:
        push offset promptN
        call crt_printf
        add esp, 4

        push offset nValue
        push offset fmtIn
        call crt_scanf
        add esp, 8

        push dword ptr [nValue]
        call fact

        push eax
        push dword ptr [nValue]
        push offset fmtOut
        call crt_printf
        add esp, 12

        push offset strPause
        call crt_system
        add esp, 4

        push 0
        call ExitProcess

end start
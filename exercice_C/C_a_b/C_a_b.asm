.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\msvcrt.lib

.DATA
promptN  db "Entrer n (>=1): ", 0
fmtIn    db "%d", 0
fmtOut   db "myst(%d) = %d", 10, 0
msgFib   db "Cette fonction calcule le n-ieme terme de Fibonacci (F1=1, F2=1).", 10, 0
nValue   dd 0
strPause db "pause", 0

.CODE
myst:
        push ebp
        mov ebp, esp
        sub esp, 12

        mov dword ptr [ebp-4], 1
        mov dword ptr [ebp-8], 1

        mov ecx, 3
        mov edx, [ebp+8]

loop_test:
        cmp ecx, edx
        jg loop_end

        mov eax, [ebp-4]
        add eax, [ebp-8]
        mov [ebp-12], eax

        mov eax, [ebp-8]
        mov [ebp-4], eax

        mov eax, [ebp-12]
        mov [ebp-8], eax

        inc ecx
        jmp loop_test

loop_end:
        mov eax, [ebp-8]
        mov esp, ebp
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

        mov eax, [nValue]
        cmp eax, 1
        jge n_ok
        mov dword ptr [nValue], 1

n_ok:
        push dword ptr [nValue]
        call myst

        push eax
        push dword ptr [nValue]
        push offset fmtOut
        call crt_printf
        add esp, 12

        push offset msgFib
        call crt_printf
        add esp, 4

        push offset strPause
        call crt_system
        add esp, 4

        push 0
        call ExitProcess

end start
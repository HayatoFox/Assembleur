.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\msvcrt.lib

.DATA
wordStr   db "abacabbccaa", 0
fmtOut    db "mot=%s | a=%d b=%d c=%d", 10, 0
resA      dd 0
resB      dd 0
resC      dd 0
strPause  db "pause", 0

.CODE
CountABC:
        push ebp
        mov ebp, esp
        sub esp, 12

        mov dword ptr [ebp-4], 0
        mov dword ptr [ebp-8], 0
        mov dword ptr [ebp-12], 0

        mov esi, [ebp+8]

abc_loop:
        mov al, [esi]
        cmp al, 0
        je abc_done

        cmp al, 'a'
        jne test_b
        inc dword ptr [ebp-4]
        jmp abc_next

test_b:
        cmp al, 'b'
        jne test_c
        inc dword ptr [ebp-8]
        jmp abc_next

test_c:
        cmp al, 'c'
        jne abc_next
        inc dword ptr [ebp-12]

abc_next:
        inc esi
        jmp abc_loop

abc_done:
        mov eax, [ebp-4]
        mov ebx, [ebp-8]
        mov ecx, [ebp-12]
        mov esp, ebp
        pop ebp
        ret 4

start:
        push offset wordStr
        call CountABC

        mov [resA], eax
        mov [resB], ebx
        mov [resC], ecx

        push dword ptr [resC]
        push dword ptr [resB]
        push dword ptr [resA]
        push offset wordStr
        push offset fmtOut
        call crt_printf
        add esp, 20

        push offset strPause
        call crt_system
        add esp, 4

        push 0
        call ExitProcess

end start
.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\msvcrt.lib

.DATA
sample   db "assembleur", 0
msgLen   db "Longueur de '%s' = %d", 10, 0
strPause db "pause", 0

.CODE
CountChars:
        push ebp
        mov ebp, esp
        mov esi, [ebp+8]
        xor eax, eax

len_loop:
        cmp byte ptr [esi], 0
        je len_done
        inc eax
        inc esi
        jmp len_loop

len_done:
        pop ebp
        ret 4

start:
        push offset sample
        call CountChars

        push eax
        push offset sample
        push offset msgLen
        call crt_printf
        add esp, 12

        push offset strPause
        call crt_system
        add esp, 4

        push 0
        call ExitProcess

end start
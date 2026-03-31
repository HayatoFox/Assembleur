.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\msvcrt.lib

.DATA
msgBefore db "Avant : %s", 10, 0
msgAfter  db "Apres : %s", 10, 0
sample    db "Assembleur Ensibs 2026", 0
strPause  db "pause", 0

.CODE
start:
        push offset sample
        push offset msgBefore
        call crt_printf
        add esp, 8

        mov esi, offset sample

upper_loop:
        mov al, [esi]
        cmp al, 0
        je upper_done
        cmp al, 'a'
        jl upper_next
        cmp al, 'z'
        jg upper_next
        sub al, 32
        mov [esi], al

upper_next:
        inc esi
        jmp upper_loop

upper_done:
        push offset sample
        push offset msgAfter
        call crt_printf
        add esp, 8

        push offset strPause
        call crt_system
        add esp, 4

        push 0
        call ExitProcess

end start
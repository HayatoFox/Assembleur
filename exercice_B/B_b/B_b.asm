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
sample    db "Bonjour a tous", 0
strPause  db "pause", 0

.CODE
ToUpperStack:
        push ebp
        mov ebp, esp
        mov esi, [ebp+8]

sub_loop:
        mov al, [esi]
        cmp al, 0
        je sub_done
        cmp al, 'a'
        jl sub_next
        cmp al, 'z'
        jg sub_next
        sub al, 32
        mov [esi], al

sub_next:
        inc esi
        jmp sub_loop

sub_done:
        pop ebp
        ret 4

start:
        push offset sample
        push offset msgBefore
        call crt_printf
        add esp, 8

        push offset sample
        call ToUpperStack

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
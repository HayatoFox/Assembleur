.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
include c:\masm32\include\msvcrt.inc

includelib c:\masm32\lib\kernel32.lib
includelib c:\masm32\lib\msvcrt.lib

.DATA
promptN  db "Entrer un entier positif: ", 0
fmtIn    db "%u", 0
fmtDiv   db "%u ", 0
fmtHead  db "Diviseurs: ", 0
fmtNl    db 10, 0
fmtErr   db "Valeur invalide (<=0).", 10, 0
nValue   dd 0
strPause db "pause", 0

.CODE
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

        push offset fmtErr
        call crt_printf
        add esp, 4

        push offset strPause
        call crt_system
        add esp, 4

        push 0
        call ExitProcess

n_ok:
        push offset fmtHead
        call crt_printf
        add esp, 4

        mov ebx, 1

div_loop:
        cmp ebx, [nValue]
        jg done

        mov eax, [nValue]
        xor edx, edx
        div ebx
        cmp edx, 0
        jne next_div

        push ebx
        push offset fmtDiv
        call crt_printf
        add esp, 8

next_div:
        inc ebx
        jmp div_loop

done:
        push offset strPause
        call crt_system
        add esp, 4

        push offset fmtNl
        call crt_printf
        add esp, 4

        push 0
        call ExitProcess

end start
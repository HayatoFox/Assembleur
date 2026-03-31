; ============================================================================
; DIR /S Clone - Version Ligne de Commande
; Assembleur x86 (MASM) pour Windows
;
; Listage récursif des fichiers à partir d'un répertoire donné par l'utilisateur
; Equivalent de la commande Windows DIR /S
;
; Version sans pseudo-instructions MASM dans le segment .code
; (pas de INVOKE, PROC avec params/LOCAL, .IF, .WHILE, .FOR)
;
; Assemblage:  ml /c /coff dir_recursive_cli.asm
; Liaison:     link /SUBSYSTEM:CONSOLE dir_recursive_cli.obj kernel32.lib user32.lib
; ============================================================================

.386
.model flat, stdcall
option casemap:none

; ============================================================================
; Inclusions des fonctions Windows API
; ============================================================================

; --- Constantes ---
STD_INPUT_HANDLE        equ -10
STD_OUTPUT_HANDLE       equ -11
MAX_PATH                equ 260
INVALID_HANDLE_VALUE    equ -1

FILE_ATTRIBUTE_DIRECTORY equ 10h
FILE_ATTRIBUTE_HIDDEN    equ 02h
FILE_ATTRIBUTE_SYSTEM    equ 04h

; --- Structure WIN32_FIND_DATA (taille 318 octets pour ANSI) ---
WIN32_FIND_DATA STRUCT
    dwFileAttributes    DWORD ?
    ftCreationTime      DWORD 2 dup(?)      ; FILETIME = 2 DWORDs
    ftLastAccessTime    DWORD 2 dup(?)
    ftLastWriteTime     DWORD 2 dup(?)
    nFileSizeHigh       DWORD ?
    nFileSizeLow        DWORD ?
    dwReserved0         DWORD ?
    dwReserved1         DWORD ?
    cFileName           BYTE MAX_PATH dup(?)
    cAlternateFileName  BYTE 14 dup(?)
WIN32_FIND_DATA ENDS

; --- Structure SYSTEMTIME ---
SYSTEMTIME STRUCT
    wYear           WORD ?
    wMonth          WORD ?
    wDayOfWeek      WORD ?
    wDay            WORD ?
    wHour           WORD ?
    wMinute         WORD ?
    wSecond         WORD ?
    wMilliseconds   WORD ?
SYSTEMTIME ENDS

; --- Prototypes des fonctions API Windows ---
ExitProcess             PROTO :DWORD
GetStdHandle            PROTO :DWORD
WriteConsoleA           PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ReadConsoleA            PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
FindFirstFileA          PROTO :DWORD, :DWORD
FindNextFileA           PROTO :DWORD, :DWORD
FindClose               PROTO :DWORD
GetLastError            PROTO
SetConsoleOutputCP      PROTO :DWORD
FileTimeToSystemTime    PROTO :DWORD, :DWORD
lstrlenA                PROTO :DWORD
lstrcpyA                PROTO :DWORD, :DWORD
lstrcatA                PROTO :DWORD, :DWORD
wsprintfA               PROTO C :DWORD, :DWORD, :VARARG

; ============================================================================
; Segment de données
; ============================================================================
.data

    ; Messages affichés à l'utilisateur
    msgBanner       BYTE 13, 10
                    BYTE "  ======================================", 13, 10
                    BYTE "  =   DIR /S - Listage Recursif ASM   =", 13, 10
                    BYTE "  ======================================", 13, 10, 13, 10, 0

    msgPrompt       BYTE "  Entrez le repertoire de depart: ", 0
    msgScanning     BYTE 13, 10, "  Analyse en cours...", 13, 10, 13, 10, 0
    msgDirHeader    BYTE 13, 10, " Repertoire de : ", 0
    msgNewLine      BYTE 13, 10, 0
    msgSeparator    BYTE " -----------------------------------------"
                    BYTE "---------------------------------------", 13, 10, 0
    msgFileCount    BYTE 13, 10, " ==========================================", 13, 10
                    BYTE "  Total: %d fichier(s), %d repertoire(s)", 13, 10
                    BYTE " ==========================================", 13, 10, 0
    msgError        BYTE 13, 10, "  ERREUR: Repertoire introuvable ou inaccessible.", 13, 10, 0
    msgDirTag       BYTE "  <REP>     ", 0
    msgFileFormat   BYTE "  %12lu  ", 0

    ; Format de date/heure
    msgDateFmt      BYTE "%02d/%02d/%04d  %02d:%02d  ", 0
    msgPause        BYTE 13, 10, "  Appuyez sur Entree pour quitter...", 13, 10, 0

    ; Masque de recherche
    szWildcard      BYTE "\\*", 0
    szBackslash     BYTE "\\", 0
    szDot           BYTE ".", 0
    szDotDot        BYTE "..", 0

    ; Compteurs globaux
    dwFileCount     DWORD 0
    dwDirCount      DWORD 0

    ; Handles console
    hStdOut         DWORD ?
    hStdIn          DWORD ?

; ============================================================================
; Segment de données non initialisées
; ============================================================================
.data?

    inputBuffer     BYTE 512 dup(?)
    pathBuffer      BYTE 2048 dup(?)
    searchPath      BYTE 2048 dup(?)
    printBuffer     BYTE 1024 dup(?)
    dateBuf         BYTE 128 dup(?)
    dwBytesWritten  DWORD ?
    dwBytesRead     DWORD ?
    findData        WIN32_FIND_DATA <>
    sysTime         SYSTEMTIME <>

; ============================================================================
; Segment de code
; ============================================================================
.code

; ----------------------------------------------------------------------------
; PrintStr - Affiche une chaîne terminée par 0 sur la console
; Entrée : ESI = pointeur vers la chaîne
; ----------------------------------------------------------------------------
PrintStr:
    push ebp
    mov ebp, esp
    push eax
    push ecx
    push edx

    ; Calculer la longueur de la chaîne
    ; lstrlenA(esi) - stdcall, 1 param
    push esi
    call lstrlenA
    mov ecx, eax

    ; Écrire sur la console
    ; WriteConsoleA(hStdOut, esi, ecx, ADDR dwBytesWritten, 0) - stdcall, 5 params
    push 0
    push OFFSET dwBytesWritten
    push ecx
    push esi
    push hStdOut
    call WriteConsoleA

    pop edx
    pop ecx
    pop eax
    mov esp, ebp
    pop ebp
    ret

; ----------------------------------------------------------------------------
; TrimCRLF - Supprime les CR/LF en fin de chaîne
; Entrée : EDI = pointeur vers la chaîne
; ----------------------------------------------------------------------------
TrimCRLF:
    push ebp
    mov ebp, esp
    push eax
    push ecx

    ; lstrlenA(edi) - stdcall, 1 param
    push edi
    call lstrlenA
    test eax, eax
    jz _TrimDone

    lea ecx, [edi + eax - 1]
_TrimLoop:
    cmp ecx, edi
    jb _TrimDone
    mov al, [ecx]
    cmp al, 13          ; CR
    je _TrimChar
    cmp al, 10          ; LF
    je _TrimChar
    cmp al, 32          ; espace
    je _TrimChar
    jmp _TrimDone
_TrimChar:
    mov BYTE PTR [ecx], 0
    dec ecx
    jmp _TrimLoop
_TrimDone:
    pop ecx
    pop eax
    mov esp, ebp
    pop ebp
    ret

; ----------------------------------------------------------------------------
; FormatFileTime - Formate un FILETIME en chaîne date/heure lisible
; Entrée : ESI = pointeur vers FILETIME
;          EDI = pointeur vers buffer de sortie
; ----------------------------------------------------------------------------
FormatFileTime:
    push ebp
    mov ebp, esp
    pushad

    ; Convertir FILETIME en SYSTEMTIME
    ; FileTimeToSystemTime(esi, ADDR sysTime) - stdcall, 2 params
    push OFFSET sysTime
    push esi
    call FileTimeToSystemTime

    ; Formater la date
    movzx eax, sysTime.wDay
    movzx ebx, sysTime.wMonth
    movzx ecx, sysTime.wYear
    movzx edx, sysTime.wHour
    movzx esi, sysTime.wMinute

    ; wsprintfA(edi, ADDR msgDateFmt, eax, ebx, ecx, edx, esi) - cdecl, 7 args
    push esi              ; wMinute
    push edx              ; wHour
    push ecx              ; wYear
    push ebx              ; wMonth
    push eax              ; wDay
    push OFFSET msgDateFmt
    push edi              ; buffer de sortie
    call wsprintfA
    add esp, 28           ; cdecl: caller cleans 7 * 4 = 28 bytes

    popad
    mov esp, ebp
    pop ebp
    ret

; ----------------------------------------------------------------------------
; ListDirectory - Procédure récursive de listage de répertoire
; Entrée : EBX = pointeur vers le chemin du répertoire à lister
;
; Stack frame layout (manual):
;   [ebp-4]    = hFind (DWORD)
;   [ebp-2052] = localPath (2048 bytes) : ebp-4-2048
;   [ebp-4100] = subDir (2048 bytes)    : ebp-2052-2048
;   Total locals = 4100 bytes
; ----------------------------------------------------------------------------
ListDirectory:
    push ebp
    mov ebp, esp
    sub esp, 4100         ; allocate space for locals

    pushad

    ; --- Afficher l'en-tête du répertoire ---
    lea esi, msgDirHeader
    call PrintStr
    mov esi, ebx
    call PrintStr
    lea esi, msgNewLine
    call PrintStr
    lea esi, msgSeparator
    call PrintStr

    ; --- Construire le chemin de recherche: répertoire\* ---
    lea edi, searchPath

    ; lstrcpyA(edi, ebx) - stdcall, 2 params
    push ebx
    push edi
    call lstrcpyA

    ; lstrcatA(edi, ADDR szWildcard) - stdcall, 2 params
    push OFFSET szWildcard
    lea edi, searchPath
    push edi
    call lstrcatA

    ; --- Trouver le premier fichier ---
    ; FindFirstFileA(ADDR searchPath, ADDR findData) - stdcall, 2 params
    push OFFSET findData
    push OFFSET searchPath
    call FindFirstFileA
    cmp eax, INVALID_HANDLE_VALUE
    je _LD_exit
    mov [ebp-4], eax      ; hFind = eax

_LD_findLoop:
    ; --- Ignorer "." et ".." ---
    lea esi, findData.cFileName

    ; lstrcpyA(ADDR localPath, esi) - stdcall, 2 params
    ; localPath is at [ebp-2052]
    push esi
    lea eax, [ebp-2052]
    push eax
    call lstrcpyA

    ; Comparer avec "."
    lea eax, [ebp-2052]   ; localPath
    push eax
    ; lstrlenA(eax) - stdcall, 1 param
    push eax
    call lstrlenA
    pop eax                ; restore localPath pointer (was pushed before lstrlenA)
    cmp BYTE PTR [eax], '.'
    jne _LD_notDot
    cmp BYTE PTR [eax+1], 0
    je _LD_findNext
    cmp BYTE PTR [eax+1], '.'
    jne _LD_notDot
    cmp BYTE PTR [eax+2], 0
    je _LD_findNext

_LD_notDot:
    ; --- Ignorer les jonctions (Reparse Points) pour éviter la récursion infinie ---
    test findData.dwFileAttributes, 400h ; FILE_ATTRIBUTE_REPARSE_POINT
    jnz _LD_findNext

    ; --- Vérifier si c'est un répertoire ---
    test findData.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY
    jnz _LD_isDirectory

    ; ======== C'est un fichier ========
    inc dwFileCount

    ; Afficher la date de dernière modification
    lea esi, findData.ftLastWriteTime
    lea edi, dateBuf
    call FormatFileTime
    lea esi, dateBuf
    call PrintStr

    ; Afficher la taille du fichier
    ; wsprintfA(ADDR printBuffer, ADDR msgFileFormat, findData.nFileSizeLow) - cdecl, 3 args
    push findData.nFileSizeLow
    push OFFSET msgFileFormat
    push OFFSET printBuffer
    call wsprintfA
    add esp, 12           ; cdecl: caller cleans 3 * 4 = 12 bytes
    lea esi, printBuffer
    call PrintStr

    ; Afficher le nom du fichier
    lea esi, findData.cFileName
    call PrintStr
    lea esi, msgNewLine
    call PrintStr

    jmp _LD_findNext

_LD_isDirectory:
    ; ======== C'est un répertoire ========
    inc dwDirCount

    ; Afficher la date
    lea esi, findData.ftLastWriteTime
    lea edi, dateBuf
    call FormatFileTime
    lea esi, dateBuf
    call PrintStr

    ; Afficher le tag <REP>
    lea esi, msgDirTag
    call PrintStr

    ; Afficher le nom du répertoire
    lea esi, findData.cFileName
    call PrintStr
    lea esi, msgNewLine
    call PrintStr

    ; --- Construire le chemin du sous-répertoire ---
    ; subDir is at [ebp-4100]
    lea edi, [ebp-4100]

    ; lstrcpyA(edi, ebx) - stdcall, 2 params
    push ebx
    push edi
    call lstrcpyA

    ; lstrcatA(edi, ADDR szBackslash) - stdcall, 2 params
    push OFFSET szBackslash
    lea edi, [ebp-4100]
    push edi
    call lstrcatA

    ; lstrcatA(edi, ADDR findData.cFileName) - stdcall, 2 params
    push OFFSET findData.cFileName
    lea edi, [ebp-4100]
    push edi
    call lstrcatA

    ; --- APPEL RÉCURSIF ---
    push ebx
    lea ebx, [ebp-4100]   ; subDir
    call ListDirectory
    pop ebx

_LD_findNext:
    ; --- Fichier suivant ---
    ; FindNextFileA(hFind, ADDR findData) - stdcall, 2 params
    push OFFSET findData
    push DWORD PTR [ebp-4] ; hFind
    call FindNextFileA
    test eax, eax
    jnz _LD_findLoop

    ; --- Fermer le handle de recherche ---
    ; FindClose(hFind) - stdcall, 1 param
    push DWORD PTR [ebp-4] ; hFind
    call FindClose

_LD_exit:
    popad
    mov esp, ebp
    pop ebp
    ret

; ============================================================================
; Point d'entrée principal
; ============================================================================
main:
    push ebp
    mov ebp, esp

    ; Configurer la console en UTF-8 (code page 65001)
    ; SetConsoleOutputCP(65001) - stdcall, 1 param
    push 65001
    call SetConsoleOutputCP

    ; Obtenir les handles de la console
    ; GetStdHandle(STD_OUTPUT_HANDLE) - stdcall, 1 param
    push STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOut, eax

    ; GetStdHandle(STD_INPUT_HANDLE) - stdcall, 1 param
    push STD_INPUT_HANDLE
    call GetStdHandle
    mov hStdIn, eax

    ; Afficher la bannière
    lea esi, msgBanner
    call PrintStr

    ; Demander le répertoire de départ
    lea esi, msgPrompt
    call PrintStr

    ; Lire l'entrée utilisateur
    ; ReadConsoleA(hStdIn, ADDR inputBuffer, 512, ADDR dwBytesRead, 0) - stdcall, 5 params
    push 0
    push OFFSET dwBytesRead
    push 512
    push OFFSET inputBuffer
    push hStdIn
    call ReadConsoleA

    ; Supprimer le CR/LF de fin
    lea edi, inputBuffer
    call TrimCRLF

    ; Vérifier que l'entrée n'est pas vide
    ; lstrlenA(ADDR inputBuffer) - stdcall, 1 param
    push OFFSET inputBuffer
    call lstrlenA
    test eax, eax
    jz _main_error

    ; Supprimer le backslash final s'il y en a un
    lea edi, inputBuffer
    ; lstrlenA(edi) - stdcall, 1 param
    push edi
    call lstrlenA
    dec eax
    cmp BYTE PTR [edi + eax], '\'
    jne _main_noTrailingSlash
    mov BYTE PTR [edi + eax], 0
_main_noTrailingSlash:

    ; Afficher le message de scan
    lea esi, msgScanning
    call PrintStr

    ; Initialiser les compteurs
    mov dwFileCount, 0
    mov dwDirCount, 0

    ; Lancer le listage récursif
    lea ebx, inputBuffer
    call ListDirectory

    ; Afficher le résumé final
    ; wsprintfA(ADDR printBuffer, ADDR msgFileCount, dwFileCount, dwDirCount) - cdecl, 4 args
    push dwDirCount
    push dwFileCount
    push OFFSET msgFileCount
    push OFFSET printBuffer
    call wsprintfA
    add esp, 16           ; cdecl: caller cleans 4 * 4 = 16 bytes
    lea esi, printBuffer
    call PrintStr

    jmp _main_exit

_main_error:
    lea esi, msgError
    call PrintStr

_main_exit:
    lea esi, msgPause
    call PrintStr

    ; ReadConsoleA(hStdIn, ADDR inputBuffer, 512, ADDR dwBytesRead, 0) - stdcall, 5 params
    push 0
    push OFFSET dwBytesRead
    push 512
    push OFFSET inputBuffer
    push hStdIn
    call ReadConsoleA

    ; ExitProcess(0) - stdcall, 1 param
    push 0
    call ExitProcess

    mov esp, ebp
    pop ebp
    ret

END main

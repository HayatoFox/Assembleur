; ============================================================================
; DIR /S Clone - Version Ligne de Commande
; Assembleur x86 (MASM) pour Windows
; 
; Listage récursif des fichiers à partir d'un répertoire donné par l'utilisateur
; Equivalent de la commande Windows DIR /S
;
; Assemblage:  ml /c /coff dir_recursive_cli.asm
; Liaison:     link /SUBSYSTEM:CONSOLE dir_recursive_cli.obj kernel32.lib
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
    printBuffer     BYTE 1024 dup(?)
    dateBuf         BYTE 128 dup(?)
    dwBytesWritten  DWORD ?
    dwBytesRead     DWORD ?
    sysTime         SYSTEMTIME <>

; ============================================================================
; Segment de code
; ============================================================================
.code

; ----------------------------------------------------------------------------
; PrintStr - Affiche une chaîne terminée par 0 sur la console
; Entrée : ESI = pointeur vers la chaîne
; ----------------------------------------------------------------------------
PrintStr PROC
    push eax
    push ecx
    push edx

    ; Calculer la longueur de la chaîne
    invoke lstrlenA, esi
    mov ecx, eax

    ; Écrire sur la console
    invoke WriteConsoleA, hStdOut, esi, ecx, ADDR dwBytesWritten, 0

    pop edx
    pop ecx
    pop eax
    ret
PrintStr ENDP

; ----------------------------------------------------------------------------
; TrimCRLF - Supprime les CR/LF en fin de chaîne
; Entrée : EDI = pointeur vers la chaîne
; ----------------------------------------------------------------------------
TrimCRLF PROC
    push eax
    push ecx

    invoke lstrlenA, edi
    test eax, eax
    jz @@done

    lea ecx, [edi + eax - 1]
@@loop:
    cmp ecx, edi
    jb @@done
    mov al, [ecx]
    cmp al, 13          ; CR
    je @@trim
    cmp al, 10          ; LF
    je @@trim
    cmp al, 32          ; espace
    je @@trim
    jmp @@done
@@trim:
    mov BYTE PTR [ecx], 0
    dec ecx
    jmp @@loop
@@done:
    pop ecx
    pop eax
    ret
TrimCRLF ENDP

; ----------------------------------------------------------------------------
; FormatFileTime - Formate un FILETIME en chaîne date/heure lisible
; Entrée : ESI = pointeur vers FILETIME
;          EDI = pointeur vers buffer de sortie
; ----------------------------------------------------------------------------
FormatFileTime PROC
    pushad

    ; Convertir FILETIME en SYSTEMTIME
    invoke FileTimeToSystemTime, esi, ADDR sysTime

    ; Formater la date
    movzx eax, sysTime.wDay
    movzx ebx, sysTime.wMonth
    movzx ecx, sysTime.wYear
    movzx edx, sysTime.wHour
    movzx esi, sysTime.wMinute

    invoke wsprintfA, edi, ADDR msgDateFmt, eax, ebx, ecx, edx, esi

    popad
    ret
FormatFileTime ENDP

; ----------------------------------------------------------------------------
; ListDirectory - Procédure récursive de listage de répertoire
; Entrée : EBX = pointeur vers le chemin du répertoire à lister
; ----------------------------------------------------------------------------
ListDirectory PROC
    LOCAL hFind:DWORD
    LOCAL localPath[2048]:BYTE
    LOCAL subDir[2048]:BYTE
    LOCAL findData:WIN32_FIND_DATA
    LOCAL localSearch[2048]:BYTE

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
    lea edi, localSearch
    invoke lstrcpyA, edi, ebx
    invoke lstrcatA, edi, ADDR szWildcard

    ; --- Trouver le premier fichier ---
    invoke FindFirstFileA, ADDR localSearch, ADDR findData
    cmp eax, INVALID_HANDLE_VALUE
    je @@exit
    mov hFind, eax

@@findLoop:
    ; --- Ignorer "." et ".." ---
    lea esi, findData.cFileName
    invoke lstrcpyA, ADDR localPath, esi

    ; Comparer avec "."
    lea eax, localPath
    push eax
    invoke lstrlenA, eax
    pop eax
    cmp BYTE PTR [eax], '.'
    jne @@notDot
    cmp BYTE PTR [eax+1], 0
    je @@findNext
    cmp BYTE PTR [eax+1], '.'
    jne @@notDot
    cmp BYTE PTR [eax+2], 0
    je @@findNext

@@notDot:
    ; --- Vérifier si c'est un répertoire ---
    test findData.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY
    jnz @@isDirectory

    ; ======== C'est un fichier ========
    inc dwFileCount

    ; Afficher la date de dernière modification
    lea esi, findData.ftLastWriteTime
    lea edi, dateBuf
    call FormatFileTime
    lea esi, dateBuf
    call PrintStr

    ; Afficher la taille du fichier
    invoke wsprintfA, ADDR printBuffer, ADDR msgFileFormat, findData.nFileSizeLow
    lea esi, printBuffer
    call PrintStr

    ; Afficher le nom du fichier
    lea esi, findData.cFileName
    call PrintStr
    lea esi, msgNewLine
    call PrintStr

    jmp @@findNext

@@isDirectory:
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
    lea edi, subDir
    invoke lstrcpyA, edi, ebx
    invoke lstrcatA, edi, ADDR szBackslash
    invoke lstrcatA, edi, ADDR findData.cFileName

    ; --- APPEL RÉCURSIF ---
    lea ebx, subDir
    call ListDirectory

@@findNext:
    ; --- Fichier suivant ---
    invoke FindNextFileA, hFind, ADDR findData
    test eax, eax
    jnz @@findLoop

    ; --- Fermer le handle de recherche ---
    invoke FindClose, hFind

@@exit:
    popad
    ret
ListDirectory ENDP

; ============================================================================
; Point d'entrée principal
; ============================================================================
main PROC

    ; Configurer la console en UTF-8 (code page 65001)
    invoke SetConsoleOutputCP, 65001

    ; Obtenir les handles de la console
    invoke GetStdHandle, STD_OUTPUT_HANDLE
    mov hStdOut, eax
    invoke GetStdHandle, STD_INPUT_HANDLE
    mov hStdIn, eax

    ; Afficher la bannière
    lea esi, msgBanner
    call PrintStr

    ; Demander le répertoire de départ
    lea esi, msgPrompt
    call PrintStr

    ; Lire l'entrée utilisateur
    invoke ReadConsoleA, hStdIn, ADDR inputBuffer, 512, ADDR dwBytesRead, 0

    ; Supprimer le CR/LF de fin
    lea edi, inputBuffer
    call TrimCRLF

    ; Vérifier que l'entrée n'est pas vide
    invoke lstrlenA, ADDR inputBuffer
    test eax, eax
    jz @@error

    ; Supprimer le backslash final s'il y en a un
    lea edi, inputBuffer
    invoke lstrlenA, edi
    dec eax
    cmp BYTE PTR [edi + eax], '\'
    jne @@noTrailingSlash
    mov BYTE PTR [edi + eax], 0
@@noTrailingSlash:

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
    invoke wsprintfA, ADDR printBuffer, ADDR msgFileCount, dwFileCount, dwDirCount
    lea esi, printBuffer
    call PrintStr

    jmp @@exit

@@error:
    lea esi, msgError
    call PrintStr

@@exit:
    ; Attendre une touche avant de fermer
    lea esi, msgPause
    call PrintStr
    invoke ReadConsoleA, hStdIn, ADDR inputBuffer, 2, ADDR dwBytesRead, 0
    invoke ExitProcess, 0

main ENDP

END main

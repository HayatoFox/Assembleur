; ============================================================================
; DIR /S Clone - Version Interface Graphique (GUI)
; Assembleur x86 (MASM) pour Windows
;
; Interface graphique Win32 avec:
;   - Champ de saisie pour le repertoire de depart
;   - Bouton "Parcourir..." (Browse)
;   - Bouton "Lister" pour lancer le scan
;   - ListView avec colonnes (Nom, Taille, Date, Chemin) et scrolling
;   - Barre de statut avec compteurs
;
; Version sans pseudo-instructions MASM dans le segment .code
; (pas de INVOKE, .IF, .WHILE, .FOR, LOCAL, PROC avec parametres)
;
; Assemblage:  ml /c /coff dir_recursive_gui.asm
; Liaison:     link /SUBSYSTEM:WINDOWS dir_recursive_gui.obj kernel32.lib
;              user32.lib gdi32.lib comctl32.lib comdlg32.lib shell32.lib
; ============================================================================

.386
.model flat, stdcall
option casemap:none

; ============================================================================
; Constantes
; ============================================================================

; IDs des controles
IDC_EDIT_PATH       equ 1001
IDC_BTN_BROWSE      equ 1002
IDC_BTN_LIST        equ 1003
IDC_BTN_CLEAR       equ 1004
IDC_LISTVIEW        equ 1005
IDC_STATUSBAR       equ 1006

; Constantes Windows
WS_OVERLAPPEDWINDOW equ 00CF0000h
WS_VISIBLE          equ 10000000h
WS_CHILD            equ 40000000h
WS_BORDER           equ 00800000h
WS_VSCROLL          equ 00200000h
WS_HSCROLL          equ 00100000h
WS_TABSTOP          equ 00010000h
WS_CLIPCHILDREN     equ 02000000h
WS_EX_CLIENTEDGE    equ 00000200h

; Styles de bouton
BS_PUSHBUTTON       equ 00000000h
BS_DEFPUSHBUTTON    equ 00000001h

; Styles Edit
ES_AUTOHSCROLL      equ 0080h

; Window Messages
WM_CREATE           equ 0001h
WM_DESTROY          equ 0002h
WM_SIZE             equ 0005h
WM_CLOSE            equ 0010h
WM_COMMAND          equ 0111h
WM_NOTIFY           equ 004Eh

; Autres constantes
SW_SHOW             equ 5
CW_USEDEFAULT       equ 80000000h
MAX_PATH            equ 260
INVALID_HANDLE_VALUE equ -1
NULL                equ 0
TRUE                equ 1
FALSE               equ 0
BN_CLICKED          equ 0

; Constantes de fichiers
FILE_ATTRIBUTE_DIRECTORY equ 10h

; ListView constantes
LVS_REPORT          equ 0001h
LVS_SINGLESEL       equ 0004h
LVS_SHOWSELALWAYS   equ 0008h
LVS_EX_FULLROWSELECT equ 00000020h
LVS_EX_GRIDLINES    equ 00000001h
LVS_EX_DOUBLEBUFFER equ 00010000h

LVCF_FMT            equ 0001h
LVCF_WIDTH          equ 0002h
LVCF_TEXT           equ 0004h
LVCF_SUBITEM        equ 0008h
LVCFMT_LEFT         equ 0000h
LVCFMT_RIGHT        equ 0001h

LVIF_TEXT            equ 0001h
LVIF_IMAGE           equ 0002h

LVM_FIRST            equ 1000h
LVM_INSERTCOLUMNA    equ LVM_FIRST + 27
LVM_INSERTITEMA      equ LVM_FIRST + 7
LVM_SETITEMA         equ LVM_FIRST + 6
LVM_DELETEALLITEMS   equ LVM_FIRST + 9
LVM_SETEXTENDEDLISTVIEWSTYLE equ LVM_FIRST + 54
LVM_GETITEMCOUNT     equ LVM_FIRST + 4

; Browse for Folder
BIF_RETURNONLYFSDIRS equ 0001h
BIF_USENEWUI         equ 0050h

; Status bar
SB_SETTEXTA          equ 0401h
SBARS_SIZEGRIP       equ 0100h

; Common Controls
ICC_LISTVIEW_CLASSES equ 00000001h
ICC_BAR_CLASSES      equ 00000004h

; ============================================================================
; Structures
; ============================================================================

WNDCLASSEXA STRUCT
    cbSize          DWORD ?
    style           DWORD ?
    lpfnWndProc     DWORD ?
    cbClsExtra      DWORD ?
    cbWndExtra      DWORD ?
    hInstance       DWORD ?
    hIcon           DWORD ?
    hCursor         DWORD ?
    hbrBackground   DWORD ?
    lpszMenuName    DWORD ?
    lpszClassName   DWORD ?
    hIconSm        DWORD ?
WNDCLASSEXA ENDS

POINT STRUCT
    x DWORD ?
    y DWORD ?
POINT ENDS

MSG STRUCT
    hWnd    DWORD ?
    message DWORD ?
    wParam  DWORD ?
    lParam  DWORD ?
    time    DWORD ?
    pt      POINT <>
MSG ENDS

RECT STRUCT
    left    DWORD ?
    top     DWORD ?
    right   DWORD ?
    bottom  DWORD ?
RECT ENDS

WIN32_FIND_DATA STRUCT
    dwFileAttributes    DWORD ?
    ftCreationTime      DWORD 2 dup(?)
    ftLastAccessTime    DWORD 2 dup(?)
    ftLastWriteTime     DWORD 2 dup(?)
    nFileSizeHigh       DWORD ?
    nFileSizeLow        DWORD ?
    dwReserved0         DWORD ?
    dwReserved1         DWORD ?
    cFileName           BYTE MAX_PATH dup(?)
    cAlternateFileName  BYTE 14 dup(?)
WIN32_FIND_DATA ENDS

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

LVCOLUMNA STRUCT
    mask_       DWORD ?
    fmt         DWORD ?
    lx          DWORD ?
    pszText     DWORD ?
    cchTextMax  DWORD ?
    iSubItem    DWORD ?
    iImage      DWORD ?
    iOrder      DWORD ?
LVCOLUMNA ENDS

LVITEMA STRUCT
    mask_       DWORD ?
    iItem       DWORD ?
    iSubItem    DWORD ?
    state       DWORD ?
    stateMask   DWORD ?
    pszText     DWORD ?
    cchTextMax  DWORD ?
    iImage      DWORD ?
    lParam      DWORD ?
LVITEMA ENDS

BROWSEINFOA STRUCT
    hWndOwner       DWORD ?
    pidlRoot        DWORD ?
    pszDisplayName  DWORD ?
    lpszTitle       DWORD ?
    ulFlags         DWORD ?
    lpfn            DWORD ?
    lParam          DWORD ?
    iImage          DWORD ?
BROWSEINFOA ENDS

INITCOMMONCONTROLSEX STRUCT
    dwSize  DWORD ?
    dwICC   DWORD ?
INITCOMMONCONTROLSEX ENDS

; ============================================================================
; Prototypes API Windows
; ============================================================================
ExitProcess             PROTO :DWORD
GetModuleHandleA        PROTO :DWORD
RegisterClassExA        PROTO :DWORD
CreateWindowExA         PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,
                              :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ShowWindow              PROTO :DWORD,:DWORD
UpdateWindow            PROTO :DWORD
GetMessageA             PROTO :DWORD,:DWORD,:DWORD,:DWORD
TranslateMessage        PROTO :DWORD
DispatchMessageA        PROTO :DWORD
PostQuitMessage         PROTO :DWORD
DefWindowProcA          PROTO :DWORD,:DWORD,:DWORD,:DWORD
SendMessageA            PROTO :DWORD,:DWORD,:DWORD,:DWORD
GetWindowTextA          PROTO :DWORD,:DWORD,:DWORD
SetWindowTextA          PROTO :DWORD,:DWORD
MoveWindow              PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
GetClientRect           PROTO :DWORD,:DWORD
LoadCursorA             PROTO :DWORD,:DWORD
LoadIconA               PROTO :DWORD,:DWORD
GetStockObject          PROTO :DWORD
CreateFontIndirectA     PROTO :DWORD
DestroyWindow           PROTO :DWORD
InvalidateRect          PROTO :DWORD,:DWORD,:DWORD
EnableWindow            PROTO :DWORD,:DWORD
SetFocus                PROTO :DWORD
MessageBoxA             PROTO :DWORD,:DWORD,:DWORD,:DWORD

; Fichiers
FindFirstFileA          PROTO :DWORD,:DWORD
FindNextFileA           PROTO :DWORD,:DWORD
FindClose               PROTO :DWORD
FileTimeToSystemTime    PROTO :DWORD,:DWORD

; Chaines
lstrlenA                PROTO :DWORD
lstrcpyA                PROTO :DWORD,:DWORD
lstrcatA                PROTO :DWORD,:DWORD
wsprintfA               PROTO C :DWORD,:DWORD,:VARARG

; Controles communs
InitCommonControlsEx    PROTO :DWORD

; Shell - Browse for folder
SHBrowseForFolderA      PROTO :DWORD
SHGetPathFromIDListA    PROTO :DWORD,:DWORD
CoTaskMemFree           PROTO :DWORD

; ============================================================================
; Donnees
; ============================================================================
.data

    szClassName     BYTE "DirRecursiveGUI", 0
    szWindowTitle   BYTE "DIR /S - Explorateur Recursif ASM", 0

    szBtnBrowse     BYTE "Parcourir...", 0
    szBtnList       BYTE "Lister", 0
    szBtnClear      BYTE "Effacer", 0
    szEditClass     BYTE "EDIT", 0
    szButtonClass   BYTE "BUTTON", 0
    szListViewClass BYTE "SysListView32", 0
    szStatusClass   BYTE "msctls_statusbar32", 0
    szStaticClass   BYTE "STATIC", 0

    ; Labels des colonnes du ListView
    szColName       BYTE "Nom", 0
    szColSize       BYTE "Taille", 0
    szColDate       BYTE "Date de modification", 0
    szColPath       BYTE "Chemin complet", 0
    szColType       BYTE "Type", 0

    ; Tags
    szTypeFile      BYTE "Fichier", 0
    szTypeDir       BYTE "<REP>", 0

    ; Formats
    szSizeFmt       BYTE "%lu", 0
    szDateFmt       BYTE "%02d/%02d/%04d %02d:%02d", 0
    szStatusFmt     BYTE " %d fichier(s)  |  %d repertoire(s)  |  %d element(s) total", 0

    ; Messages
    szBrowseTitle   BYTE "Selectionnez le repertoire de depart :", 0
    szDefaultPath   BYTE "C:\", 0
    szErrEmpty      BYTE "Veuillez specifier un repertoire.", 0
    szErrNotFound   BYTE "Repertoire introuvable ou inaccessible.", 0
    szAppTitle      BYTE "DIR /S ASM", 0

    ; Recherche
    szWildcard      BYTE "\*", 0
    szBackslash     BYTE "\", 0

    ; Compteurs
    dwFileCount     DWORD 0
    dwDirCount      DWORD 0
    dwTotalItems    DWORD 0

    ; Handles
    hInstance       DWORD ?
    hWndMain        DWORD ?
    hWndEdit        DWORD ?
    hWndBtnBrowse   DWORD ?
    hWndBtnList     DWORD ?
    hWndBtnClear    DWORD ?
    hWndListView    DWORD ?
    hWndStatus      DWORD ?

.data?
    msgStruct       MSG <>
    wc              WNDCLASSEXA <>
    findData        WIN32_FIND_DATA <>
    sysTime         SYSTEMTIME <>
    clientRect      RECT <>
    browseInfo      BROWSEINFOA <>
    iccex           INITCOMMONCONTROLSEX <>

    inputPath       BYTE 512 dup(?)
    searchPath      BYTE 2048 dup(?)
    tempBuffer      BYTE 2048 dup(?)
    sizeBuffer      BYTE 64 dup(?)
    dateBuffer      BYTE 64 dup(?)
    statusBuffer    BYTE 256 dup(?)
    browsePath      BYTE MAX_PATH dup(?)
    displayName     BYTE MAX_PATH dup(?)

; ============================================================================
; Code
; ============================================================================
.code

; ----------------------------------------------------------------------------
; SetupListViewColumns - Initialise les colonnes du ListView
; Stack frame: LOCAL lvc:LVCOLUMNA (32 bytes) at [ebp-32]
; ----------------------------------------------------------------------------
SetupListViewColumns:
    push ebp
    mov ebp, esp
    sub esp, 32                         ; LVCOLUMNA = 8 DWORDs = 32 bytes
    ; lvc at [ebp-32]
    ; lvc.mask_    = [ebp-32]
    ; lvc.fmt      = [ebp-28]
    ; lvc.lx       = [ebp-24]
    ; lvc.pszText  = [ebp-20]
    ; lvc.cchTextMax = [ebp-16]
    ; lvc.iSubItem = [ebp-12]
    ; lvc.iImage   = [ebp-8]
    ; lvc.iOrder   = [ebp-4]

    ; Colonne 0 : Type
    mov DWORD PTR [ebp-32], LVCF_FMT or LVCF_WIDTH or LVCF_TEXT or LVCF_SUBITEM  ; mask_
    mov DWORD PTR [ebp-28], LVCFMT_LEFT    ; fmt
    mov DWORD PTR [ebp-24], 70             ; lx
    lea eax, szColType
    mov DWORD PTR [ebp-20], eax            ; pszText
    mov DWORD PTR [ebp-12], 0             ; iSubItem
    ; SendMessageA(hWndListView, LVM_INSERTCOLUMNA, 0, &lvc) - stdcall
    lea eax, [ebp-32]
    push eax                               ; lParam = &lvc
    push 0                                 ; wParam = 0
    push LVM_INSERTCOLUMNA                 ; uMsg
    push DWORD PTR [hWndListView]          ; hWnd
    call SendMessageA

    ; Colonne 1 : Nom
    mov DWORD PTR [ebp-24], 250            ; lx
    lea eax, szColName
    mov DWORD PTR [ebp-20], eax            ; pszText
    mov DWORD PTR [ebp-12], 1             ; iSubItem
    lea eax, [ebp-32]
    push eax
    push 1
    push LVM_INSERTCOLUMNA
    push DWORD PTR [hWndListView]
    call SendMessageA

    ; Colonne 2 : Taille
    mov DWORD PTR [ebp-28], LVCFMT_RIGHT   ; fmt
    mov DWORD PTR [ebp-24], 120            ; lx
    lea eax, szColSize
    mov DWORD PTR [ebp-20], eax            ; pszText
    mov DWORD PTR [ebp-12], 2             ; iSubItem
    lea eax, [ebp-32]
    push eax
    push 2
    push LVM_INSERTCOLUMNA
    push DWORD PTR [hWndListView]
    call SendMessageA

    ; Colonne 3 : Date
    mov DWORD PTR [ebp-28], LVCFMT_LEFT    ; fmt
    mov DWORD PTR [ebp-24], 160            ; lx
    lea eax, szColDate
    mov DWORD PTR [ebp-20], eax            ; pszText
    mov DWORD PTR [ebp-12], 3             ; iSubItem
    lea eax, [ebp-32]
    push eax
    push 3
    push LVM_INSERTCOLUMNA
    push DWORD PTR [hWndListView]
    call SendMessageA

    ; Colonne 4 : Chemin
    mov DWORD PTR [ebp-24], 400            ; lx
    lea eax, szColPath
    mov DWORD PTR [ebp-20], eax            ; pszText
    mov DWORD PTR [ebp-12], 4             ; iSubItem
    lea eax, [ebp-32]
    push eax
    push 4
    push LVM_INSERTCOLUMNA
    push DWORD PTR [hWndListView]
    call SendMessageA

    ; Activer le mode grille + selection ligne entiere + double buffering
    ; SendMessageA(hWndListView, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, styles)
    push LVS_EX_FULLROWSELECT or LVS_EX_GRIDLINES or LVS_EX_DOUBLEBUFFER
    push 0
    push LVM_SETEXTENDEDLISTVIEWSTYLE
    push DWORD PTR [hWndListView]
    call SendMessageA

    mov esp, ebp
    pop ebp
    ret

; ----------------------------------------------------------------------------
; AddListViewItem - Ajoute un element au ListView
;   pType    = [ebp+8]   pointeur vers "Fichier" ou "<REP>"
;   pName    = [ebp+12]  pointeur vers le nom du fichier/repertoire
;   pSize    = [ebp+16]  pointeur vers la taille formatee (ou "")
;   pDate    = [ebp+20]  pointeur vers la date formatee
;   pPath    = [ebp+24]  pointeur vers le chemin complet
;
; Locals:
;   lvi:LVITEMA (36 bytes) at [ebp-36]
;   nIndex:DWORD           at [ebp-40]
;
; lvi layout (LVITEMA = 9 DWORDs = 36 bytes):
;   lvi.mask_      = [ebp-36]
;   lvi.iItem      = [ebp-32]
;   lvi.iSubItem   = [ebp-28]
;   lvi.state      = [ebp-24]
;   lvi.stateMask  = [ebp-20]
;   lvi.pszText    = [ebp-16]
;   lvi.cchTextMax = [ebp-12]
;   lvi.iImage     = [ebp-8]
;   lvi.lParam     = [ebp-4]
; nIndex = [ebp-40]
; ----------------------------------------------------------------------------
AddListViewItem:
    push ebp
    mov ebp, esp
    sub esp, 40                         ; 36 (LVITEMA) + 4 (nIndex)

    ; Obtenir le nombre d'items actuels (sera l'index du nouvel item)
    ; SendMessageA(hWndListView, LVM_GETITEMCOUNT, 0, 0)
    push 0
    push 0
    push LVM_GETITEMCOUNT
    push DWORD PTR [hWndListView]
    call SendMessageA
    mov DWORD PTR [ebp-40], eax         ; nIndex = eax

    ; Inserer l'item principal (colonne 0 = Type)
    mov DWORD PTR [ebp-36], LVIF_TEXT   ; lvi.mask_
    mov eax, DWORD PTR [ebp-40]
    mov DWORD PTR [ebp-32], eax         ; lvi.iItem = nIndex
    mov DWORD PTR [ebp-28], 0          ; lvi.iSubItem = 0
    mov DWORD PTR [ebp-24], 0          ; lvi.state = 0
    mov DWORD PTR [ebp-20], 0          ; lvi.stateMask = 0
    mov eax, DWORD PTR [ebp+8]         ; pType
    mov DWORD PTR [ebp-16], eax         ; lvi.pszText = pType
    mov DWORD PTR [ebp-12], 0          ; lvi.cchTextMax = 0
    mov DWORD PTR [ebp-8], 0           ; lvi.iImage = 0
    mov DWORD PTR [ebp-4], 0           ; lvi.lParam = 0
    ; SendMessageA(hWndListView, LVM_INSERTITEMA, 0, &lvi)
    lea eax, [ebp-36]
    push eax
    push 0
    push LVM_INSERTITEMA
    push DWORD PTR [hWndListView]
    call SendMessageA

    ; Sous-item 1 = Nom
    mov eax, DWORD PTR [ebp-40]
    mov DWORD PTR [ebp-32], eax         ; lvi.iItem = nIndex
    mov DWORD PTR [ebp-28], 1          ; lvi.iSubItem = 1
    mov eax, DWORD PTR [ebp+12]         ; pName
    mov DWORD PTR [ebp-16], eax         ; lvi.pszText = pName
    lea eax, [ebp-36]
    push eax
    push 0
    push LVM_SETITEMA
    push DWORD PTR [hWndListView]
    call SendMessageA

    ; Sous-item 2 = Taille
    mov eax, DWORD PTR [ebp-40]
    mov DWORD PTR [ebp-32], eax         ; lvi.iItem = nIndex
    mov DWORD PTR [ebp-28], 2          ; lvi.iSubItem = 2
    mov eax, DWORD PTR [ebp+16]         ; pSize
    mov DWORD PTR [ebp-16], eax         ; lvi.pszText = pSize
    lea eax, [ebp-36]
    push eax
    push 0
    push LVM_SETITEMA
    push DWORD PTR [hWndListView]
    call SendMessageA

    ; Sous-item 3 = Date
    mov eax, DWORD PTR [ebp-40]
    mov DWORD PTR [ebp-32], eax         ; lvi.iItem = nIndex
    mov DWORD PTR [ebp-28], 3          ; lvi.iSubItem = 3
    mov eax, DWORD PTR [ebp+20]         ; pDate
    mov DWORD PTR [ebp-16], eax         ; lvi.pszText = pDate
    lea eax, [ebp-36]
    push eax
    push 0
    push LVM_SETITEMA
    push DWORD PTR [hWndListView]
    call SendMessageA

    ; Sous-item 4 = Chemin
    mov eax, DWORD PTR [ebp-40]
    mov DWORD PTR [ebp-32], eax         ; lvi.iItem = nIndex
    mov DWORD PTR [ebp-28], 4          ; lvi.iSubItem = 4
    mov eax, DWORD PTR [ebp+24]         ; pPath
    mov DWORD PTR [ebp-16], eax         ; lvi.pszText = pPath
    lea eax, [ebp-36]
    push eax
    push 0
    push LVM_SETITEMA
    push DWORD PTR [hWndListView]
    call SendMessageA

    mov esp, ebp
    pop ebp
    ret 20                              ; 5 params * 4 = 20 bytes (stdcall)

; ----------------------------------------------------------------------------
; UpdateStatusBar - Met a jour la barre de statut avec les compteurs
; No params, no locals
; ----------------------------------------------------------------------------
UpdateStatusBar:
    push ebp
    mov ebp, esp

    ; wsprintfA is cdecl: push args right-to-left, call, then add esp
    ; wsprintfA(statusBuffer, szStatusFmt, dwFileCount, dwDirCount, dwTotalItems)
    push DWORD PTR [dwTotalItems]
    push DWORD PTR [dwDirCount]
    push DWORD PTR [dwFileCount]
    push OFFSET szStatusFmt
    push OFFSET statusBuffer
    call wsprintfA
    add esp, 20                         ; cdecl: 5 args * 4 = 20

    ; SendMessageA(hWndStatus, SB_SETTEXTA, 0, &statusBuffer)
    push OFFSET statusBuffer
    push 0
    push SB_SETTEXTA
    push DWORD PTR [hWndStatus]
    call SendMessageA

    mov esp, ebp
    pop ebp
    ret

; ----------------------------------------------------------------------------
; ScanDirectory - Procedure recursive de scan (version GUI)
; Entree : EBX = pointeur vers le chemin a scanner (register convention)
;
; Stack frame locals (total 6292 bytes):
;   hFind            = [ebp-4]       (4 bytes)
;   localSearchPath  = [ebp-2052]    (2048 bytes)  starts at ebp-2052
;   subDirPath       = [ebp-4100]    (2048 bytes)  starts at ebp-4100
;   localSizeBuf     = [ebp-4164]    (64 bytes)    starts at ebp-4164
;   localDateBuf     = [ebp-4228]    (64 bytes)    starts at ebp-4228
;   localFullPath    = [ebp-6276]    (2048 bytes)  starts at ebp-6276
;   localSysTime     = [ebp-6292]    (16 bytes)    starts at ebp-6292
; ----------------------------------------------------------------------------

; Equates for ScanDirectory locals (offsets from ebp)
SD_hFind            equ DWORD PTR [ebp-4]
SD_localSearchPath  equ ebp-2052
SD_subDirPath       equ ebp-4100
SD_localSizeBuf     equ ebp-4164
SD_localDateBuf     equ ebp-4228
SD_localFullPath    equ ebp-6276
SD_localSysTime     equ ebp-6292

ScanDirectory:
    push ebp
    mov ebp, esp
    sub esp, 6292

    pushad

    ; Construire le chemin de recherche: localSearchPath = EBX + "\*"
    lea edi, [SD_localSearchPath]
    ; lstrcpyA(edi, ebx) - stdcall
    push ebx
    push edi
    call lstrcpyA
    ; lstrcatA(edi, &szWildcard) - stdcall
    lea edi, [SD_localSearchPath]
    push OFFSET szWildcard
    push edi
    call lstrcatA

    ; FindFirstFileA(&localSearchPath, &findData)
    push OFFSET findData
    lea eax, [SD_localSearchPath]
    push eax
    call FindFirstFileA
    cmp eax, INVALID_HANDLE_VALUE
    je @@sd_exit
    mov SD_hFind, eax

@@sd_findLoop:
    ; Ignorer "." et ".."
    lea eax, findData.cFileName
    cmp BYTE PTR [eax], '.'
    jne @@sd_notDot
    cmp BYTE PTR [eax+1], 0
    je @@sd_next
    cmp BYTE PTR [eax+1], '.'
    jne @@sd_notDot
    cmp BYTE PTR [eax+2], 0
    je @@sd_next

@@sd_notDot:
    ; --- Ignorer les jonctions (Reparse Points) pour eviter la recursion infinie ---
    test findData.dwFileAttributes, 400h ; FILE_ATTRIBUTE_REPARSE_POINT
    jnz @@sd_next

    ; Construire le chemin complet: localFullPath = EBX + "\" + cFileName
    lea edi, [SD_localFullPath]
    ; lstrcpyA(edi, ebx)
    push ebx
    push edi
    call lstrcpyA
    lea edi, [SD_localFullPath]
    ; lstrcatA(edi, &szBackslash)
    push OFFSET szBackslash
    push edi
    call lstrcatA
    lea edi, [SD_localFullPath]
    ; lstrcatA(edi, &findData.cFileName)
    push OFFSET findData.cFileName
    push edi
    call lstrcatA

    ; Formater la date
    ; FileTimeToSystemTime(&findData.ftLastWriteTime, &localSysTime)
    lea eax, [SD_localSysTime]
    push eax
    push OFFSET findData.ftLastWriteTime
    call FileTimeToSystemTime

    ; wsprintfA(localDateBuf, szDateFmt, day, month, year, hour, minute) - cdecl
    lea eax, [SD_localSysTime]
    movzx ecx, WORD PTR [eax+6]        ; wDay (offset 6 in SYSTEMTIME)
    movzx edx, WORD PTR [eax+2]        ; wMonth (offset 2)
    movzx esi, WORD PTR [eax]          ; wYear (offset 0)
    push esi                            ; year
    push edx                            ; month
    push ecx                            ; day
    ; Now push hour and minute (but wait - they come AFTER in the format string
    ; Format: "%02d/%02d/%04d %02d:%02d"
    ;   arg1=day, arg2=month, arg3=year, arg4=hour, arg5=minute
    ; wsprintfA pushes are right-to-left, so last arg first
    ; We need to redo this: push minute, hour, year, month, day, fmt, buf
    ; Let me redo properly:
    add esp, 12                         ; undo the 3 pushes above

    lea eax, [SD_localSysTime]
    movzx ecx, WORD PTR [eax+10]       ; wMinute (offset 10)
    push ecx
    movzx ecx, WORD PTR [eax+8]        ; wHour (offset 8)
    push ecx
    movzx ecx, WORD PTR [eax]          ; wYear (offset 0)
    push ecx
    movzx ecx, WORD PTR [eax+2]        ; wMonth (offset 2)
    push ecx
    movzx ecx, WORD PTR [eax+6]        ; wDay (offset 6)
    push ecx
    push OFFSET szDateFmt
    lea eax, [SD_localDateBuf]
    push eax
    call wsprintfA
    add esp, 28                         ; cdecl: 7 args * 4 = 28

    ; Est-ce un repertoire ?
    test findData.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY
    jnz @@sd_isDir

    ; === FICHIER ===
    inc dwFileCount
    inc dwTotalItems

    ; Formater la taille: wsprintfA(localSizeBuf, szSizeFmt, nFileSizeLow) - cdecl
    push DWORD PTR [findData.nFileSizeLow]
    push OFFSET szSizeFmt
    lea eax, [SD_localSizeBuf]
    push eax
    call wsprintfA
    add esp, 12                         ; cdecl: 3 args * 4 = 12

    ; Ajouter au ListView: AddListViewItem(&szTypeFile, &cFileName, &localSizeBuf, &localDateBuf, &localFullPath)
    lea eax, [SD_localFullPath]
    push eax                            ; pPath
    lea eax, [SD_localDateBuf]
    push eax                            ; pDate
    lea eax, [SD_localSizeBuf]
    push eax                            ; pSize
    push OFFSET findData.cFileName      ; pName
    push OFFSET szTypeFile              ; pType
    call AddListViewItem

    ; Mettre a jour le statut tous les 50 fichiers
    mov eax, dwTotalItems
    push edx
    xor edx, edx
    mov ecx, 50
    div ecx
    mov eax, edx                        ; remainder
    pop edx
    test eax, eax
    jnz @@sd_next
    call UpdateStatusBar
    jmp @@sd_next

@@sd_isDir:
    ; === REPERTOIRE ===
    inc dwDirCount
    inc dwTotalItems

    ; Taille vide pour les repertoires
    lea eax, [SD_localSizeBuf]
    mov BYTE PTR [eax], 0

    ; Ajouter au ListView: AddListViewItem(&szTypeDir, &cFileName, &localSizeBuf, &localDateBuf, &localFullPath)
    lea eax, [SD_localFullPath]
    push eax                            ; pPath
    lea eax, [SD_localDateBuf]
    push eax                            ; pDate
    lea eax, [SD_localSizeBuf]
    push eax                            ; pSize
    push OFFSET findData.cFileName      ; pName
    push OFFSET szTypeDir               ; pType
    call AddListViewItem

    ; APPEL RECURSIF sur le sous-repertoire
    push ebx
    lea ebx, [SD_localFullPath]
    call ScanDirectory
    pop ebx

@@sd_next:
    ; FindNextFileA(hFind, &findData)
    push OFFSET findData
    push SD_hFind
    call FindNextFileA
    test eax, eax
    jnz @@sd_findLoop

    ; FindClose(hFind)
    push SD_hFind
    call FindClose

@@sd_exit:
    popad
    mov esp, ebp
    pop ebp
    ret

; ----------------------------------------------------------------------------
; DoScan - Lance le scan depuis le chemin saisi
; No params, no locals
; ----------------------------------------------------------------------------
DoScan:
    push ebp
    mov ebp, esp

    ; Recuperer le texte du champ de saisie
    ; GetWindowTextA(hWndEdit, &inputPath, 512)
    push 512
    push OFFSET inputPath
    push DWORD PTR [hWndEdit]
    call GetWindowTextA
    test eax, eax
    jz @@ds_errEmpty

    ; Supprimer le backslash final eventuel
    ; lstrlenA(&inputPath)
    push OFFSET inputPath
    call lstrlenA
    dec eax
    lea edi, inputPath
    cmp BYTE PTR [edi + eax], '\'
    jne @@ds_noTrail
    mov BYTE PTR [edi + eax], 0
@@ds_noTrail:

    ; Vider le ListView
    ; SendMessageA(hWndListView, LVM_DELETEALLITEMS, 0, 0)
    push 0
    push 0
    push LVM_DELETEALLITEMS
    push DWORD PTR [hWndListView]
    call SendMessageA

    ; Reinitialiser les compteurs
    mov dwFileCount, 0
    mov dwDirCount, 0
    mov dwTotalItems, 0

    ; Desactiver le bouton pendant le scan
    ; EnableWindow(hWndBtnList, FALSE)
    push FALSE
    push DWORD PTR [hWndBtnList]
    call EnableWindow

    ; Lancer le scan recursif
    lea ebx, inputPath
    call ScanDirectory

    ; Mettre a jour la barre de statut finale
    call UpdateStatusBar

    ; Reactiver le bouton
    ; EnableWindow(hWndBtnList, TRUE)
    push TRUE
    push DWORD PTR [hWndBtnList]
    call EnableWindow

    ; SetFocus(hWndBtnList)
    push DWORD PTR [hWndBtnList]
    call SetFocus

    mov esp, ebp
    pop ebp
    ret

@@ds_errEmpty:
    ; MessageBoxA(hWndMain, &szErrEmpty, &szAppTitle, 0)
    push 0
    push OFFSET szAppTitle
    push OFFSET szErrEmpty
    push DWORD PTR [hWndMain]
    call MessageBoxA

    mov esp, ebp
    pop ebp
    ret

; ----------------------------------------------------------------------------
; DoBrowse - Ouvre la boite de dialogue de selection de dossier
; No params. LOCAL pidl:DWORD at [ebp-4]
; ----------------------------------------------------------------------------
DoBrowse:
    push ebp
    mov ebp, esp
    sub esp, 4                          ; pidl at [ebp-4]

    ; Initialiser la structure BROWSEINFO (zero out)
    lea edi, browseInfo
    mov ecx, SIZEOF BROWSEINFOA
    xor al, al
    rep stosb

    mov browseInfo.hWndOwner, 0
    mov eax, hWndMain
    mov browseInfo.hWndOwner, eax
    mov browseInfo.pidlRoot, 0
    lea eax, displayName
    mov browseInfo.pszDisplayName, eax
    lea eax, szBrowseTitle
    mov browseInfo.lpszTitle, eax
    mov browseInfo.ulFlags, BIF_RETURNONLYFSDIRS or BIF_USENEWUI

    ; Afficher la boite de dialogue
    ; SHBrowseForFolderA(&browseInfo)
    push OFFSET browseInfo
    call SHBrowseForFolderA
    test eax, eax
    jz @@db_cancel
    mov DWORD PTR [ebp-4], eax          ; pidl = eax

    ; Recuperer le chemin
    ; SHGetPathFromIDListA(pidl, &browsePath)
    push OFFSET browsePath
    push DWORD PTR [ebp-4]
    call SHGetPathFromIDListA

    ; Liberer la memoire
    ; CoTaskMemFree(pidl)
    push DWORD PTR [ebp-4]
    call CoTaskMemFree

    ; Mettre le chemin dans le champ de saisie
    ; SetWindowTextA(hWndEdit, &browsePath)
    push OFFSET browsePath
    push DWORD PTR [hWndEdit]
    call SetWindowTextA

@@db_cancel:
    mov esp, ebp
    pop ebp
    ret

; ----------------------------------------------------------------------------
; ResizeControls - Redimensionne les controles quand la fenetre change
; Param: hWnd = [ebp+8]  (1 param, stdcall)
; Locals:
;   cx_     = [ebp-4]
;   cy_     = [ebp-8]
;   statusH = [ebp-12]
; ----------------------------------------------------------------------------
ResizeControls:
    push ebp
    mov ebp, esp
    sub esp, 12
    push ebx                            ; save ebx (we use it)

    ; GetClientRect(hWnd, &clientRect)
    push OFFSET clientRect
    push DWORD PTR [ebp+8]
    call GetClientRect

    mov eax, clientRect.right
    sub eax, clientRect.left
    mov DWORD PTR [ebp-4], eax          ; cx_

    mov eax, clientRect.bottom
    sub eax, clientRect.top
    mov DWORD PTR [ebp-8], eax          ; cy_

    ; Hauteur de la barre de statut
    mov DWORD PTR [ebp-12], 22          ; statusH

    ; Champ de saisie: x=10, y=10, largeur = cx-240, hauteur=26
    ; MoveWindow(hWndEdit, 10, 10, cx_-240, 26, TRUE)
    mov eax, DWORD PTR [ebp-4]
    sub eax, 240
    push TRUE
    push 26
    push eax
    push 10
    push 10
    push DWORD PTR [hWndEdit]
    call MoveWindow

    ; Bouton Parcourir: apres le champ, largeur=100
    ; MoveWindow(hWndBtnBrowse, cx_-220, 10, 100, 26, TRUE)
    mov eax, DWORD PTR [ebp-4]
    sub eax, 220
    push TRUE
    push 26
    push 100
    push 10
    push eax
    push DWORD PTR [hWndBtnBrowse]
    call MoveWindow

    ; Bouton Lister: apres Parcourir
    ; MoveWindow(hWndBtnList, cx_-112, 10, 50, 26, TRUE)
    mov eax, DWORD PTR [ebp-4]
    sub eax, 112
    push TRUE
    push 26
    push 50
    push 10
    push eax
    push DWORD PTR [hWndBtnList]
    call MoveWindow

    ; Bouton Effacer: apres Lister
    ; MoveWindow(hWndBtnClear, cx_-58, 10, 52, 26, TRUE)
    mov eax, DWORD PTR [ebp-4]
    sub eax, 58
    push TRUE
    push 26
    push 52
    push 10
    push eax
    push DWORD PTR [hWndBtnClear]
    call MoveWindow

    ; ListView: x=10, y=46, largeur=cx-20, hauteur=cy-78
    ; MoveWindow(hWndListView, 10, 46, cx_-20, cy_-78, TRUE)
    mov eax, DWORD PTR [ebp-4]
    sub eax, 20
    mov ebx, DWORD PTR [ebp-8]
    sub ebx, 78
    push TRUE
    push ebx
    push eax
    push 46
    push 10
    push DWORD PTR [hWndListView]
    call MoveWindow

    ; Barre de statut (auto-resize via message WM_SIZE)
    ; SendMessageA(hWndStatus, WM_SIZE, 0, 0)
    push 0
    push 0
    push WM_SIZE
    push DWORD PTR [hWndStatus]
    call SendMessageA

    pop ebx                             ; restore ebx
    mov esp, ebp
    pop ebp
    ret 4                               ; 1 param * 4 = 4 (stdcall)

; ----------------------------------------------------------------------------
; WndProc - Procedure de fenetre principale (Windows callback)
; Params (stdcall, 4 params):
;   hWnd   = [ebp+8]
;   uMsg   = [ebp+12]
;   wParam = [ebp+16]
;   lParam = [ebp+20]
; No locals
; Returns with ret 16
; ----------------------------------------------------------------------------
WndProc:
    push ebp
    mov ebp, esp

    cmp DWORD PTR [ebp+12], WM_CREATE
    je @@wp_onCreate
    cmp DWORD PTR [ebp+12], WM_SIZE
    je @@wp_onSize
    cmp DWORD PTR [ebp+12], WM_COMMAND
    je @@wp_onCommand
    cmp DWORD PTR [ebp+12], WM_CLOSE
    je @@wp_onClose
    cmp DWORD PTR [ebp+12], WM_DESTROY
    je @@wp_onDestroy
    jmp @@wp_default

@@wp_onCreate:
    ; === Creer le champ de saisie (EDIT) ===
    ; CreateWindowExA(WS_EX_CLIENTEDGE, &szEditClass, &szDefaultPath,
    ;                 WS_CHILD|WS_VISIBLE|WS_TABSTOP|ES_AUTOHSCROLL,
    ;                 10, 10, 500, 26, hWnd, IDC_EDIT_PATH, hInstance, NULL)
    push NULL
    push DWORD PTR [hInstance]
    push IDC_EDIT_PATH
    push DWORD PTR [ebp+8]             ; hWnd
    push 26
    push 500
    push 10
    push 10
    push WS_CHILD or WS_VISIBLE or WS_TABSTOP or ES_AUTOHSCROLL
    push OFFSET szDefaultPath
    push OFFSET szEditClass
    push WS_EX_CLIENTEDGE
    call CreateWindowExA
    mov hWndEdit, eax

    ; === Bouton Parcourir ===
    push NULL
    push DWORD PTR [hInstance]
    push IDC_BTN_BROWSE
    push DWORD PTR [ebp+8]
    push 26
    push 100
    push 10
    push 520
    push WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or WS_TABSTOP
    push OFFSET szBtnBrowse
    push OFFSET szButtonClass
    push 0
    call CreateWindowExA
    mov hWndBtnBrowse, eax

    ; === Bouton Lister ===
    push NULL
    push DWORD PTR [hInstance]
    push IDC_BTN_LIST
    push DWORD PTR [ebp+8]
    push 26
    push 50
    push 10
    push 630
    push WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON or WS_TABSTOP
    push OFFSET szBtnList
    push OFFSET szButtonClass
    push 0
    call CreateWindowExA
    mov hWndBtnList, eax

    ; === Bouton Effacer ===
    push NULL
    push DWORD PTR [hInstance]
    push IDC_BTN_CLEAR
    push DWORD PTR [ebp+8]
    push 26
    push 52
    push 10
    push 690
    push WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or WS_TABSTOP
    push OFFSET szBtnClear
    push OFFSET szButtonClass
    push 0
    call CreateWindowExA
    mov hWndBtnClear, eax

    ; === ListView ===
    push NULL
    push DWORD PTR [hInstance]
    push IDC_LISTVIEW
    push DWORD PTR [ebp+8]
    push 450
    push 750
    push 46
    push 10
    push WS_CHILD or WS_VISIBLE or LVS_REPORT or LVS_SINGLESEL or LVS_SHOWSELALWAYS or WS_TABSTOP
    push NULL
    push OFFSET szListViewClass
    push WS_EX_CLIENTEDGE
    call CreateWindowExA
    mov hWndListView, eax

    ; Initialiser les colonnes
    call SetupListViewColumns

    ; === Barre de statut ===
    push NULL
    push DWORD PTR [hInstance]
    push IDC_STATUSBAR
    push DWORD PTR [ebp+8]
    push 0
    push 0
    push 0
    push 0
    push WS_CHILD or WS_VISIBLE or SBARS_SIZEGRIP
    push NULL
    push OFFSET szStatusClass
    push 0
    call CreateWindowExA
    mov hWndStatus, eax

    ; Message initial dans la barre de statut
    ; SendMessageA(hWndStatus, SB_SETTEXTA, 0, &szBrowseTitle)
    push OFFSET szBrowseTitle
    push 0
    push SB_SETTEXTA
    push DWORD PTR [hWndStatus]
    call SendMessageA

    xor eax, eax
    mov esp, ebp
    pop ebp
    ret 16

@@wp_onSize:
    ; ResizeControls(hWnd) - stdcall, 1 param
    push DWORD PTR [ebp+8]
    call ResizeControls
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret 16

@@wp_onCommand:
    ; Tester quel bouton a ete clique
    movzx eax, WORD PTR [ebp+16]       ; ID du controle (LOWORD of wParam)
    mov ecx, DWORD PTR [ebp+16]
    shr ecx, 16                         ; Code de notification (HIWORD)

    cmp ecx, BN_CLICKED
    jne @@wp_default

    cmp eax, IDC_BTN_LIST
    je @@wp_doList
    cmp eax, IDC_BTN_BROWSE
    je @@wp_doBrowse
    cmp eax, IDC_BTN_CLEAR
    je @@wp_doClear
    jmp @@wp_default

@@wp_doList:
    call DoScan
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret 16

@@wp_doBrowse:
    call DoBrowse
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret 16

@@wp_doClear:
    ; SendMessageA(hWndListView, LVM_DELETEALLITEMS, 0, 0)
    push 0
    push 0
    push LVM_DELETEALLITEMS
    push DWORD PTR [hWndListView]
    call SendMessageA
    mov dwFileCount, 0
    mov dwDirCount, 0
    mov dwTotalItems, 0
    call UpdateStatusBar
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret 16

@@wp_onClose:
    ; DestroyWindow(hWnd)
    push DWORD PTR [ebp+8]
    call DestroyWindow
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret 16

@@wp_onDestroy:
    ; PostQuitMessage(0)
    push 0
    call PostQuitMessage
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret 16

@@wp_default:
    ; DefWindowProcA(hWnd, uMsg, wParam, lParam)
    push DWORD PTR [ebp+20]
    push DWORD PTR [ebp+16]
    push DWORD PTR [ebp+12]
    push DWORD PTR [ebp+8]
    call DefWindowProcA
    mov esp, ebp
    pop ebp
    ret 16

; ============================================================================
; Point d'entree WinMain
; ============================================================================
WinMain:
    push ebp
    mov ebp, esp

    ; Obtenir le handle de l'instance
    ; GetModuleHandleA(NULL)
    push NULL
    call GetModuleHandleA
    mov hInstance, eax

    ; Initialiser les controles communs (ListView, StatusBar)
    mov iccex.dwSize, SIZEOF INITCOMMONCONTROLSEX
    mov iccex.dwICC, ICC_LISTVIEW_CLASSES or ICC_BAR_CLASSES
    ; InitCommonControlsEx(&iccex)
    push OFFSET iccex
    call InitCommonControlsEx

    ; === Enregistrer la classe de fenetre ===
    mov wc.cbSize, SIZEOF WNDCLASSEXA
    mov wc.style, 3                     ; CS_HREDRAW or CS_VREDRAW
    lea eax, WndProc
    mov wc.lpfnWndProc, eax
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, hInstance
    mov wc.hInstance, eax

    ; LoadIconA(NULL, 32512)  ; IDI_APPLICATION
    push 32512
    push NULL
    call LoadIconA
    mov wc.hIcon, eax
    mov wc.hIconSm, eax

    ; LoadCursorA(NULL, 32512)  ; IDC_ARROW
    push 32512
    push NULL
    call LoadCursorA
    mov wc.hCursor, eax

    ; GetStockObject(0)  ; WHITE_BRUSH
    push 0
    call GetStockObject
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, NULL
    lea eax, szClassName
    mov wc.lpszClassName, eax

    ; RegisterClassExA(&wc)
    push OFFSET wc
    call RegisterClassExA

    ; === Creer la fenetre principale ===
    ; CreateWindowExA(0, &szClassName, &szWindowTitle,
    ;                 WS_OVERLAPPEDWINDOW|WS_CLIPCHILDREN,
    ;                 CW_USEDEFAULT, CW_USEDEFAULT, 900, 600,
    ;                 NULL, NULL, hInstance, NULL)
    push NULL
    push DWORD PTR [hInstance]
    push NULL
    push NULL
    push 600
    push 900
    push CW_USEDEFAULT
    push CW_USEDEFAULT
    push WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN
    push OFFSET szWindowTitle
    push OFFSET szClassName
    push 0
    call CreateWindowExA
    mov hWndMain, eax

    ; Afficher la fenetre
    ; ShowWindow(hWndMain, SW_SHOW)
    push SW_SHOW
    push DWORD PTR [hWndMain]
    call ShowWindow

    ; UpdateWindow(hWndMain)
    push DWORD PTR [hWndMain]
    call UpdateWindow

    ; === Boucle de messages ===
@@wm_msgLoop:
    ; GetMessageA(&msgStruct, NULL, 0, 0)
    push 0
    push 0
    push NULL
    push OFFSET msgStruct
    call GetMessageA
    test eax, eax
    jz @@wm_exitLoop

    ; TranslateMessage(&msgStruct)
    push OFFSET msgStruct
    call TranslateMessage

    ; DispatchMessageA(&msgStruct)
    push OFFSET msgStruct
    call DispatchMessageA
    jmp @@wm_msgLoop

@@wm_exitLoop:
    mov eax, msgStruct.wParam
    ; ExitProcess(eax)
    push eax
    call ExitProcess

    mov esp, ebp
    pop ebp
    ret

END WinMain

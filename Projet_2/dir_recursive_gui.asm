; ============================================================================
; DIR /S Clone - Version Interface Graphique (GUI)
; Assembleur x86 (MASM) pour Windows
; 
; Interface graphique Win32 avec:
;   - Champ de saisie pour le répertoire de départ
;   - Bouton "Parcourir..." (Browse)
;   - Bouton "Lister" pour lancer le scan
;   - ListView avec colonnes (Nom, Taille, Date, Chemin) et scrolling
;   - Barre de statut avec compteurs
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

; IDs des contrôles
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
    cx_         DWORD ?
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

; Chaînes
lstrlenA                PROTO :DWORD
lstrcpyA                PROTO :DWORD,:DWORD
lstrcatA                PROTO :DWORD,:DWORD
wsprintfA               PROTO C :DWORD,:DWORD,:VARARG

; Contrôles communs
InitCommonControlsEx    PROTO :DWORD

; Shell - Browse for folder
SHBrowseForFolderA      PROTO :DWORD
SHGetPathFromIDListA    PROTO :DWORD,:DWORD
CoTaskMemFree           PROTO :DWORD

; ============================================================================
; Données
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
; ----------------------------------------------------------------------------
SetupListViewColumns PROC
    LOCAL lvc:LVCOLUMNA

    ; Colonne 0 : Type
    mov lvc.mask_, LVCF_FMT or LVCF_WIDTH or LVCF_TEXT or LVCF_SUBITEM
    mov lvc.fmt, LVCFMT_LEFT
    mov lvc.cx_, 70
    lea eax, szColType
    mov lvc.pszText, eax
    mov lvc.iSubItem, 0
    invoke SendMessageA, hWndListView, LVM_INSERTCOLUMNA, 0, ADDR lvc

    ; Colonne 1 : Nom
    mov lvc.cx_, 250
    lea eax, szColName
    mov lvc.pszText, eax
    mov lvc.iSubItem, 1
    invoke SendMessageA, hWndListView, LVM_INSERTCOLUMNA, 1, ADDR lvc

    ; Colonne 2 : Taille
    mov lvc.fmt, LVCFMT_RIGHT
    mov lvc.cx_, 120
    lea eax, szColSize
    mov lvc.pszText, eax
    mov lvc.iSubItem, 2
    invoke SendMessageA, hWndListView, LVM_INSERTCOLUMNA, 2, ADDR lvc

    ; Colonne 3 : Date
    mov lvc.fmt, LVCFMT_LEFT
    mov lvc.cx_, 160
    lea eax, szColDate
    mov lvc.pszText, eax
    mov lvc.iSubItem, 3
    invoke SendMessageA, hWndListView, LVM_INSERTCOLUMNA, 3, ADDR lvc

    ; Colonne 4 : Chemin
    mov lvc.cx_, 400
    lea eax, szColPath
    mov lvc.pszText, eax
    mov lvc.iSubItem, 4
    invoke SendMessageA, hWndListView, LVM_INSERTCOLUMNA, 4, ADDR lvc

    ; Activer le mode grille + sélection ligne entière + double buffering
    invoke SendMessageA, hWndListView, LVM_SETEXTENDEDLISTVIEWSTYLE, 0,
           LVS_EX_FULLROWSELECT or LVS_EX_GRIDLINES or LVS_EX_DOUBLEBUFFER

    ret
SetupListViewColumns ENDP

; ----------------------------------------------------------------------------
; AddListViewItem - Ajoute un élément au ListView
;   pType    = pointeur vers "Fichier" ou "<REP>"
;   pName    = pointeur vers le nom du fichier/répertoire
;   pSize    = pointeur vers la taille formatée (ou "")
;   pDate    = pointeur vers la date formatée
;   pPath    = pointeur vers le chemin complet
; ----------------------------------------------------------------------------
AddListViewItem PROC pType:DWORD, pName:DWORD, pSize:DWORD, pDate:DWORD, pPath:DWORD
    LOCAL lvi:LVITEMA
    LOCAL nIndex:DWORD

    ; Obtenir le nombre d'items actuels (sera l'index du nouvel item)
    invoke SendMessageA, hWndListView, LVM_GETITEMCOUNT, 0, 0
    mov nIndex, eax

    ; Insérer l'item principal (colonne 0 = Type)
    mov lvi.mask_, LVIF_TEXT
    mov eax, nIndex
    mov lvi.iItem, eax
    mov lvi.iSubItem, 0
    mov eax, pType
    mov lvi.pszText, eax
    invoke SendMessageA, hWndListView, LVM_INSERTITEMA, 0, ADDR lvi

    ; Sous-item 1 = Nom
    mov eax, nIndex
    mov lvi.iItem, eax
    mov lvi.iSubItem, 1
    mov eax, pName
    mov lvi.pszText, eax
    invoke SendMessageA, hWndListView, LVM_SETITEMA, 0, ADDR lvi

    ; Sous-item 2 = Taille
    mov eax, nIndex
    mov lvi.iItem, eax
    mov lvi.iSubItem, 2
    mov eax, pSize
    mov lvi.pszText, eax
    invoke SendMessageA, hWndListView, LVM_SETITEMA, 0, ADDR lvi

    ; Sous-item 3 = Date
    mov eax, nIndex
    mov lvi.iItem, eax
    mov lvi.iSubItem, 3
    mov eax, pDate
    mov lvi.pszText, eax
    invoke SendMessageA, hWndListView, LVM_SETITEMA, 0, ADDR lvi

    ; Sous-item 4 = Chemin
    mov eax, nIndex
    mov lvi.iItem, eax
    mov lvi.iSubItem, 4
    mov eax, pPath
    mov lvi.pszText, eax
    invoke SendMessageA, hWndListView, LVM_SETITEMA, 0, ADDR lvi

    ret
AddListViewItem ENDP

; ----------------------------------------------------------------------------
; UpdateStatusBar - Met à jour la barre de statut avec les compteurs
; ----------------------------------------------------------------------------
UpdateStatusBar PROC
    invoke wsprintfA, ADDR statusBuffer, ADDR szStatusFmt,
           dwFileCount, dwDirCount, dwTotalItems
    invoke SendMessageA, hWndStatus, SB_SETTEXTA, 0, ADDR statusBuffer
    ret
UpdateStatusBar ENDP

; ----------------------------------------------------------------------------
; ScanDirectory - Procédure récursive de scan (version GUI)
; Entrée : EBX = pointeur vers le chemin à scanner
; ----------------------------------------------------------------------------
ScanDirectory PROC
    LOCAL hFind:DWORD
    LOCAL localSearchPath[2048]:BYTE
    LOCAL subDirPath[2048]:BYTE
    LOCAL localSizeBuf[64]:BYTE
    LOCAL localDateBuf[64]:BYTE
    LOCAL localFullPath[2048]:BYTE
    LOCAL localSysTime:SYSTEMTIME
    LOCAL localFindData:WIN32_FIND_DATA

    pushad

    ; Construire le chemin de recherche
    lea edi, localSearchPath
    invoke lstrcpyA, edi, ebx
    invoke lstrcatA, edi, ADDR szWildcard

    ; FindFirstFile
    invoke FindFirstFileA, ADDR localSearchPath, ADDR localFindData
    cmp eax, INVALID_HANDLE_VALUE
    je @@exit
    mov hFind, eax

@@findLoop:
    ; Ignorer "." et ".."
    lea eax, localFindData.cFileName
    cmp BYTE PTR [eax], '.'
    jne @@notDot
    cmp BYTE PTR [eax+1], 0
    je @@next
    cmp BYTE PTR [eax+1], '.'
    jne @@notDot
    cmp BYTE PTR [eax+2], 0
    je @@next

@@notDot:
    ; Construire le chemin complet
    lea edi, localFullPath
    invoke lstrcpyA, edi, ebx
    invoke lstrcatA, edi, ADDR szBackslash
    invoke lstrcatA, edi, ADDR localFindData.cFileName

    ; Formater la date
    invoke FileTimeToSystemTime, ADDR localFindData.ftLastWriteTime, ADDR localSysTime
    movzx eax, localSysTime.wDay
    movzx ebx, localSysTime.wMonth
    movzx ecx, localSysTime.wYear
    movzx edx, localSysTime.wHour
    movzx esi, localSysTime.wMinute
    invoke wsprintfA, ADDR localDateBuf, ADDR szDateFmt, eax, ebx, ecx, edx, esi

    ; Est-ce un répertoire ?
    test localFindData.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY
    jnz @@isDir

    ; === FICHIER ===
    inc dwFileCount
    inc dwTotalItems

    ; Formater la taille
    invoke wsprintfA, ADDR localSizeBuf, ADDR szSizeFmt, localFindData.nFileSizeLow

    ; Ajouter au ListView
    invoke AddListViewItem, ADDR szTypeFile, ADDR localFindData.cFileName,
           ADDR localSizeBuf, ADDR localDateBuf, ADDR localFullPath

    ; Mettre à jour le statut tous les 50 fichiers
    mov eax, dwTotalItems
    push edx
    xor edx, edx
    mov ecx, 50
    div ecx
    pop edx
    test edx, edx
    jnz @@next
    call UpdateStatusBar
    jmp @@next

@@isDir:
    ; === RÉPERTOIRE ===
    inc dwDirCount
    inc dwTotalItems

    ; Taille vide pour les répertoires
    mov BYTE PTR localSizeBuf, 0

    ; Ajouter au ListView
    invoke AddListViewItem, ADDR szTypeDir, ADDR localFindData.cFileName,
           ADDR localSizeBuf, ADDR localDateBuf, ADDR localFullPath

    ; APPEL RÉCURSIF sur le sous-répertoire
    lea ebx, localFullPath
    call ScanDirectory

@@next:
    invoke FindNextFileA, hFind, ADDR localFindData
    test eax, eax
    jnz @@findLoop

    invoke FindClose, hFind

@@exit:
    popad
    ret
ScanDirectory ENDP

; ----------------------------------------------------------------------------
; DoScan - Lance le scan depuis le chemin saisi
; ----------------------------------------------------------------------------
DoScan PROC
    ; Récupérer le texte du champ de saisie
    invoke GetWindowTextA, hWndEdit, ADDR inputPath, 512
    test eax, eax
    jz @@errEmpty

    ; Supprimer le backslash final éventuel
    invoke lstrlenA, ADDR inputPath
    dec eax
    lea edi, inputPath
    cmp BYTE PTR [edi + eax], '\'
    jne @@noTrail
    mov BYTE PTR [edi + eax], 0
@@noTrail:

    ; Vider le ListView
    invoke SendMessageA, hWndListView, LVM_DELETEALLITEMS, 0, 0

    ; Réinitialiser les compteurs
    mov dwFileCount, 0
    mov dwDirCount, 0
    mov dwTotalItems, 0

    ; Désactiver le bouton pendant le scan
    invoke EnableWindow, hWndBtnList, FALSE

    ; Lancer le scan récursif
    lea ebx, inputPath
    call ScanDirectory

    ; Mettre à jour la barre de statut finale
    call UpdateStatusBar

    ; Réactiver le bouton
    invoke EnableWindow, hWndBtnList, TRUE
    invoke SetFocus, hWndBtnList

    ret

@@errEmpty:
    invoke MessageBoxA, hWndMain, ADDR szErrEmpty, ADDR szAppTitle, 0
    ret
DoScan ENDP

; ----------------------------------------------------------------------------
; DoBrowse - Ouvre la boîte de dialogue de sélection de dossier
; ----------------------------------------------------------------------------
DoBrowse PROC
    LOCAL pidl:DWORD

    ; Initialiser la structure BROWSEINFO
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

    ; Afficher la boîte de dialogue
    invoke SHBrowseForFolderA, ADDR browseInfo
    test eax, eax
    jz @@cancel
    mov pidl, eax

    ; Récupérer le chemin
    invoke SHGetPathFromIDListA, pidl, ADDR browsePath

    ; Libérer la mémoire
    invoke CoTaskMemFree, pidl

    ; Mettre le chemin dans le champ de saisie
    invoke SetWindowTextA, hWndEdit, ADDR browsePath

@@cancel:
    ret
DoBrowse ENDP

; ----------------------------------------------------------------------------
; ResizeControls - Redimensionne les contrôles quand la fenêtre change
; ----------------------------------------------------------------------------
ResizeControls PROC hWnd:DWORD
    LOCAL cx_:DWORD
    LOCAL cy_:DWORD
    LOCAL statusH:DWORD

    invoke GetClientRect, hWnd, ADDR clientRect

    mov eax, clientRect.right
    sub eax, clientRect.left
    mov cx_, eax

    mov eax, clientRect.bottom
    sub eax, clientRect.top
    mov cy_, eax

    ; Hauteur de la barre de statut
    mov statusH, 22

    ; Champ de saisie: x=10, y=10, largeur = cx-240, hauteur=26
    mov eax, cx_
    sub eax, 240
    invoke MoveWindow, hWndEdit, 10, 10, eax, 26, TRUE

    ; Bouton Parcourir: après le champ, largeur=100
    mov eax, cx_
    sub eax, 220
    invoke MoveWindow, hWndBtnBrowse, eax, 10, 100, 26, TRUE

    ; Bouton Lister: après Parcourir
    mov eax, cx_
    sub eax, 112
    invoke MoveWindow, hWndBtnList, eax, 10, 50, 26, TRUE

    ; Bouton Effacer: après Lister
    mov eax, cx_
    sub eax, 58
    invoke MoveWindow, hWndBtnClear, eax, 10, 52, 26, TRUE

    ; ListView: x=10, y=46, largeur=cx-20, hauteur=cy-78
    mov eax, cx_
    sub eax, 20
    mov ebx, cy_
    sub ebx, 78
    invoke MoveWindow, hWndListView, 10, 46, eax, ebx, TRUE

    ; Barre de statut (auto-resize via message WM_SIZE)
    invoke SendMessageA, hWndStatus, WM_SIZE, 0, 0

    ret
ResizeControls ENDP

; ----------------------------------------------------------------------------
; WndProc - Procédure de fenêtre principale
; ----------------------------------------------------------------------------
WndProc PROC hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD

    cmp uMsg, WM_CREATE
    je @@onCreate
    cmp uMsg, WM_SIZE
    je @@onSize
    cmp uMsg, WM_COMMAND
    je @@onCommand
    cmp uMsg, WM_CLOSE
    je @@onClose
    cmp uMsg, WM_DESTROY
    je @@onDestroy
    jmp @@default

@@onCreate:
    ; === Créer le champ de saisie (EDIT) ===
    invoke CreateWindowExA, WS_EX_CLIENTEDGE, ADDR szEditClass, ADDR szDefaultPath,
           WS_CHILD or WS_VISIBLE or WS_TABSTOP or ES_AUTOHSCROLL,
           10, 10, 500, 26, hWnd, IDC_EDIT_PATH, hInstance, NULL
    mov hWndEdit, eax

    ; === Bouton Parcourir ===
    invoke CreateWindowExA, 0, ADDR szButtonClass, ADDR szBtnBrowse,
           WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or WS_TABSTOP,
           520, 10, 100, 26, hWnd, IDC_BTN_BROWSE, hInstance, NULL
    mov hWndBtnBrowse, eax

    ; === Bouton Lister ===
    invoke CreateWindowExA, 0, ADDR szButtonClass, ADDR szBtnList,
           WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON or WS_TABSTOP,
           630, 10, 50, 26, hWnd, IDC_BTN_LIST, hInstance, NULL
    mov hWndBtnList, eax

    ; === Bouton Effacer ===
    invoke CreateWindowExA, 0, ADDR szButtonClass, ADDR szBtnClear,
           WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON or WS_TABSTOP,
           690, 10, 52, 26, hWnd, IDC_BTN_CLEAR, hInstance, NULL
    mov hWndBtnClear, eax

    ; === ListView ===
    invoke CreateWindowExA, WS_EX_CLIENTEDGE, ADDR szListViewClass, NULL,
           WS_CHILD or WS_VISIBLE or LVS_REPORT or LVS_SINGLESEL or LVS_SHOWSELALWAYS or WS_TABSTOP,
           10, 46, 750, 450, hWnd, IDC_LISTVIEW, hInstance, NULL
    mov hWndListView, eax

    ; Initialiser les colonnes
    call SetupListViewColumns

    ; === Barre de statut ===
    invoke CreateWindowExA, 0, ADDR szStatusClass, NULL,
           WS_CHILD or WS_VISIBLE or SBARS_SIZEGRIP,
           0, 0, 0, 0, hWnd, IDC_STATUSBAR, hInstance, NULL
    mov hWndStatus, eax

    ; Message initial dans la barre de statut
    invoke SendMessageA, hWndStatus, SB_SETTEXTA, 0, ADDR szBrowseTitle

    xor eax, eax
    ret

@@onSize:
    invoke ResizeControls, hWnd
    xor eax, eax
    ret

@@onCommand:
    ; Tester quel bouton a été cliqué
    movzx eax, WORD PTR wParam        ; ID du contrôle (LOWORD)
    mov ecx, wParam
    shr ecx, 16                        ; Code de notification (HIWORD)

    cmp ecx, BN_CLICKED
    jne @@default

    cmp eax, IDC_BTN_LIST
    je @@doList
    cmp eax, IDC_BTN_BROWSE
    je @@doBrowse
    cmp eax, IDC_BTN_CLEAR
    je @@doClear
    jmp @@default

@@doList:
    call DoScan
    xor eax, eax
    ret

@@doBrowse:
    call DoBrowse
    xor eax, eax
    ret

@@doClear:
    invoke SendMessageA, hWndListView, LVM_DELETEALLITEMS, 0, 0
    mov dwFileCount, 0
    mov dwDirCount, 0
    mov dwTotalItems, 0
    call UpdateStatusBar
    xor eax, eax
    ret

@@onClose:
    invoke DestroyWindow, hWnd
    xor eax, eax
    ret

@@onDestroy:
    invoke PostQuitMessage, 0
    xor eax, eax
    ret

@@default:
    invoke DefWindowProcA, hWnd, uMsg, wParam, lParam
    ret

WndProc ENDP

; ============================================================================
; Point d'entrée WinMain
; ============================================================================
WinMain PROC

    ; Obtenir le handle de l'instance
    invoke GetModuleHandleA, NULL
    mov hInstance, eax

    ; Initialiser les contrôles communs (ListView, StatusBar)
    mov iccex.dwSize, SIZEOF INITCOMMONCONTROLSEX
    mov iccex.dwICC, ICC_LISTVIEW_CLASSES or ICC_BAR_CLASSES
    invoke InitCommonControlsEx, ADDR iccex

    ; === Enregistrer la classe de fenêtre ===
    mov wc.cbSize, SIZEOF WNDCLASSEXA
    mov wc.style, 3                     ; CS_HREDRAW or CS_VREDRAW
    lea eax, WndProc
    mov wc.lpfnWndProc, eax
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov eax, hInstance
    mov wc.hInstance, eax

    invoke LoadIconA, NULL, 32512       ; IDI_APPLICATION
    mov wc.hIcon, eax
    mov wc.hIconSm, eax

    invoke LoadCursorA, NULL, 32512     ; IDC_ARROW
    mov wc.hCursor, eax

    invoke GetStockObject, 0            ; WHITE_BRUSH
    mov wc.hbrBackground, eax
    mov wc.lpszMenuName, NULL
    lea eax, szClassName
    mov wc.lpszClassName, eax

    invoke RegisterClassExA, ADDR wc

    ; === Créer la fenêtre principale ===
    invoke CreateWindowExA, 0,
           ADDR szClassName,
           ADDR szWindowTitle,
           WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN,
           CW_USEDEFAULT, CW_USEDEFAULT,   ; Position
           900, 600,                         ; Taille
           NULL, NULL, hInstance, NULL
    mov hWndMain, eax

    ; Afficher la fenêtre
    invoke ShowWindow, hWndMain, SW_SHOW
    invoke UpdateWindow, hWndMain

    ; === Boucle de messages ===
@@msgLoop:
    invoke GetMessageA, ADDR msgStruct, NULL, 0, 0
    test eax, eax
    jz @@exitLoop

    invoke TranslateMessage, ADDR msgStruct
    invoke DispatchMessageA, ADDR msgStruct
    jmp @@msgLoop

@@exitLoop:
    mov eax, msgStruct.wParam
    invoke ExitProcess, eax

WinMain ENDP

END WinMain

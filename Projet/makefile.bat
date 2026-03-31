@echo off
REM ============================================================================
REM Script de compilation - DIR /S Clone en Assembleur
REM Necessite: MASM32 SDK (ou Visual Studio avec ml.exe)
REM ============================================================================

echo.
echo  ====================================================
echo   Compilation du projet DIR /S en Assembleur x86
echo  ====================================================
echo.

REM --- Verifier la presence de MASM ---
where ml >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo  ERREUR: ml.exe [MASM] introuvable dans le PATH.
    echo  Installez MASM32 ou Visual Studio Build Tools.
    echo.
    echo  Option 1: MASM32 - http://www.masm32.com/
    echo  Option 2: VS Build Tools avec composant C++ Desktop
    echo.
    pause
    exit /b 1
)

REM ============================================================================
REM Version 1 : Ligne de commande (Console) - depuis cli/
REM ============================================================================
echo  [1/4] Assemblage de la version console...
ml /c /coff /Zi cli\dir_recursive_cli.asm
if %ERRORLEVEL% neq 0 (
    echo  ERREUR: Assemblage console echoue.
    exit /b 1
)

echo  [2/4] Edition de liens - version console...
link /SUBSYSTEM:CONSOLE /DEBUG dir_recursive_cli.obj kernel32.lib user32.lib
if %ERRORLEVEL% neq 0 (
    echo  ERREUR: Liaison console echouee.
    exit /b 1
)
echo  OK: dir_recursive_cli.exe genere.
echo.

REM ============================================================================
REM Version 2 : Interface Graphique (Windows) - depuis gui/
REM ============================================================================
echo  [3/4] Assemblage de la version GUI...
ml /c /coff /Zi gui\dir_recursive_gui.asm
if %ERRORLEVEL% neq 0 (
    echo  ERREUR: Assemblage GUI echoue.
    exit /b 1
)

echo  [4/4] Edition de liens - version GUI...
link /SUBSYSTEM:WINDOWS /DEBUG dir_recursive_gui.obj ^
    kernel32.lib user32.lib gdi32.lib comctl32.lib ^
    comdlg32.lib shell32.lib ole32.lib
if %ERRORLEVEL% neq 0 (
    echo  ERREUR: Liaison GUI echouee.
    exit /b 1
)
echo  OK: dir_recursive_gui.exe genere.
echo.

echo  ====================================================
echo   Compilation terminee avec succes !
echo  ====================================================
echo.
echo   Executables generes:
echo     - dir_recursive_cli.exe  (Console)
echo     - dir_recursive_gui.exe  (Interface graphique)
echo.

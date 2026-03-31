@echo off
set PATH=C:\masm32\bin;%PATH%
set LIB=C:\masm32\lib;%LIB%
set INCLUDE=C:\masm32\include;%INCLUDE%
cd /d C:\Users\rapha\Downloads\files

echo [1/4] Assemblage version console...
ml /c /coff /Zi dir_recursive_cli.asm
if errorlevel 1 goto err_cli_asm

echo [2/4] Liaison version console...
link /SUBSYSTEM:CONSOLE dir_recursive_cli.obj kernel32.lib user32.lib /OUT:dir_recursive_cli.exe
if errorlevel 1 goto err_cli_link

echo [3/4] Assemblage version GUI...
ml /c /coff /Zi dir_recursive_gui.asm
if errorlevel 1 goto err_gui_asm

echo [4/4] Liaison version GUI...
link /SUBSYSTEM:WINDOWS dir_recursive_gui.obj kernel32.lib user32.lib gdi32.lib comctl32.lib comdlg32.lib shell32.lib ole32.lib /OUT:dir_recursive_gui.exe
if errorlevel 1 goto err_gui_link

echo.
echo === Compilation reussie ! ===
echo   dir_recursive_cli.exe
echo   dir_recursive_gui.exe
goto end

:err_cli_asm
echo ERREUR: Assemblage CLI echoue
goto end
:err_cli_link
echo ERREUR: Liaison CLI echouee
goto end
:err_gui_asm
echo ERREUR: Assemblage GUI echoue
goto end
:err_gui_link
echo ERREUR: Liaison GUI echouee
goto end
:end

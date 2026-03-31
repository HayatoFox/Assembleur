# Exercice A - question d

## Objectif

La question A.d du TP demande de creer un nouveau projet en assembleur qui realise un appel a `MessageBox`.

Contraintes respectees dans ce projet :

- aucun `INVOKE`
- aucune macro ou pseudo-instruction MASM dans le segment de code
- appel de fonction realise uniquement avec `push` puis `call`

Le programme se trouve dans [MessageBox.asm](MessageBox.asm).

## Principe general

Le programme affiche une boite de dialogue Windows en appelant directement l'API `MessageBoxA`, puis termine le processus avec `ExitProcess`.

Le point important de l'exercice est de comprendre comment les arguments sont passes a une fonction en x86 :

- les arguments sont empiles sur la pile
- ils sont pousses de droite a gauche
- l'instruction `call` transfere l'execution a la fonction

## Code du programme

```asm
.386
.model flat,stdcall
option casemap:none

include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\kernel32.inc

includelib c:\masm32\lib\user32.lib
includelib c:\masm32\lib\kernel32.lib

.DATA
messageText db "Bonjour depuis l'assembleur", 0
messageTitle db "Exercice A - question d", 0

.CODE
start:
        push 0
        push offset messageTitle
        push offset messageText
        push 0
        call MessageBoxA

        push 0
        call ExitProcess

end start
```

## Explication ligne par ligne

### En-tete

- `.386` indique que l'on cible le processeur 80386 et ses instructions 32 bits.
- `.model flat,stdcall` indique un modele memoire plat et la convention d'appel `stdcall`.
- `option casemap:none` demande a MASM de respecter la casse des symboles.

### Includes et bibliotheques

- `windows.inc`, `user32.inc`, `kernel32.inc` declarent les constantes et fonctions Windows.
- `user32.lib` permet d'utiliser `MessageBoxA`.
- `kernel32.lib` permet d'utiliser `ExitProcess`.

### Segment de donnees

- `messageText` contient le texte a afficher.
- `messageTitle` contient le titre de la boite de dialogue.
- le `0` final marque la fin de chaque chaine de caracteres.

### Segment de code

Le point d'entree est l'etiquette `start`.

## Appel a MessageBoxA

La fonction Windows utilisee est :

```c
int MessageBoxA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, UINT uType);
```

Ses arguments sont donc :

1. `hWnd` : handle de la fenetre parente
2. `lpText` : adresse du texte a afficher
3. `lpCaption` : adresse du titre
4. `uType` : type de boite de dialogue

En assembleur x86 avec `stdcall`, les arguments sont pousses de droite a gauche.

Le code :

```asm
push 0
push offset messageTitle
push offset messageText
push 0
call MessageBoxA
```

correspond donc a :

```c
MessageBoxA(0, messageText, messageTitle, 0);
```

Interpretation de chaque instruction :

- `push 0` : empile `uType = 0`, ce qui correspond a une boite standard de type `MB_OK`
- `push offset messageTitle` : empile l'adresse du titre
- `push offset messageText` : empile l'adresse du texte
- `push 0` : empile `hWnd = NULL`
- `call MessageBoxA` : saute dans la fonction Windows apres avoir empile l'adresse de retour

## Etat de la pile

Juste avant `call MessageBoxA`, la pile contient les 4 arguments.

Apres l'execution du `call`, l'adresse de retour est ajoutee au sommet de pile.

Vu depuis la fonction appelee, l'organisation est la suivante :

```text
[esp]     = adresse de retour
[esp+4]   = hWnd
[esp+8]   = lpText
[esp+12]  = lpCaption
[esp+16]  = uType
```

Comme `MessageBoxA` suit la convention `stdcall`, c'est la fonction appelee qui nettoie la pile avant de revenir. Il n'y a donc pas besoin d'ecrire `add esp, 16` apres l'appel.

## Fin du programme

La fin du programme est :

```asm
push 0
call ExitProcess
```

Cela signifie :

- `push 0` : code de retour du processus
- `call ExitProcess` : fin propre du programme Windows

## Ce qu'il faut observer dans x64dbg

Pour relier le code au cours et au TP, il faut surtout observer la pile.

Etapes conseillees :

1. lancer `MessageBox.exe`
2. s'arreter sur l'instruction `call MessageBoxA`
3. regarder la pile juste avant l'appel
4. executer le `call`
5. verifier qu'une adresse de retour a ete ajoutee sur la pile
6. laisser la fonction se terminer
7. verifier que la pile a ete restauree automatiquement

## Pourquoi cette solution repond bien a la question

Cette solution repond exactement a la question A.d car :

- elle cree un nouveau projet assembleur
- elle realise un appel a `MessageBox`
- elle montre explicitement le passage des parametres par la pile
- elle n'utilise pas `INVOKE`
- elle n'utilise pas de macro MASM dans le code

## Compilation

Le fichier [make.bat](make.bat) permet de compiler et lier le programme :

```bat
@echo off
c:\masm32\bin\ml /c /Zd /coff MessageBox.asm
c:\masm32\bin\Link /SUBSYSTEM:WINDOWS MessageBox.obj
pause
```

Le choix `/SUBSYSTEM:WINDOWS` est logique ici car le programme ouvre une boite de dialogue Windows et n'a pas besoin de console.
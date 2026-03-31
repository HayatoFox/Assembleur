# TP Assembleur x86 - Realisation A a D

Ce depot contient une proposition complete des exercices A, B, C et D.
La partie E est volontairement laissee de cote comme demande.

## A - Appel de fonctions

- A.d code dans [exercice_A/MessageBox.asm](exercice_A/MessageBox.asm)
- explication detaillee dans [exercice_A/README.md](exercice_A/README.md)

## B - Modes d'adressage

- B.a routine de mise en majuscule dans [exercice_B/B_a/B_a.asm](exercice_B/B_a/B_a.asm)
- B.b sous-programme appele via la pile dans [exercice_B/B_b/B_b.asm](exercice_B/B_b/B_b.asm)
- B.c sous-programme de comptage de longueur dans [exercice_B/B_c/B_c.asm](exercice_B/B_c/B_c.asm)

## C - Variables locales

- C.a + C.b fonction `myst` et verification dans [exercice_C/C_a_b/C_a_b.asm](exercice_C/C_a_b/C_a_b.asm)
- C.c comptage de a, b, c avec compteurs locaux dans [exercice_C/C_c/C_c.asm](exercice_C/C_c/C_c.asm)

## D - Un peu de calcul

- D.a affichage des diviseurs d'un entier positif dans [exercice_D/D_a/D_a.asm](exercice_D/D_a/D_a.asm)
- D.b factorielle recursive dans [exercice_D/D_b/D_b.asm](exercice_D/D_b/D_b.asm)

## Compilation

Chaque sous-dossier contient son `make.bat`.

Exemple :

1. Ouvrir un terminal dans un dossier d'exercice, par exemple `exercice_D/D_b`
2. Lancer `make.bat`
3. Executer l'`exe` genere

Tous les codes respectent les contraintes demandees :

- pas de `INVOKE` dans ces exercices
- pas de `.IF`, `.WHILE`, `.FOR`, `PROC`, `LOCAL`
- appels explicites avec `push` et `call`
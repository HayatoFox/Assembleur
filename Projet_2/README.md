# DIR /S — Clone récursif en Assembleur x86 (MASM)

## Description du projet

Ce projet implémente un clone de la commande Windows `DIR /S` en assembleur x86,
permettant de lister récursivement tous les fichiers et répertoires à partir d'un
point d'entrée spécifié par l'utilisateur.

Le projet comprend **deux versions** :

| Version | Fichier | Description |
|---------|---------|-------------|
| **CLI** | `dir_recursive_cli.asm` | Version ligne de commande (console) |
| **GUI** | `dir_recursive_gui.asm` | Version interface graphique Win32 |

---

## Architecture technique

### Version Console (`dir_recursive_cli.asm`)

```
main
 ├── Affichage bannière
 ├── ReadConsoleA → saisie du répertoire
 ├── TrimCRLF → nettoyage de l'entrée
 └── ListDirectory (RÉCURSIF)
      ├── FindFirstFileA / FindNextFileA
      ├── Filtrage "." et ".."
      ├── Si fichier → affichage date + taille + nom
      ├── Si répertoire → affichage + appel récursif
      └── FindClose
```

**Fonctions clés :**

| Procédure | Rôle |
|-----------|------|
| `PrintStr` | Affiche une chaîne ASCIIZ sur la console via `WriteConsoleA` |
| `TrimCRLF` | Supprime CR/LF/espaces en fin de chaîne |
| `FormatFileTime` | Convertit `FILETIME` → chaîne `DD/MM/YYYY HH:MM` |
| `ListDirectory` | Parcours récursif avec `FindFirstFileA`/`FindNextFileA` |

### Version GUI (`dir_recursive_gui.asm`)

```
WinMain
 ├── InitCommonControlsEx (ListView + StatusBar)
 ├── RegisterClassExA + CreateWindowExA
 └── Boucle de messages (GetMessageA)

WndProc
 ├── WM_CREATE → création des contrôles
 │    ├── EDIT       (champ de saisie du chemin)
 │    ├── BUTTON ×3  (Parcourir / Lister / Effacer)
 │    ├── ListView   (affichage en colonnes)
 │    └── StatusBar  (compteurs)
 ├── WM_SIZE → redimensionnement dynamique
 ├── WM_COMMAND
 │    ├── BTN_LIST   → DoScan → ScanDirectory (récursif)
 │    ├── BTN_BROWSE → SHBrowseForFolderA
 │    └── BTN_CLEAR  → vider le ListView
 └── WM_DESTROY → PostQuitMessage
```

**Contrôles de l'interface :**

| Contrôle | Type | Fonction |
|----------|------|----------|
| Champ de saisie | `EDIT` | Entrer/afficher le chemin de départ |
| Parcourir... | `BUTTON` | Ouvre le dialogue de sélection de dossier |
| Lister | `BUTTON` | Lance le scan récursif |
| Effacer | `BUTTON` | Vide le ListView et les compteurs |
| ListView | `SysListView32` | Affiche les résultats (5 colonnes, scroll) |
| Barre de statut | `StatusBar` | Affiche le total fichiers/répertoires |

**Colonnes du ListView :**

1. **Type** — `Fichier` ou `<REP>`
2. **Nom** — Nom du fichier/répertoire
3. **Taille** — Taille en octets (vide pour les répertoires)
4. **Date** — Date de dernière modification
5. **Chemin** — Chemin complet

---

## Prérequis

### Option A : MASM32 SDK (recommandé)
- Télécharger depuis [masm32.com](http://www.masm32.com/)
- Ajouter `C:\masm32\bin` au PATH système

### Option B : Visual Studio Build Tools
- Installer « Développement Desktop en C++ »
- Utiliser le « Developer Command Prompt »

---

## Compilation

### Méthode rapide (script batch)
```batch
build.bat
```

### Méthode manuelle

**Version Console :**
```batch
ml /c /coff dir_recursive_cli.asm
link /SUBSYSTEM:CONSOLE dir_recursive_cli.obj kernel32.lib user32.lib
```

**Version GUI :**
```batch
ml /c /coff dir_recursive_gui.asm
link /SUBSYSTEM:WINDOWS dir_recursive_gui.obj kernel32.lib user32.lib gdi32.lib comctl32.lib comdlg32.lib shell32.lib ole32.lib
```

---

## Utilisation

### Version Console
```
dir_recursive_cli.exe
```
L'application demande le répertoire de départ, puis affiche le listing
récursif dans la console avec date, taille et nom de chaque élément.

### Version GUI
```
dir_recursive_gui.exe
```
1. Entrez un chemin dans le champ de saisie (ex: `C:\Users`)
2. Ou cliquez **Parcourir...** pour sélectionner un dossier
3. Cliquez **Lister** pour lancer le scan récursif
4. Les résultats apparaissent dans le ListView (scrollable)
5. La barre de statut affiche le nombre total de fichiers et répertoires

---

## APIs Windows utilisées

| API | Usage |
|-----|-------|
| `FindFirstFileA` / `FindNextFileA` | Énumération des fichiers |
| `FileTimeToSystemTime` | Conversion des dates |
| `WriteConsoleA` / `ReadConsoleA` | E/S console (version CLI) |
| `CreateWindowExA` | Création de fenêtre et contrôles (GUI) |
| `SendMessageA` + `LVM_*` | Manipulation du ListView (GUI) |
| `SHBrowseForFolderA` | Dialogue de sélection de dossier (GUI) |
| `InitCommonControlsEx` | Activation des contrôles communs (GUI) |

---

## Structure des fichiers

```
projet/
├── dir_recursive_cli.asm    # Source - version console
├── dir_recursive_gui.asm    # Source - version GUI
├── build.bat                # Script de compilation
└── README.md                # Ce fichier
```

---

## Détails d'implémentation

### Récursion
La récursion utilise des variables locales sur la pile (`LOCAL`) pour chaque
niveau d'appel, ce qui permet de gérer des arborescences profondes sans
conflit de données. La pile x86 standard supporte facilement des centaines
de niveaux de profondeur.

### Gestion mémoire
Aucune allocation dynamique (`HeapAlloc`) n'est utilisée. Toutes les données
sont soit statiques (.data/.data?), soit locales sur la pile. Cela simplifie
le code et évite les fuites mémoire.

### Performance (GUI)
La barre de statut est mise à jour tous les 50 fichiers pour éviter un
ralentissement dû aux appels trop fréquents à `SendMessageA`.
L'option `LVS_EX_DOUBLEBUFFER` est activée sur le ListView pour réduire
le scintillement lors de l'ajout massif d'éléments.

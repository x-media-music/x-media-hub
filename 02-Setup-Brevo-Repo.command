#!/bin/bash
#
# Phase B.1 — Brevo-Projekt in privates Git-Repo überführen
# =========================================================
#
# Was dieses Skript macht:
#  1) Prüft, ob ~/Documents/Claude/Projects/BREVO-Account/ existiert
#  2) Erstellt .gitignore (schützt API-Keys, Workflow-JSONs mit Keys)
#  3) Initialisiert Git-Repo + erster Commit
#  4) Erstellt privates GitHub-Repo x-media-music/xmedia-brevo
#  5) Pusht
#
# Live-Brevo-Account ist NICHT betroffen — wir versionieren nur die lokalen Dateien.
# Workflow-JSONs mit hardcoded Service-Role-Keys werden BEWUSST ausgeschlossen
# (Backup erfolgt im separaten n8n-workflows-Repo, sauber exportiert).
#
# Doppelklick auf diese Datei zum Ausführen.
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

BREVO_DIR="$HOME/Documents/Claude/Projects/BREVO-Account"

clear
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Phase B.1 — Brevo-Projekt versionieren${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# ───────────────────────────────────────────────────────────────
# Voraussetzungen
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[0/5] Voraussetzungen prüfen...${NC}"

if [ ! -d "$BREVO_DIR" ]; then
  echo -e "${RED}✗ Ordner nicht gefunden: $BREVO_DIR${NC}"
  read -p "Drücke Return zum Beenden..." dummy
  exit 1
fi
echo -e "${GREEN}✓ Brevo-Ordner gefunden${NC}"

if ! command -v gh >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠ GitHub CLI (gh) nicht gefunden.${NC}"
  echo "  Du kannst gh installieren (brew install gh) oder das Repo manuell auf"
  echo "  https://github.com/new anlegen und dann hier weitermachen."
  echo
  read -p "Repo schon manuell angelegt? [j/n] " manual
  if [[ ! "$manual" =~ ^[Jj] ]]; then
    echo "Abbruch. Lege das Repo unter https://github.com/new an"
    echo "(Name: xmedia-brevo, Owner: x-media-music, Visibility: Private,"
    echo " KEINE README/License/Gitignore-Initialisierung)."
    read -p "Drücke Return zum Beenden..." dummy
    exit 1
  fi
  GH_AVAILABLE=0
else
  if ! gh auth status >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ gh ist installiert, aber nicht angemeldet.${NC}"
    echo "  Führe in einem Terminal aus: gh auth login"
    read -p "Drücke Return zum Beenden..." dummy
    exit 1
  fi
  echo -e "${GREEN}✓ GitHub CLI angemeldet${NC}"
  GH_AVAILABLE=1
fi
echo

# ───────────────────────────────────────────────────────────────
# Schritt 1: .gitignore anlegen
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[1/5] .gitignore anlegen (schützt Credentials)...${NC}"
cd "$BREVO_DIR"

if [ ! -f .gitignore ]; then
  cat > .gitignore <<'EOF'
# ═══════════════════════════════════════════════════════════════
# Sensible Daten — NIEMALS in Git
# ═══════════════════════════════════════════════════════════════

# Environment-Dateien
*.env
.env*
.envrc

# Credentials, Tokens, Keys
API-KEYS*
api_keys*
*.token
*.secret
*.credentials
credentials.json

# Skripte/Dateien mit hardcoded Credentials
# (sollten irgendwann refactored werden, sodass sie Keys aus ENV lesen)
_import_veranstalter.py

# Workflow-JSONs mit hardcoded Service Role Keys
# Backup dieser Workflows erfolgt im separaten n8n-workflows-Repo
# (dort sauber exportiert, ggf. Keys durch Placeholder ersetzt)
workflow_brevo_*.json

# ═══════════════════════════════════════════════════════════════
# Generelles
# ═══════════════════════════════════════════════════════════════

# macOS
.DS_Store

# Python
__pycache__/
*.pyc
*.pyo
*.egg-info/
*.egg
.venv/
venv/
.pytest_cache/

# Node (falls jemals)
node_modules/

# IDE
.vscode/
.idea/
*.swp
*~

# Build-Output / Logs
dist/
build/
*.log
EOF
  echo -e "${GREEN}✓ .gitignore erstellt${NC}"
else
  echo -e "${YELLOW}ℹ .gitignore existiert bereits — überspringe${NC}"
fi

# README anlegen, wenn noch keiner da ist
if [ ! -f README.md ]; then
  cat > README.md <<'EOF'
# xmedia-brevo

Lokale Werkzeuge und Skripte rund um den Brevo-Account von x-media music GmbH.

## Inhalt

- Python-Skripte für Import, Repair, Diagnose von Brevo-Kontakten
- Newsletter-HTMLs für Kampagnen
- (Workflow-JSONs liegen im separaten `xmedia-n8n-workflows`-Repo)

## Setup

Skripte lesen API-Keys aus `~/Library/CloudStorage/Dropbox/x-media MUSIC GmbH/CRM/API-KEYS.md`.
Diese Datei ist via `.gitignore` ausgeschlossen.

## Skill

Siehe `xmedia-brevo` Skill in der Cowork-/Claude-Code-Umgebung — komplette
Referenz zu Listen, Attributen, Sync-Workflows, Troubleshooting.

## Status

Produktiv. Synchronisiert Veranstalter-Daten aus CRM-Supabase nach Brevo
über zwei n8n-Workflows (siehe Skill `xmedia-brevo` → `references/n8n-sync-workflows.md`).
EOF
  echo -e "${GREEN}✓ README.md erstellt${NC}"
else
  echo -e "${YELLOW}ℹ README.md existiert bereits — überspringe${NC}"
fi
echo

# ───────────────────────────────────────────────────────────────
# Schritt 2: Git-Repo initialisieren
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[2/5] Git-Repo initialisieren...${NC}"

if [ -d .git ]; then
  echo -e "${YELLOW}ℹ Git-Repo existiert bereits — überspringe init${NC}"
else
  git init -q
  git branch -M main
  echo -e "${GREEN}✓ git init + branch main${NC}"
fi
echo

# ───────────────────────────────────────────────────────────────
# Schritt 3: Was wird ein-, was ausgeschlossen?
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[3/5] Vorschau: was kommt ins Repo?${NC}"
echo
echo -e "${BLUE}Dateien, die committed werden:${NC}"
git -c safe.directory='*' status --short --ignored=no 2>/dev/null | \
  grep -E "^\?\?" | sed 's/^?? /  + /' | head -30
echo
echo -e "${YELLOW}Dateien, die IGNORIERT werden (bleiben lokal):${NC}"
git -c safe.directory='*' status --ignored --short 2>/dev/null | \
  grep -E "^!!" | sed 's/^!! /  ✗ /' | head -10
echo

read -p "Sieht das richtig aus? Weiter mit Commit + Push? [j/n] " ok
if [[ ! "$ok" =~ ^[Jj] ]]; then
  echo "Abbruch. Du kannst die .gitignore manuell anpassen und dieses Skript erneut starten."
  read -p "Drücke Return..." dummy
  exit 0
fi
echo

# ───────────────────────────────────────────────────────────────
# Schritt 4: Erster Commit
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[4/5] Initial Commit...${NC}"

git add .
if git -c user.email="info@xmedia24.com" -c user.name="Dirk Wöhrle" \
       commit -m "Initial: Brevo-Projekt versionieren" -q; then
  echo -e "${GREEN}✓ Commit erstellt${NC}"
else
  echo -e "${YELLOW}ℹ Nichts zu committen (vielleicht schon committed?)${NC}"
fi
echo

# ───────────────────────────────────────────────────────────────
# Schritt 5: GitHub-Repo + Push
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[5/5] GitHub-Repo anlegen + pushen...${NC}"

# Prüfen, ob Remote schon existiert
if git remote get-url origin >/dev/null 2>&1; then
  echo -e "${YELLOW}ℹ Remote 'origin' existiert bereits: $(git remote get-url origin)${NC}"
  echo "  Push wird mit bestehendem Remote versucht."
else
  if [ "$GH_AVAILABLE" = "1" ]; then
    echo "  Erstelle privates GitHub-Repo x-media-music/xmedia-brevo..."
    gh repo create x-media-music/xmedia-brevo --private --source=. --remote=origin --description="Brevo-Tools und Skripte für x-media music"
    echo -e "${GREEN}✓ Remote 'origin' eingerichtet${NC}"
  else
    echo "  Bitte trage die Remote-URL manuell ein:"
    read -p "  URL des manuell erstellten Repos: " repo_url
    git remote add origin "$repo_url"
  fi
fi

if git push -u origin main; then
  echo -e "${GREEN}✓ Push erfolgreich${NC}"
else
  echo -e "${RED}✗ Push fehlgeschlagen — bitte Fehler oben prüfen${NC}"
fi
echo

# ───────────────────────────────────────────────────────────────
# Zusammenfassung
# ───────────────────────────────────────────────────────────────
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Phase B.1 abgeschlossen${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "  Repo:   https://github.com/x-media-music/xmedia-brevo"
echo "  Lokal:  $BREVO_DIR"
echo
echo "  Auf GitHub prüfen: die ignorierten Dateien dürfen NICHT erscheinen!"
echo
echo "  Als nächstes:  03-Setup-n8n-Workflows-Backup.command  (siehe x-media-Ordner)"
echo
read -p "Drücke Return zum Beenden..." dummy

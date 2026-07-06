#!/bin/bash
#
# Phase B.2 — Push-Nachzügler
# ===========================
#
# Macht den letzten Schritt des n8n-Workflow-Backups, der beim Hauptskript
# nicht durchlief: privates GitHub-Repo erstellen + push.
#
# Lokale Vorbereitung (Sanitisieren, Git-Init, Commit) ist schon erledigt.
# Hier wird nur noch hochgeladen.
#
# Doppelklick zum Ausführen.
#

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

REPO_DIR="$HOME/Documents/Claude/Projects/x-media/n8n-workflows"

clear
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  n8n-Workflows → GitHub pushen${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

if [ ! -d "$REPO_DIR/.git" ]; then
  echo -e "${RED}✗ Kein Git-Repo unter $REPO_DIR${NC}"
  echo "  Erst das Haupt-Skript 03-Setup-n8n-Workflows-Backup.command durchlaufen lassen."
  read -p "Return zum Beenden..." dummy; exit 1
fi

cd "$REPO_DIR"

# Wegen Cowork-VM-Permissions: stelle sicher, dass git die Datei sieht
chmod -R u+w .git/ 2>/dev/null || true

echo -e "${BOLD}[1/2] GitHub-Repo anlegen + Remote setzen...${NC}"

if git remote get-url origin >/dev/null 2>&1; then
  echo -e "${YELLOW}ℹ Remote 'origin' existiert bereits${NC}"
  echo "    $(git remote get-url origin)"
else
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh repo create x-media-music/xmedia-n8n-workflows \
      --private --source=. --remote=origin \
      --description="Backup aller produktiven n8n-Workflows von x-media music"
    echo -e "${GREEN}✓ Repo erstellt + Remote eingerichtet${NC}"
  else
    echo -e "${YELLOW}ℹ GitHub CLI nicht angemeldet${NC}"
    echo "  Lege das Repo manuell unter https://github.com/new an:"
    echo "    Owner:      x-media-music"
    echo "    Name:       xmedia-n8n-workflows"
    echo "    Visibility: Private"
    echo "    KEINE Initialisierung mit README/Gitignore/License!"
    read -p "  Fertig? Drück Return..." dummy
    git remote add origin https://github.com/x-media-music/xmedia-n8n-workflows.git
  fi
fi
echo

echo -e "${BOLD}[2/2] Pushen...${NC}"
if git push -u origin main; then
  echo -e "${GREEN}✓ Push erfolgreich${NC}"
else
  echo -e "${RED}✗ Push fehlgeschlagen — bitte Fehler oben prüfen${NC}"
  read -p "Return..." dummy; exit 1
fi

echo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ n8n-Workflows-Backup ist auf GitHub${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "  Repo:   https://github.com/x-media-music/xmedia-n8n-workflows"
echo "  Lokal:  $REPO_DIR"
echo
echo "  Auf GitHub prüfen: NUR exports-sanitized/ + README + .gitignore"
echo "  sollten zu sehen sein. Originale exports/ darf NICHT erscheinen."
echo
read -p "Drücke Return zum Beenden..." dummy

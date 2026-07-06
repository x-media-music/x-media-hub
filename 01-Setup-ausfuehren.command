#!/bin/bash
#
# x-media Setup — One-Click-Skript für die Phase-A-Migration
# ==========================================================
#
# Was dieses Skript macht:
#  1) Prüft, ob git und GitHub-Authentifizierung verfügbar sind
#  2) Klont das CRM-Repo nach ~/Documents/Claude/Projects/x-media/crm/
#  3) Klont das Website-Repo nach ~/Documents/Claude/Projects/x-media/website-xmedia24/
#  4) Legt einen Symlink für API-KEYS.md ins CRM
#  5) Macht einen ungefährlichen Mini-Test-Commit (KEIN Deploy!)
#  6) Zeigt eine Zusammenfassung
#
# Live-Systeme (CRM auf Hostinger, n8n auf VPS) bleiben dabei UNBERÜHRT.
# Du kannst dieses Skript jederzeit abbrechen mit Strg+C.
#
# AUSFÜHREN: Doppelklick auf diese Datei im Finder.
# (Falls Sicherheitswarnung kommt: Rechtsklick → Öffnen → Bestätigen.)
#

set -e  # bei jedem Fehler sofort abbrechen

# Farben für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'  # Reset

ROOT="$HOME/Documents/Claude/Projects/x-media"
DROPBOX_KEYS="$HOME/Library/CloudStorage/Dropbox/x-media MUSIC GmbH/CRM/API-KEYS.md"

clear
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  x-media — Phase-A-Setup (Repos klonen)${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "Wir klonen jetzt zwei Repos aus GitHub in den Ordner:"
echo -e "  ${BLUE}$ROOT${NC}"
echo
echo -e "Das Live-CRM und n8n bleiben dabei ${BOLD}vollkommen unberührt${NC}."
echo

# ───────────────────────────────────────────────────────────────
# Schritt 0: Voraussetzungen prüfen
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[0/5] Voraussetzungen prüfen...${NC}"

if ! command -v git >/dev/null 2>&1; then
  echo -e "${RED}✗ git ist nicht installiert.${NC}"
  echo "  Tippe in einem normalen Terminal: xcode-select --install"
  echo "  Drücke dann Return im Popup. Wenn fertig, dieses Skript erneut starten."
  read -p "Drücke Return zum Beenden..." dummy
  exit 1
fi
echo -e "${GREEN}✓ git ist installiert${NC} ($(git --version))"

# Prüfen, ob GitHub via gh oder via cached HTTPS-Credentials erreichbar ist
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo -e "${GREEN}✓ GitHub CLI (gh) ist angemeldet${NC}"
  AUTH_METHOD="gh"
else
  echo -e "${YELLOW}ℹ GitHub CLI nicht oder nicht angemeldet — versuche per HTTPS${NC}"
  AUTH_METHOD="https"
fi

if [ ! -f "$DROPBOX_KEYS" ]; then
  echo -e "${YELLOW}⚠ API-KEYS.md in Dropbox nicht gefunden unter:${NC}"
  echo "  $DROPBOX_KEYS"
  echo "  (Symlink-Schritt wird übersprungen — kann später nachgeholt werden.)"
  echo
fi

if [ ! -d "$ROOT" ]; then
  echo -e "${RED}✗ Zielordner existiert nicht: $ROOT${NC}"
  echo "  Du hast die Vorbereitung übersprungen. Starte zuerst Claude und lass den Wurzelordner anlegen."
  read -p "Drücke Return zum Beenden..." dummy
  exit 1
fi
echo -e "${GREEN}✓ Wurzelordner gefunden${NC}"
echo

# ───────────────────────────────────────────────────────────────
# Schritt 1: CRM klonen
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[1/5] CRM-Repo klonen...${NC}"
cd "$ROOT"

if [ -d "$ROOT/crm" ]; then
  echo -e "${YELLOW}ℹ Ordner ./crm existiert bereits — überspringe Klone${NC}"
else
  if [ "$AUTH_METHOD" = "gh" ]; then
    gh repo clone x-media-music/xmedia-crm crm
  else
    git clone https://github.com/x-media-music/xmedia-crm.git crm
  fi
  echo -e "${GREEN}✓ CRM geklont nach ./crm/${NC}"
fi
echo

# ───────────────────────────────────────────────────────────────
# Schritt 2: Website klonen
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[2/5] Website-Repo klonen...${NC}"
cd "$ROOT"

if [ -d "$ROOT/website-xmedia24" ]; then
  echo -e "${YELLOW}ℹ Ordner ./website-xmedia24 existiert bereits — überspringe Klone${NC}"
else
  if [ "$AUTH_METHOD" = "gh" ]; then
    gh repo clone x-media-music/xmedia24-website website-xmedia24
  else
    git clone https://github.com/x-media-music/xmedia24-website.git website-xmedia24
  fi
  echo -e "${GREEN}✓ Website geklont nach ./website-xmedia24/${NC}"
fi
echo

# ───────────────────────────────────────────────────────────────
# Schritt 3: API-KEYS.md Symlink
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[3/5] API-KEYS Symlink ins CRM...${NC}"

if [ -f "$DROPBOX_KEYS" ]; then
  if [ -L "$ROOT/crm/API-KEYS.md" ]; then
    echo -e "${YELLOW}ℹ Symlink existiert bereits${NC}"
  elif [ -f "$ROOT/crm/API-KEYS.md" ]; then
    echo -e "${YELLOW}⚠ Echte Datei API-KEYS.md im crm-Ordner gefunden (kein Symlink) — überspringe${NC}"
  else
    ln -s "$DROPBOX_KEYS" "$ROOT/crm/API-KEYS.md"
    echo -e "${GREEN}✓ Symlink gesetzt${NC}"
  fi
else
  echo -e "${YELLOW}ℹ Quelldatei in Dropbox nicht gefunden — überspringe${NC}"
fi
echo

# ───────────────────────────────────────────────────────────────
# Schritt 4: Mini-Test-Commit (KEIN Deploy)
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[4/5] Mini-Test (Kommentar in crm-source.html committen — KEIN Deploy)...${NC}"
cd "$ROOT/crm"

if [ ! -f crm-source.html ]; then
  echo -e "${YELLOW}ℹ crm-source.html nicht im Repo gefunden — überspringe Mini-Test${NC}"
else
  # Schon getestet? Dann nicht doppelt
  if grep -q "Phase-A-Setup Mini-Test" crm-source.html 2>/dev/null; then
    echo -e "${YELLOW}ℹ Test-Kommentar ist schon drin — überspringe${NC}"
  else
    DATESTAMP=$(date '+%Y-%m-%d %H:%M')
    echo "" >> crm-source.html
    echo "<!-- Phase-A-Setup Mini-Test $DATESTAMP — geklonter Pfad funktioniert -->" >> crm-source.html
    git add crm-source.html
    git -c user.email="info@xmedia24.com" -c user.name="Dirk Wöhrle" \
        commit -m "test: Phase-A Mini-Test ($DATESTAMP) — kein Deploy" >/dev/null
    echo -e "${GREEN}✓ Test-Commit erstellt (noch nicht gepusht)${NC}"
    echo
    echo -e "  Soll ich den Test-Commit nach GitHub pushen?"
    echo -e "  (Pusht NUR nach GitHub, deployt NICHT auf Hostinger.)"
    read -p "  Push? [j/n] " antwort
    if [[ "$antwort" =~ ^[JjYy] ]]; then
      git push origin main
      echo -e "${GREEN}✓ Push erfolgreich${NC}"
    else
      echo -e "${YELLOW}ℹ Push übersprungen. Mit 'git push' im Terminal später nachholbar.${NC}"
    fi
  fi
fi
echo

# ───────────────────────────────────────────────────────────────
# Schritt 5: Zusammenfassung
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[5/5] Zusammenfassung${NC}"
echo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Setup abgeschlossen!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo -e "Neue Ordnerstruktur unter ${BLUE}$ROOT${NC}:"
echo
ls -la "$ROOT" | grep -v "^total" | awk '{print "  " $0}'
echo
echo -e "${BOLD}Was du jetzt tun kannst:${NC}"
echo "  • In Claude (Cowork/Code) den Ordner öffnen — er hat sofort den vollen Überblick"
echo "  • In VS Code öffnen: code $ROOT"
echo "  • Auf GitHub prüfen: https://github.com/x-media-music/xmedia-crm/commits"
echo
echo -e "${BOLD}Was du NICHT machen sollst:${NC}"
echo "  • deploy-hostinger.js ausführen (das Live-CRM ist noch nicht dran)"
echo
echo -e "Druck Return zum Beenden..."
read dummy

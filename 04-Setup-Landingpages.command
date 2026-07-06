#!/bin/bash
#
# Phase B.3 — Landingpages + gsc-mcp ins x-media-Setup übernehmen
# ===============================================================
#
# Was dieses Skript macht:
#  1) Konzept-Doku aus LANDINGPAGE-PROJEKT/ → x-media/docs/landingpages/
#  2) oktoberfestbands24.de → website-oktoberfestbands24/  + Repo + Push
#  3) partybands24.de → website-partybands24/  + Repo + Push
#  4) gsc-mcp → tools/gsc-mcp/  + Repo + Push
#  5) STILLGELEGT.md im Dropbox-Quellordner anlegen
#
# Live-Domains (oktoberfestbands24.de, partybands24.de) sind dabei UNBERÜHRT.
# Dropbox-Quellen werden NUR KOPIERT, nicht verschoben.
# Sensible Dateien (.env.local, credentials.json) werden per .gitignore ausgeschlossen.
#
# Doppelklick zum Ausführen.
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ROOT="$HOME/Documents/Claude/Projects/x-media"
SRC_DROPBOX="$HOME/Library/CloudStorage/Dropbox/x-media MUSIC GmbH/CRM/LANDINGPAGE-PROJEKT"

clear
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Phase B.3 — Landingpages versionieren${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "Quelle:  $SRC_DROPBOX"
echo "Ziel:    $ROOT"
echo
echo "Live-Domains bleiben unberührt — wir versionieren nur den lokalen Code."
echo

# ───────────────────────────────────────────────────────────────
# Voraussetzungen
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[0/6] Voraussetzungen prüfen...${NC}"

if [ ! -d "$SRC_DROPBOX" ]; then
  echo -e "${RED}✗ Quellordner nicht gefunden: $SRC_DROPBOX${NC}"
  read -p "Return zum Beenden..." dummy; exit 1
fi
echo -e "${GREEN}✓ Dropbox-Quelle gefunden${NC}"

if [ ! -d "$ROOT" ]; then
  echo -e "${RED}✗ Wurzelordner nicht gefunden: $ROOT${NC}"
  read -p "Return..." dummy; exit 1
fi
echo -e "${GREEN}✓ x-media-Wurzelordner OK${NC}"

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  echo -e "${RED}✗ GitHub CLI (gh) nicht angemeldet${NC}"
  echo "  Im Terminal: gh auth login"
  read -p "Return..." dummy; exit 1
fi
echo -e "${GREEN}✓ GitHub CLI angemeldet${NC}"

if ! command -v rsync >/dev/null 2>&1; then
  echo -e "${RED}✗ rsync fehlt${NC}"
  read -p "Return..." dummy; exit 1
fi
echo -e "${GREEN}✓ rsync vorhanden${NC}"
echo

# ───────────────────────────────────────────────────────────────
# Helper: Repo aufsetzen + push (idempotent)
# ───────────────────────────────────────────────────────────────
setup_repo() {
  local SOURCE_DIR="$1"
  local TARGET_DIR="$2"
  local REPO_NAME="$3"
  local DESCRIPTION="$4"
  local TYPE="$5"   # nextjs | mcp

  if [ -d "$TARGET_DIR/.git" ]; then
    echo -e "  ${YELLOW}ℹ $TARGET_DIR ist schon Repo — überspringe${NC}"
    return 0
  fi

  if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "  ${RED}✗ Quelle nicht gefunden: $SOURCE_DIR${NC}"
    return 1
  fi

  # Kopieren (ohne große/uninteressante Verzeichnisse)
  echo "  Kopiere $(basename "$SOURCE_DIR") → $(basename "$TARGET_DIR")..."
  mkdir -p "$TARGET_DIR"
  rsync -a \
    --exclude='node_modules/' \
    --exclude='.next/' \
    --exclude='dist/' \
    --exclude='build/' \
    --exclude='__pycache__/' \
    --exclude='.venv/' \
    --exclude='*.log' \
    --exclude='.DS_Store' \
    "$SOURCE_DIR/" "$TARGET_DIR/"

  # .gitignore je nach Typ
  if [ "$TYPE" = "nextjs" ]; then
    cat > "$TARGET_DIR/.gitignore" <<'EOF'
# Dependencies
node_modules/

# Build-Output
.next/
out/
dist/
build/

# Environment / Secrets
.env.local
.env.development.local
.env.production.local
.env.test.local
*.env

# Logs
npm-debug.log*
yarn-debug.log*
*.log

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
EOF
  elif [ "$TYPE" = "mcp" ]; then
    cat > "$TARGET_DIR/.gitignore" <<'EOF'
# Google OAuth Credentials / Tokens — NIEMALS in Git
credentials.json
token.json
*.token
*.secret

# Environment
.env
.env*

# Python
__pycache__/
*.pyc
*.pyo
*.egg-info/
.venv/
venv/
.pytest_cache/

# OS / IDE
.DS_Store
.vscode/
.idea/
EOF
  fi

  cd "$TARGET_DIR"
  git init -q
  git branch -M main 2>/dev/null || git checkout -b main 2>/dev/null || true

  git add .
  if git -c user.email="info@xmedia24.com" -c user.name="Dirk Wöhrle" \
         commit -m "Initial: $REPO_NAME aus Dropbox-Migration" -q 2>/dev/null; then
    echo -e "  ${GREEN}✓ Initial Commit${NC}"
  fi

  # GitHub-Repo anlegen + Push
  if ! git remote get-url origin >/dev/null 2>&1; then
    gh repo create "x-media-music/$REPO_NAME" \
        --private --source=. --remote=origin \
        --description="$DESCRIPTION" >/dev/null
    echo -e "  ${GREEN}✓ GitHub-Repo angelegt: x-media-music/$REPO_NAME${NC}"
  fi
  git push -u origin main 2>&1 | tail -3
  cd "$ROOT"
}

# ───────────────────────────────────────────────────────────────
# Schritt 1: Konzept-Doku → docs/landingpages/
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[1/6] Konzept-Doku nach docs/landingpages/ kopieren...${NC}"
DOCS="$ROOT/docs/landingpages"
mkdir -p "$DOCS/historical"

# Markdown-Dateien direkt aus dem Wurzel des Quellordners
for f in "$SRC_DROPBOX"/*.md; do
  [ -f "$f" ] || continue
  cp "$f" "$DOCS/"
done

# STRATEGIE-Datei aus dem übergeordneten CRM-Ordner
STRATEGIE_FILE="$HOME/Library/CloudStorage/Dropbox/x-media MUSIC GmbH/CRM/STRATEGIE-Landingpages-partybands24-oktoberfestbands24.md"
[ -f "$STRATEGIE_FILE" ] && cp "$STRATEGIE_FILE" "$DOCS/"

# Bilder/
if [ -d "$SRC_DROPBOX/Bilder" ]; then
  rsync -a "$SRC_DROPBOX/Bilder/" "$DOCS/Bilder/"
  echo -e "  ${GREEN}✓ Bilder kopiert${NC}"
fi

# Pilot-HTML in historical/
if [ -f "$SRC_DROPBOX/pilot-muenchen-oktoberfestbands24.html" ]; then
  cp "$SRC_DROPBOX/pilot-muenchen-oktoberfestbands24.html" "$DOCS/historical/"
fi

# README für docs/landingpages/
if [ ! -f "$DOCS/README.md" ]; then
  cat > "$DOCS/README.md" <<'EOF'
# Landingpages — Konzept & Strategie

Dieser Ordner enthält die projektübergreifende Strategie- und Konzept-Doku für die zwei Landingpages **oktoberfestbands24.de** und **partybands24.de**.

Die eigentlichen Codebasen liegen in separaten Repos:

- `../../website-oktoberfestbands24/` → GitHub: `x-media-music/oktoberfestbands24`
- `../../website-partybands24/` → GitHub: `x-media-music/partybands24`

## Wichtige Dokumente

- `00-GESAMTPLAN.md` — Master-Projektplan, Phasen, Status
- `01-STATUS-TRACKER.md` — fortlaufende Statusverfolgung
- `02-AGENTEN-UEBERSICHT.md` — Übersicht der involvierten Sub-Agenten
- `03-API-CREDENTIALS.md` — welche API-Zugänge gebraucht werden (keine Keys!)
- `04-SETUP-ANLEITUNG.md` — Setup-Schritte
- `05-KEYWORD-RECHERCHE.md` — Keyword-Strategie + Cluster
- `06-KONKURRENZANALYSE.md` — Wettbewerber-Analyse
- `07-SEITENSTRUKTUR.md` — Silo-Architektur (~31 Seiten/Domain)
- `08-BILDKONZEPT-PARTYBANDS24.md` — Bilder & Visual-Konzept
- `STRATEGIE-Landingpages-...md` — Gesamtstrategie
- `SEO-Strategie-2026.md` — SEO-Strategie 2026
- `SEO-Aktionsplan-konkret.md` — konkrete SEO-To-dos

## Bilder

`Bilder/` enthält die Hero- und Themen-Bilder, die in beiden Landingpages verwendet werden.

## Historisches

`historical/` — alte Pilot-Versionen / aufgehobene Konzepte
EOF
  echo -e "  ${GREEN}✓ README für docs/landingpages/ erstellt${NC}"
fi

DOC_COUNT=$(ls "$DOCS"/*.md 2>/dev/null | wc -l | xargs)
echo -e "  ${GREEN}✓ $DOC_COUNT Markdown-Dokumente + Bilder in docs/landingpages/${NC}"
echo

# ───────────────────────────────────────────────────────────────
# Schritt 2: oktoberfestbands24.de
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[2/6] Setup website-oktoberfestbands24...${NC}"
setup_repo \
  "$SRC_DROPBOX/oktoberfestbands24.de" \
  "$ROOT/website-oktoberfestbands24" \
  "oktoberfestbands24" \
  "Landingpage oktoberfestbands24.de (Next.js + Supabase)" \
  "nextjs"
echo

# ───────────────────────────────────────────────────────────────
# Schritt 3: partybands24.de
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[3/6] Setup website-partybands24...${NC}"
setup_repo \
  "$SRC_DROPBOX/partybands24.de" \
  "$ROOT/website-partybands24" \
  "partybands24" \
  "Landingpage partybands24.de (Next.js + Supabase)" \
  "nextjs"
echo

# ───────────────────────────────────────────────────────────────
# Schritt 4: gsc-mcp
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[4/6] Setup tools/gsc-mcp...${NC}"
mkdir -p "$ROOT/tools"
setup_repo \
  "$SRC_DROPBOX/gsc-mcp" \
  "$ROOT/tools/gsc-mcp" \
  "xmedia-gsc-mcp" \
  "Google Search Console MCP-Server fuer x-media SEO-Monitoring" \
  "mcp"
echo

# ───────────────────────────────────────────────────────────────
# Schritt 5: STILLGELEGT.md in Dropbox-Quellordner
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[5/6] STILLGELEGT.md in Dropbox anlegen...${NC}"

cat > "$SRC_DROPBOX/STILLGELEGT.md" <<EOF
# STILLGELEGT — bitte hier NICHT mehr arbeiten

**Stand:** $(date +%Y-%m-%d)

Die Inhalte dieses Ordners sind in die neue Projektstruktur überführt worden.
Code und Doku werden NUR NOCH dort gepflegt:

## Neue Speicherorte

| Was | Neuer Ort | GitHub |
|---|---|---|
| oktoberfestbands24.de Code | \`~/Documents/Claude/Projects/x-media/website-oktoberfestbands24/\` | https://github.com/x-media-music/oktoberfestbands24 |
| partybands24.de Code | \`~/Documents/Claude/Projects/x-media/website-partybands24/\` | https://github.com/x-media-music/partybands24 |
| Google Search Console MCP | \`~/Documents/Claude/Projects/x-media/tools/gsc-mcp/\` | https://github.com/x-media-music/xmedia-gsc-mcp |
| Strategie + Konzept-Doku | \`~/Documents/Claude/Projects/x-media/docs/landingpages/\` | (nicht versioniert, projektübergreifend) |

## Warum dieser Ordner trotzdem noch da ist

Als reines Backup — falls bei der Migration etwas schiefgegangen ist.
**Bitte hier nichts mehr ändern.** Spätestens 1–2 Monate nach Migration kann
dieser Ordner ins Archiv verschoben oder gelöscht werden.

## Sensible Dateien

Die folgenden Dateien sind im neuen Setup **bewusst nicht** committet:
- \`oktoberfestbands24.de/.env.local\`  — bleibt nur lokal
- \`partybands24.de/.env.local\`        — bleibt nur lokal
- \`gsc-mcp/credentials.json\`          — bleibt nur lokal

Wenn du auf einem neuen Mac arbeitest: diese Dateien aus diesem Backup-Ordner
in die neuen Projektordner kopieren — sie sind nicht via Git verfügbar.
EOF
echo -e "  ${GREEN}✓ STILLGELEGT.md angelegt${NC}"
echo

# ───────────────────────────────────────────────────────────────
# Schritt 6: Zusammenfassung
# ───────────────────────────────────────────────────────────────
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Phase B.3 abgeschlossen${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "  Neue Repos auf GitHub:"
echo "    • https://github.com/x-media-music/oktoberfestbands24"
echo "    • https://github.com/x-media-music/partybands24"
echo "    • https://github.com/x-media-music/xmedia-gsc-mcp"
echo
echo "  Lokal:"
echo "    • $ROOT/website-oktoberfestbands24/"
echo "    • $ROOT/website-partybands24/"
echo "    • $ROOT/tools/gsc-mcp/"
echo "    • $ROOT/docs/landingpages/  (zentrale Konzept-Doku)"
echo
echo "  Dropbox-Quelle: STILLGELEGT.md eingelegt (Code bleibt als Backup)"
echo
echo "  Sensible Dateien sind per .gitignore ausgeschlossen und NICHT auf GitHub:"
echo "    • .env.local (Supabase-Keys in beiden Apps)"
echo "    • credentials.json (Google OAuth)"
echo
echo "  Verifikation: alle Repos auf GitHub öffnen und prüfen, dass dort"
echo "  KEINE der oben genannten sensiblen Dateien zu sehen ist!"
echo
echo "  Als nächstes (B.4): Creative Studio + Buchhaltungsassistent."
echo
read -p "Drücke Return zum Beenden..." dummy

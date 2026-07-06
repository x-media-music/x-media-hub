#!/bin/bash
#
# Phase B.4 — Creative Studio + Buchhaltungsassistent
# ===================================================
#
# Was dieses Skript macht:
#  1) Content Creator/ → creative-studio/  + Repo + Push
#  2) Buchhaltungsassistent/ → buchhaltungsassistent/  + Repo + Push
#  3) STILLGELEGT.md in beiden Dropbox-Quellordnern
#
# Sensible Dateien werden per .gitignore ausgeschlossen:
#   - .env (mit Higgsfield-Keys HF_API_KEY/HF_SECRET im Creative Studio)
#   - Vite-Archiv .env beim Buchhaltungsassistent
#   - große Beispiel-Renders (*.mp4) bleiben lokal
#
# Live-Buchhaltungs-App auf Hostinger und Creative Studio Edge Function
# bleiben dabei UNBERÜHRT — wir versionieren nur den lokalen Code.
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
DROPBOX="$HOME/Library/CloudStorage/Dropbox"
SRC_CC="$DROPBOX/Content Creator"
SRC_BH="$DROPBOX/x-media MUSIC GmbH/Buchhaltungsassistent"

clear
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Phase B.4 — Creative Studio + Buchhaltungsassistent${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# ───────────────────────────────────────────────────────────────
# Voraussetzungen
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[0/4] Voraussetzungen prüfen...${NC}"

for d in "$ROOT" "$SRC_CC" "$SRC_BH"; do
  if [ ! -d "$d" ]; then
    echo -e "${RED}✗ Ordner fehlt: $d${NC}"
    read -p "Return..." dummy; exit 1
  fi
done
echo -e "${GREEN}✓ Quell- und Zielordner OK${NC}"

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  echo -e "${RED}✗ gh nicht angemeldet${NC}"
  read -p "Return..." dummy; exit 1
fi
echo -e "${GREEN}✓ GitHub CLI angemeldet${NC}"
echo

# ───────────────────────────────────────────────────────────────
# Helper: Repo aufsetzen
# ───────────────────────────────────────────────────────────────
setup_repo() {
  local SOURCE_DIR="$1"
  local TARGET_DIR="$2"
  local REPO_NAME="$3"
  local DESCRIPTION="$4"
  local GITIGNORE_CONTENT="$5"
  local README_CONTENT="$6"

  # Schritt 1: Kopieren NUR wenn Zielordner noch nicht existiert
  if [ ! -d "$TARGET_DIR" ]; then
    echo "  Kopiere $(basename "$SOURCE_DIR") → $(basename "$TARGET_DIR")..."
    mkdir -p "$TARGET_DIR"
    rsync -a \
      --exclude='node_modules/' \
      --exclude='__pycache__/' \
      --exclude='.venv/' \
      --exclude='venv/' \
      --exclude='.next/' \
      --exclude='dist/' \
      --exclude='build/' \
      --exclude='*.log' \
      --exclude='.DS_Store' \
      --exclude='*.mp4' \
      --exclude='*.mov' \
      --exclude='creative-studio-deploy.zip' \
      --exclude='ziUxp5vw' \
      "$SOURCE_DIR/" "$TARGET_DIR/"
  else
    echo -e "  ${YELLOW}ℹ $TARGET_DIR existiert — überspringe Kopieren${NC}"
  fi

  # Schritt 2: Eingebettete .git-Ordner entfernen (z.B. von Third-Party-Klonen)
  # Außer dem TOP-LEVEL .git/ — falls schon einer da ist, den behalten.
  echo "  Suche eingebettete .git-Ordner (nested submodule-style)..."
  find "$TARGET_DIR" -mindepth 2 -name ".git" -type d -print -prune 2>/dev/null | while read nested; do
    echo "    entferne: $nested"
    rm -rf "$nested"
    # _UPSTREAM.md Hinweis anlegen, damit klar bleibt, woher der Code kommt
    parent=$(dirname "$nested")
    if [ ! -f "$parent/_UPSTREAM.md" ]; then
      cat > "$parent/_UPSTREAM.md" <<'UPS'
# Upstream-Snapshot

Dieser Ordner enthält einen Snapshot eines externen Repositories.
Der ursprüngliche `.git/`-Ordner wurde beim Import entfernt, damit dieser Ordner
sauber als Teil des übergeordneten Repos versioniert werden kann.

Falls du den Upstream aktualisieren willst: klone das Original separat
(siehe Dokumentation im jeweiligen Unterordner) und merge die Änderungen manuell.
UPS
    fi
  done

  # Schritt 3: .gitignore + README aktualisieren (idempotent)
  printf '%s\n' "$GITIGNORE_CONTENT" > "$TARGET_DIR/.gitignore"
  if [ ! -f "$TARGET_DIR/README.md" ]; then
    printf '%s\n' "$README_CONTENT" > "$TARGET_DIR/README.md"
  fi

  cd "$TARGET_DIR"

  # Schritt 4: git init falls noch kein Repo
  if [ ! -d .git ]; then
    git init -q
    git branch -M main 2>/dev/null || git checkout -b main 2>/dev/null || true
    echo -e "  ${GREEN}✓ git init${NC}"
  fi

  # Schritt 4b: Stale Lockfiles aus abgebrochenen Vorläufen aufräumen
  if [ -d .git ]; then
    LOCKS_GONE=0
    for lock in .git/index.lock .git/HEAD.lock .git/config.lock; do
      if [ -f "$lock" ]; then
        rm -f "$lock" && LOCKS_GONE=$((LOCKS_GONE+1))
      fi
    done
    # Zusätzlich: tief im .git nach allen anderen .lock-Files suchen
    find .git -name "*.lock" -type f -delete 2>/dev/null || true
    if [ "$LOCKS_GONE" -gt 0 ]; then
      echo -e "  ${YELLOW}ℹ $LOCKS_GONE Lockfile(s) aus abgebrochenem Vorlauf entfernt${NC}"
    fi
  fi

  # Schritt 5: Commit falls noch kein HEAD
  if ! git rev-parse HEAD >/dev/null 2>&1; then
    git add .
    if git -c user.email="info@xmedia24.com" -c user.name="Dirk Wöhrle" \
           commit -m "Initial: $REPO_NAME aus Dropbox-Migration" -q; then
      echo -e "  ${GREEN}✓ Initial Commit${NC}"
    else
      echo -e "  ${RED}✗ Commit fehlgeschlagen${NC}"
      cd "$ROOT"
      return 1
    fi
  else
    # Falls Files dazugekommen oder geändert sind: zusätzlichen Commit
    if [ -n "$(git status --porcelain)" ]; then
      git add .
      git -c user.email="info@xmedia24.com" -c user.name="Dirk Wöhrle" \
          commit -m "Update aus Dropbox-Migration" -q || true
      echo -e "  ${GREEN}✓ Folge-Commit${NC}"
    fi
  fi

  # Schritt 6: Remote setzen falls noch nicht
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
# Schritt 1: Creative Studio
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[1/4] Setup creative-studio...${NC}"

CC_GITIGNORE='# Environment / Secrets (Higgsfield, Anthropic Keys)
.env
.env.local
.env.production
.env.development
# Aber Beispiele behalten
!.env.example
!.env.example.*

# Python
__pycache__/
*.pyc
*.pyo
*.egg-info/
.venv/
venv/
.pytest_cache/

# Node
node_modules/

# Build / Deploy / Temp
*.deploy.zip
creative-studio-deploy.zip
ziUxp5vw

# Große Renders / Test-Outputs (bleiben lokal)
04_Ergebnisse/*.mp4
04_Ergebnisse/*.mov
*.mp4
*.mov

# OS / IDE
.DS_Store
.vscode/
.idea/
*.swp'

CC_README='# xmedia-creative-studio

x-media Creative Studio — KI-Content-Creation für Bands, Events, Marketing.

## Bestandteile

- `01_Konzept/` — Konzeptdokumente, Plattform-Vergleich
- `02_MCP-Server/` — MCP-Server (xmedia-creative-mcp + higgsfield_ai_mcp) für Claude Desktop
- `03_Prompt-Bibliothek/` — Prompt-Vorlagen nach Kategorie
- `04_Ergebnisse/` — generierte Test-Bilder/Videos (.mp4/.mov sind via .gitignore lokal-only)
- `05_Creative-Studio/` — Web-App (`index.html`, Single-File-SPA)
- `06_Edge-Functions/` — Supabase Edge Function `creative-proxy`
- `content-creator.skill` — Skill-Paket für Claude

## Tech-Stack

- Web-App: Single-File HTML/React (kein Build)
- MCP-Server: Python (FastMCP)
- Edge Functions: TypeScript (Supabase Edge Runtime)
- Provider: Higgsfield (primär), Krea/fal.ai (vorbereitet)

## Secrets

`.env`-Dateien mit `HF_API_KEY` und `HF_SECRET` sind via `.gitignore` ausgeschlossen.
Vorlagen: siehe `.env.example` in den MCP-Server-Ordnern.

## Skill

Siehe `content-creator` Skill in der Cowork-/Claude-Code-Umgebung — komplette technische Referenz.

## Status

In Entwicklung. Nutzt das Haupt-Supabase-Projekt (vrntqlmrxlbnhetskwjw) mit eigenen Tabellen
(creative_jobs, creative_gallery, creative_settings, creative_categories).'

setup_repo \
  "$SRC_CC" \
  "$ROOT/creative-studio" \
  "xmedia-creative-studio" \
  "x-media Creative Studio - KI-Content-Creation (Web-App, MCP-Server, Edge Functions)" \
  "$CC_GITIGNORE" \
  "$CC_README"
echo

# ───────────────────────────────────────────────────────────────
# Schritt 2: Buchhaltungsassistent
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[2/4] Setup buchhaltungsassistent...${NC}"

BH_GITIGNORE='# Environment / Secrets
.env
.env.local
.env.production
!.env.example

# Node / Build
node_modules/
dist/
build/
.next/

# Backups einzelner Dateien (Originale bleiben in Dropbox)
*.backup-*
index.html.backup-*

# Logs
*.log

# OS / IDE
.DS_Store
.vscode/
.idea/
*.swp'

BH_README='# xmedia-buchhaltungsassistent

KI-Buchhaltungsassistent für x-media music GmbH und x-media event GmbH.

## Status

⏸️ **Pause** — wird in naher Zukunft überarbeitet und reaktiviert.

## Bestandteile

- `live-hostinger/` — Live-Code (Single-File HTML PWA, deployt auf Hostinger)
  - `index.html` — die App
  - `manifest.json` + `sw.js` — PWA
- `edge-functions/` — Supabase Edge Functions (TypeScript)
  - `beleg-klassifizieren.ts`, `beleg-routing.ts`, `beleg-upload.ts`
  - `email-eingang.ts`, `email-fetch.ts`, `email-scan.ts`, `email-confirm.ts`
  - `duplikate-cleanup.ts`, `manual-belege-delete.ts`, `pdf-hash-backfill.ts`
  - `bewirtungsbeleg-pdf/`, `smtp-test.ts`
- `_archiv_25-03-2026_vite-umbau-nie-deployt/` — historisches Vite-Refactor (nie deployt)
- `backups/` — frühere Snapshots
- Doku-Dateien (BH-REFERENZ-AKTUELL.md, FRONTEND-BACKEND-ABGLEICH-LIVE-*)

## Supabase

Eigenes Projekt (NICHT das CRM-Projekt!): `hsvpjtpzsnfdpibdkxut.supabase.co`

Tabellen: `bh_belege`, `bh_bewirtungsbelege`, `bh_regeln`, `bh_protokoll`, `bh_einstellungen`, `bh_benutzer`

## Routing-Logik

- **x-media music GmbH** → DATEV Uploadmail-Adressen (per E-Mail)
- **x-media event GmbH** → Dropbox-Ordner (XE Buchhaltung)

## Skill

Siehe `buchhaltungsassistent` Skill in der Cowork-/Claude-Code-Umgebung — vollständige
Projekt-Konzept-Referenz mit Routing-Logik, Datenmodell, Phasen-Plan.

## Reaktivierung

Bei Wiederaufnahme:
1. `BH-REFERENZ-AKTUELL.md` lesen (aktuelle Funktionsreferenz)
2. `FRONTEND-BACKEND-ABGLEICH-LIVE-16042026.md` lesen (Stand der Implementierung)
3. Live-Stand auf Hostinger prüfen
4. Edge Functions Status checken (lieber per Supabase Dashboard als per Code)'

setup_repo \
  "$SRC_BH" \
  "$ROOT/buchhaltungsassistent" \
  "xmedia-buchhaltungsassistent" \
  "KI-Buchhaltungsassistent (Live-Web-App + Edge Functions + Archiv)" \
  "$BH_GITIGNORE" \
  "$BH_README"
echo

# ───────────────────────────────────────────────────────────────
# Schritt 3: STILLGELEGT.md in beiden Quellordnern
# ───────────────────────────────────────────────────────────────
echo -e "${BOLD}[3/4] STILLGELEGT.md in Dropbox-Quellen anlegen...${NC}"

cat > "$SRC_CC/STILLGELEGT.md" <<EOF
# STILLGELEGT — bitte hier NICHT mehr arbeiten

**Stand:** $(date +%Y-%m-%d)

Die Inhalte dieses Ordners sind in die neue Projektstruktur überführt worden.
Code und Doku werden NUR NOCH dort gepflegt:

## Neuer Speicherort

- **Lokal:**  \`~/Documents/Claude/Projects/x-media/creative-studio/\`
- **GitHub:** https://github.com/x-media-music/xmedia-creative-studio (privat)

## Sensible Dateien

Die folgenden Dateien sind im neuen Setup **bewusst nicht** committet:
- \`02_MCP-Server/.env\`                          — Higgsfield-Keys
- \`02_MCP-Server/xmedia-creative-mcp/.env\`      — Higgsfield-Keys
- große \`*.mp4\`/\`*.mov\` in \`04_Ergebnisse/\` — bleiben lokal

Wenn du auf einem neuen Mac arbeitest: diese Dateien aus diesem Backup-Ordner
in den neuen Projektordner kopieren.

## Warum dieser Ordner trotzdem noch da ist

Als reines Backup. Spätestens 1–2 Monate nach Migration kann er ins Archiv
verschoben oder gelöscht werden.
EOF
echo -e "  ${GREEN}✓ Content Creator/STILLGELEGT.md${NC}"

cat > "$SRC_BH/STILLGELEGT.md" <<EOF
# STILLGELEGT — bitte hier NICHT mehr arbeiten

**Stand:** $(date +%Y-%m-%d)

Die Inhalte dieses Ordners sind in die neue Projektstruktur überführt worden.
Code und Doku werden NUR NOCH dort gepflegt:

## Neuer Speicherort

- **Lokal:**  \`~/Documents/Claude/Projects/x-media/buchhaltungsassistent/\`
- **GitHub:** https://github.com/x-media-music/xmedia-buchhaltungsassistent (privat)

## Sensible Dateien

Die folgenden Dateien sind im neuen Setup **bewusst nicht** committet:
- \`_archiv_25-03-2026_vite-umbau-nie-deployt/.env\`

Wenn du auf einem neuen Mac arbeitest: aus diesem Backup-Ordner kopieren.

## Status

Projekt ist aktuell pausiert. Wird voraussichtlich überarbeitet/reaktiviert.

## Warum dieser Ordner trotzdem noch da ist

Als reines Backup. Spätestens 1–2 Monate nach Migration kann er ins Archiv
verschoben oder gelöscht werden.
EOF
echo -e "  ${GREEN}✓ Buchhaltungsassistent/STILLGELEGT.md${NC}"
echo

# ───────────────────────────────────────────────────────────────
# Schritt 4: Zusammenfassung
# ───────────────────────────────────────────────────────────────
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Phase B.4 abgeschlossen${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "  Neue Repos auf GitHub:"
echo "    • https://github.com/x-media-music/xmedia-creative-studio"
echo "    • https://github.com/x-media-music/xmedia-buchhaltungsassistent"
echo
echo "  Lokal:"
echo "    • $ROOT/creative-studio/"
echo "    • $ROOT/buchhaltungsassistent/"
echo
echo "  Sensible Dateien (NICHT auf GitHub):"
echo "    • Creative Studio .env-Files (Higgsfield-Keys HF_API_KEY/HF_SECRET)"
echo "    • Buchhaltungs _archiv_.../.env"
echo "    • Große *.mp4 Renders in 04_Ergebnisse/"
echo
echo "  Phase B ist damit abgeschlossen! 🎉"
echo "  Alle aktiven Projekte sind jetzt in einer sauberen Struktur + auf GitHub."
echo
read -p "Drücke Return zum Beenden..." dummy

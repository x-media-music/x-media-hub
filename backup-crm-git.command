#!/bin/bash
# =====================================================================
#  CRM Git-Backup  —  läuft AUF DEM MAC, mehrmals täglich per launchd
#  und zusätzlich per Doppelklick.
#
#  Neu seit 25.08.2026:
#   · Zweig 'main' (der produktive)
#   · Wächter: schlägt Alarm, wenn anderswo eine neuere Fassung liegt
#   · Fehler erscheinen als Meldung auf dem Bildschirm, nicht nur im Log
# =====================================================================
set -uo pipefail

CRM_DIR="/Users/dirkwoehrle/Documents/Claude/Projects/x-media/crm"
BRANCH="main"
EXPECTED_REMOTE="https://github.com/x-media-music/xmedia-crm.git"
LOG="$HOME/Library/Logs/crm-git-backup.log"
ALT_ORDNER="/Users/dirkwoehrle/Library/CloudStorage/Dropbox/x-media MUSIC GmbH/CRM"

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

log()   { echo "$(date '+%Y-%m-%d %H:%M:%S')  $*" | tee -a "$LOG"; }
melde() { osascript -e "display notification \"$1\" with title \"CRM-Backup\" sound name \"Basso\"" 2>/dev/null; }

log "----- CRM-Backup gestartet -----"

cd "$CRM_DIR" 2>/dev/null || { log "FEHLER: Ordner nicht gefunden: $CRM_DIR"; melde "CRM-Ordner nicht gefunden."; exit 1; }

# --- Wächter 1: richtiges Repo ---
REMOTE="$(git remote get-url origin 2>/dev/null || true)"
if [ "$REMOTE" != "$EXPECTED_REMOTE" ]; then
  log "ABBRUCH: Falsches Remote ('$REMOTE')."; melde "Falsches Repo — nicht gesichert."; exit 1
fi

# --- Wächter 2: richtiger Zweig ---
AKT="$(git rev-parse --abbrev-ref HEAD)"
if [ "$AKT" != "$BRANCH" ]; then
  log "ABBRUCH: Zweig '$AKT' statt '$BRANCH'."; melde "Falscher Zweig ($AKT) — nicht gesichert."; exit 1
fi

# --- Wächter 3: ist das überhaupt der produktive Stand? ---
if ! grep -q "n8n.srv1596684" crm-source.html 2>/dev/null; then
  log "ABBRUCH: crm-source.html sieht nicht nach dem produktiven Stand aus."
  melde "Der gesicherte Ordner sieht nicht produktiv aus — bitte prüfen."; exit 1
fi

# --- Wächter 4: liegt anderswo eine NEUERE Fassung? (der Fehler von 2026) ---
if [ -f "$ALT_ORDNER/crm-source.html" ]; then
  if [ "$ALT_ORDNER/crm-source.html" -nt "crm-source.html" ]; then
    log "WARNUNG: Im alten Dropbox-Ordner liegt eine NEUERE crm-source.html!"
    log "         Es wird offenbar am falschen Ort gearbeitet: $ALT_ORDNER"
    melde "Im alten Dropbox-Ordner liegt eine neuere CRM-Fassung. Bitte prüfen!"
  fi
fi

# --- Wächter 5: hängengebliebene Git-Sperre? (Ursache der Lücke Mai-August 2026) ---
while IFS= read -r L; do
  [ -z "$L" ] && continue
  if [ -z "$(find "$L" -mmin -5 2>/dev/null)" ]; then
    rm -f "$L" && log "Hängengebliebene Sperre entfernt: $L"
  else
    log "Ein anderer Git-Vorgang läuft ($L) — diese Runde übersprungen."; exit 0
  fi
done < <(find .git -name "*.lock" -not -name "*.weg*" -not -name "*.bak*" -not -name "*.old*" -not -name "*.ALTLAST*" -not -name "*.removed*" 2>/dev/null)

git config user.name  >/dev/null 2>&1 || git config user.name  "x-media-music"
git config user.email >/dev/null 2>&1 || git config user.email "info@xmedia24.com"

# --- 1) Änderungen sichern ---
N=0
if [ -n "$(git status --porcelain)" ]; then
  N="$(git status --porcelain | wc -l | tr -d ' ')"
  git add -A
  git commit -m "Auto-Backup $(date '+%Y-%m-%d %H:%M') (automatische Sicherung)" >>"$LOG" 2>&1
  log "$N Datei(en) gesichert (Commit $(git rev-parse --short HEAD))."
fi

# --- 2) Etwas zu übertragen? ---
AHEAD="$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)"
if [ "$N" -eq 0 ] && [ "$AHEAD" -eq 0 ]; then
  log "Keine Änderungen. Fertig."; exit 0
fi

# --- 3) Übertragen ---
if git push origin "$BRANCH" >>"$LOG" 2>&1; then
  log "OK: $AHEAD Stand/Stände zu GitHub übertragen (Commit $(git rev-parse --short HEAD))."
else
  log "FEHLER: Lokal gesichert, aber Übertragung zu GitHub fehlgeschlagen."
  log "        Prüfen:  gh auth status   /   git -C \"$CRM_DIR\" push"
  melde "Sicherung liegt lokal, aber GitHub wurde nicht erreicht."
  exit 1
fi

log "----- CRM-Backup beendet -----"

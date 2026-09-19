#!/bin/bash
# =====================================================================
#  x-media-Klammer sichern  —  läuft AUF DEM MAC, per launchd und
#  zusätzlich per Doppelklick.
#
#  Sichert den Ordner x-media SELBST (CLAUDE.md, README.md,
#  ABHAENGIGKEITS-KARTE.md, die .command-Skripte) nach GitHub.
#  Die Unterprojekte (crm, Websites, MCP-Server) sind eigene Repos
#  und werden hier NICHT mitgesichert.
#
#  Angelegt 19.09.2026 — schließt die letzte Lücke im Sicherungsnetz.
# =====================================================================
set -uo pipefail

KLAMMER_DIR="/Users/dirkwoehrle/Documents/Claude/Projects/x-media"
BRANCH="main"
EXPECTED_REMOTE="https://github.com/x-media-music/x-media-hub.git"
LOG="$HOME/Library/Logs/crm-git-backup.log"

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

log()   { echo "$(date '+%Y-%m-%d %H:%M:%S')  [klammer] $*" | tee -a "$LOG"; }
melde() { osascript -e "display notification \"$1\" with title \"x-media-Sicherung\" sound name \"Basso\"" 2>/dev/null; }

cd "$KLAMMER_DIR" 2>/dev/null || { log "FEHLER: Ordner nicht gefunden: $KLAMMER_DIR"; melde "x-media-Ordner nicht gefunden."; exit 1; }

# --- Wächter 1: richtiges Repo ---
REMOTE="$(git remote get-url origin 2>/dev/null || true)"
if [ "$REMOTE" != "$EXPECTED_REMOTE" ]; then
  log "ABBRUCH: Falsches Remote ('$REMOTE')."; melde "Falsches Repo — Klammer nicht gesichert."; exit 1
fi

# --- Wächter 2: richtiger Zweig ---
AKT="$(git rev-parse --abbrev-ref HEAD)"
if [ "$AKT" != "$BRANCH" ]; then
  log "ABBRUCH: Zweig '$AKT' statt '$BRANCH'."; melde "Falscher Zweig ($AKT) — Klammer nicht gesichert."; exit 1
fi

# --- Wächter 3: hängengebliebene Sperren wegräumen ---
#     (entstehen, wenn ein Git-Vorgang abbricht — z.B. aus einer Cowork-Sitzung)
while IFS= read -r L; do
  [ -z "$L" ] && continue
  if [ -z "$(find "$L" -mmin -5 2>/dev/null)" ]; then
    rm -f "$L" && log "Hängengebliebene Sperre entfernt: $L"
  else
    log "Ein anderer Git-Vorgang läuft ($L) — diese Runde übersprungen."; exit 0
  fi
done < <(find .git -maxdepth 1 -name "*.lock" 2>/dev/null)

git config user.name  >/dev/null 2>&1 || git config user.name  "x-media-music"
git config user.email >/dev/null 2>&1 || git config user.email "info@xmedia24.com"

# --- Nichts zu tun? ---
if [ -z "$(git status --porcelain)" ] && [ "$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)" -eq 0 ]; then
  log "Keine Änderungen. Fertig."; exit 0
fi

# --- Änderungen vormerken ---
N="$(git status --porcelain | wc -l | tr -d ' ')"
git add -A

# --- Wächter 4: GEHEIMNIS-BREMSE ---------------------------------------
#     In diesem Ordner liegen API-KEYS.md, Datenbank-Auszüge und
#     n8n-Sicherungen. Die .gitignore schliesst sie aus — aber falls
#     dort je etwas durchrutscht, bricht die Sicherung hier ab,
#     statt Zugangsdaten zu GitHub zu schicken.
VORGEMERKT="$(git diff --cached --name-only)"

VERBOTEN="$(echo "$VORGEMERKT" | grep -iE '(^|/)(API-KEYS\.md|\.env|credentials\.json)|(^|/)_DB-Sicherung/|(^|/)_SICHERUNG-CRM-|(^|/)_n8n-Sicherung/|(^|/)node_modules/|\.pem$|\.p12$' || true)"
if [ -n "$VERBOTEN" ]; then
  log "ABBRUCH — verbotene Datei vorgemerkt:"
  echo "$VERBOTEN" | sed 's/^/          /' | tee -a "$LOG"
  git reset >/dev/null 2>&1
  melde "Sicherung gestoppt: Zugangsdaten wären hochgeladen worden."
  exit 1
fi

# Das Suchmuster wird aus Teilen zusammengesetzt, damit dieses Skript
# nicht sich selbst als Fund meldet (Fehler vom 19.09.2026).
JWT_MUSTER="eyJhbGciOiJIUzI1""NiIs"
PEM_MUSTER="-----BEGIN"" [A-Z ]*PRIVATE KEY-----"

BETROFFEN=""
while IFS= read -r DATEI; do
  [ -z "$DATEI" ] && continue
  [ -f "$DATEI" ] || continue
  if grep -qE "$JWT_MUSTER|$PEM_MUSTER" "$DATEI" 2>/dev/null; then
    BETROFFEN="$BETROFFEN$DATEI
"
  fi
done <<< "$VORGEMERKT"

if [ -n "$BETROFFEN" ]; then
  log "ABBRUCH — in dieser Datei steht ein Schlüssel oder Zertifikat:"
  printf '%s' "$BETROFFEN" | sed 's/^/          /' | tee -a "$LOG"
  git reset >/dev/null 2>&1
  melde "Sicherung gestoppt: Schlüssel im Text gefunden."
  exit 1
fi
# -----------------------------------------------------------------------

git commit -m "Auto-Backup $(date '+%Y-%m-%d %H:%M') (automatische Sicherung)" >>"$LOG" 2>&1
log "$N Datei(en) gesichert (Commit $(git rev-parse --short HEAD))."

AHEAD="$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)"
if git push origin "$BRANCH" >>"$LOG" 2>&1; then
  log "OK: $AHEAD Stand/Stände zu GitHub übertragen."
else
  log "FEHLER: Lokal gesichert, aber Übertragung zu GitHub fehlgeschlagen."
  melde "Klammer liegt lokal gesichert, GitHub wurde nicht erreicht."
  exit 1
fi

#!/bin/bash
# =====================================================================
#  MCP-Server sichern  —  läuft mit dem CRM-Backup zusammen
# =====================================================================
set -uo pipefail
SRV="/Users/dirkwoehrle/Documents/Claude/Projects/x-media/mcp-crm-server"
LOG="$HOME/Library/Logs/crm-git-backup.log"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
log()   { echo "$(date '+%Y-%m-%d %H:%M:%S')  [mcp] $*" | tee -a "$LOG"; }
melde() { osascript -e "display notification \"$1\" with title \"MCP-Server-Backup\" sound name \"Basso\"" 2>/dev/null; }

cd "$SRV" 2>/dev/null || { log "Ordner nicht gefunden — übersprungen."; exit 0; }
[ -d .git ] || { log "Noch kein Git-Repo — MCP-Server-Git-Einrichten.command ausführen."; exit 0; }

while IFS= read -r L; do
  [ -z "$L" ] && continue
  [ -z "$(find "$L" -mmin -5 2>/dev/null)" ] && rm -f "$L" && log "Hängengebliebene Sperre entfernt: $L"
done < <(find .git -name "*.lock" -not -name "*.weg*" -not -name "*.bak*" -not -name "*.old*" 2>/dev/null)

N=0
if [ -n "$(git status --porcelain)" ]; then
  N="$(git status --porcelain | wc -l | tr -d ' ')"
  git add -A
  VERBOTEN="$(git diff --cached --name-only | grep -vE '(^|/)\.env\.example$' | grep -E '(^|/)\.env$|(^|/)\.env\.|node_modules/' || true)"
  if [ -n "$VERBOTEN" ]; then
    git reset -q; log "ABBRUCH: Zugangsdaten wären mitgesichert worden ($VERBOTEN)."
    melde "MCP-Sicherung gestoppt: Zugangsdaten im Commit."; exit 1
  fi
  git commit -q -m "Auto-Backup $(date '+%Y-%m-%d %H:%M')" && log "$N Datei(en) gesichert ($(git rev-parse --short HEAD))."
fi

git remote get-url origin >/dev/null 2>&1 || { log "Kein GitHub-Repo hinterlegt — nur lokal gesichert."; exit 0; }
AHEAD="$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)"
[ "$N" -eq 0 ] && [ "$AHEAD" -eq 0 ] && { log "Keine Änderungen."; exit 0; }
if git push origin main >>"$LOG" 2>&1; then
  log "OK: zu GitHub übertragen."
else
  log "FEHLER: Push fehlgeschlagen."; melde "MCP-Server: GitHub wurde nicht erreicht."; exit 1
fi

#!/bin/bash
# =====================================================================
#  CRM-Datenbank sichern — täglich per launchd, oder per Doppelklick.
#  Legt alle Tabellen als JSON unter x-media/_DB-Sicherung/<Datum>/ ab,
#  sieben Stände rollierend. Liest nur, ändert nichts.
# =====================================================================
set -uo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
LOG="$HOME/Library/Logs/crm-db-backup.log"
SKRIPT="/Users/dirkwoehrle/Documents/Claude/Projects/x-media/backup-crm-datenbank.mjs"

{
  echo ""
  echo "===== $(date '+%Y-%m-%d %H:%M:%S')  Datenbank-Sicherung ====="
  if node "$SKRIPT"; then
    echo "OK"
  else
    echo "FEHLGESCHLAGEN (Code $?)"
    osascript -e 'display notification "Die tägliche Sicherung der CRM-Datenbank ist fehlgeschlagen." with title "CRM-Backup" sound name "Basso"' 2>/dev/null
  fi
} 2>&1 | tee -a "$LOG"

if [ -t 1 ]; then read -n 1 -s -r -p "Taste drücken zum Schließen ..."; echo ""; fi

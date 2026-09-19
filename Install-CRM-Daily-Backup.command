#!/bin/bash
# =====================================================================
#  Installer: täglicher CRM-Git-Backup als macOS launchd-Job (20:00 Uhr)
#  Einmal doppelklicken. Danach läuft das Backup automatisch auf dem Mac.
# =====================================================================
set -uo pipefail

RUNNER="/Users/dirkwoehrle/Documents/Claude/Projects/x-media/backup-crm-git.command"
PLIST="$HOME/Library/LaunchAgents/com.xmedia.crm-git-backup.plist"
LOG="$HOME/Library/Logs/crm-git-backup.log"

echo "==> Richte täglichen CRM-Backup-Job ein ..."

if [ ! -f "$RUNNER" ]; then
  echo "FEHLER: Backup-Skript nicht gefunden: $RUNNER"
  echo "Bitte sicherstellen, dass 'backup-crm-git.command' im x-media-Ordner liegt."
  read -n 1 -s -r -p "Taste drücken zum Schließen ..."; exit 1
fi

chmod +x "$RUNNER"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.xmedia.crm-git-backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$RUNNER</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key><integer>20</integer>
        <key>Minute</key><integer>0</integer>
    </dict>
    <key>StandardOutPath</key><string>$LOG</string>
    <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

echo ""
echo "==> Fertig! Der Job 'com.xmedia.crm-git-backup' läuft jetzt täglich um 20:00 Uhr."
echo "    Log-Datei:  $LOG"
echo ""
echo "==> Ich führe jetzt einmal einen Test-Lauf aus ..."
echo ""
/bin/bash "$RUNNER"
echo ""
echo "==> Test-Lauf beendet. Oben siehst du das Ergebnis (siehe auch Log)."
echo ""
read -n 1 -s -r -p "Taste drücken zum Schließen ..."
echo ""

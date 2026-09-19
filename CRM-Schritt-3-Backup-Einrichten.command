#!/bin/bash
# =====================================================================
#  SCHRITT 3 von 3 — Sicherungen einrichten
#
#  Richtet zwei automatische Aufgaben auf diesem Mac ein:
#    1. CRM-Code + MCP-Server → GitHub, fünfmal täglich (9, 12, 15, 18, 20 Uhr)
#                   und einmal beim Anmelden
#    2. CRM-Datenbank → JSON-Auszug, täglich 20:30, sieben Stände rollierend
#
#  Ein alter Backup-Job wird dabei ersetzt, nicht ergänzt.
# =====================================================================
set -uo pipefail

BASIS="/Users/dirkwoehrle/Documents/Claude/Projects/x-media"
GIT_RUNNER="$BASIS/backup-alle.command"   # sichert CRM UND MCP-Server
DB_RUNNER="$BASIS/backup-crm-datenbank.command"
GIT_PLIST="$HOME/Library/LaunchAgents/com.xmedia.crm-git-backup.plist"
DB_PLIST="$HOME/Library/LaunchAgents/com.xmedia.crm-db-backup.plist"
GIT_LOG="$HOME/Library/Logs/crm-git-backup.log"
DB_LOG="$HOME/Library/Logs/crm-db-backup.log"

abbruch() { echo ""; echo "❌ ABBRUCH: $*"; echo ""; read -n 1 -s -r -p "Taste drücken zum Schließen ..."; exit 1; }

echo "==============================================="
echo " SCHRITT 3 — Sicherungen einrichten"
echo "==============================================="
echo ""

[ -f "$GIT_RUNNER" ] || abbruch "Nicht gefunden: $GIT_RUNNER"
[ -f "$BASIS/backup-crm-git.command" ] || abbruch "Nicht gefunden: backup-crm-git.command"
[ -f "$BASIS/backup-mcp-git.command" ] || abbruch "Nicht gefunden: backup-mcp-git.command"
chmod +x "$BASIS/backup-crm-git.command" "$BASIS/backup-mcp-git.command"
[ -f "$DB_RUNNER" ]  || abbruch "Nicht gefunden: $DB_RUNNER"
chmod +x "$GIT_RUNNER" "$DB_RUNNER"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

# --------------------------------------------------- 1) Code, 5x täglich
cat > "$GIT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.xmedia.crm-git-backup</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$GIT_RUNNER</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartCalendarInterval</key>
  <array>
    <dict><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
    <dict><key>Hour</key><integer>12</integer><key>Minute</key><integer>0</integer></dict>
    <dict><key>Hour</key><integer>15</integer><key>Minute</key><integer>0</integer></dict>
    <dict><key>Hour</key><integer>18</integer><key>Minute</key><integer>0</integer></dict>
    <dict><key>Hour</key><integer>20</integer><key>Minute</key><integer>0</integer></dict>
  </array>
  <key>StandardOutPath</key><string>$GIT_LOG</string>
  <key>StandardErrorPath</key><string>$GIT_LOG</string>
</dict>
</plist>
EOF

# --------------------------------------------------- 2) Datenbank, täglich
cat > "$DB_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.xmedia.crm-db-backup</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$DB_RUNNER</string></array>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>20</integer><key>Minute</key><integer>30</integer></dict>
  <key>StandardOutPath</key><string>$DB_LOG</string>
  <key>StandardErrorPath</key><string>$DB_LOG</string>
</dict>
</plist>
EOF

echo "[1/3] Zeitpläne geschrieben."

launchctl unload "$GIT_PLIST" 2>/dev/null || true
launchctl unload "$DB_PLIST"  2>/dev/null || true
launchctl load  "$GIT_PLIST"  || abbruch "Code-Backup ließ sich nicht aktivieren."
launchctl load  "$DB_PLIST"   || abbruch "Datenbank-Backup ließ sich nicht aktivieren."
echo "[2/3] Beide Aufgaben aktiv:"
launchctl list | grep -E "com\.xmedia\.crm-(git|db)-backup" | sed 's/^/      /'

echo ""
echo "[3/3] Probelauf ..."
echo ""
echo "--- Code-Sicherung ---------------------------------"
/bin/bash "$GIT_RUNNER"
echo ""
echo "--- Datenbank-Sicherung ----------------------------"
/bin/bash "$DB_RUNNER"

echo ""
echo "==============================================="
echo " FERTIG."
echo "   Code + MCP: 5x täglich + beim Anmelden  →  GitHub"
echo "   Datenbank: täglich 20:30  →  x-media/_DB-Sicherung/"
echo "   Protokolle: $GIT_LOG"
echo "               $DB_LOG"
echo "==============================================="
echo ""
read -n 1 -s -r -p "Taste drücken zum Schließen ..."
echo ""

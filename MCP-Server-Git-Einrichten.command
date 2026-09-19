#!/bin/bash
# =====================================================================
#  MCP-Server unter Versionskontrolle stellen  (einmalig)
#
#  Legt in mcp-crm-server ein Git-Repo an, macht den ersten Commit und
#  erstellt ein PRIVATES GitHub-Repo x-media-music/xmedia-crm-mcp.
#  Die .env mit Service-Key und Postfach-Passwörtern bleibt draußen —
#  das prüft das Skript, bevor es irgendetwas überträgt.
#  (.env.example ist die Vorlage ohne echte Werte und darf mit.)
#
#  Fassung 3: räumt hängengebliebene Git-Sperren weg, bricht bei einem
#  fehlgeschlagenen "git add" ab und kommt mit einem bereits bestehenden
#  GitHub-Repo zurecht.
# =====================================================================
set -uo pipefail
SRV="/Users/dirkwoehrle/Documents/Claude/Projects/x-media/mcp-crm-server"
REPO="x-media-music/xmedia-crm-mcp"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
abbruch() { echo ""; echo "❌ ABBRUCH: $*"; echo ""; read -n 1 -s -r -p "Taste drücken zum Schließen ..."; exit 1; }

echo "==============================================="
echo " MCP-Server unter Versionskontrolle stellen"
echo "==============================================="
echo ""
cd "$SRV" 2>/dev/null || abbruch "Ordner nicht gefunden: $SRV"

# --- .gitignore ergänzen (Diagnose-Skript mit echten Kundendaten) ---
grep -q "^_lesen3.mjs" .gitignore 2>/dev/null || cat >> .gitignore <<'IGN'

# Diagnose-Skript mit echten Kundendaten — gehört nicht ins Repo (25.08.2026)
_lesen3.mjs
IGN

if [ -d .git ]; then
  echo "[1/5] Git-Repo besteht bereits."
else
  git init -q -b main || abbruch "Git-Repo konnte nicht angelegt werden."
  echo "[1/5] Git-Repo angelegt (Zweig main).  ✅"
fi

# --- Hängengebliebene Sperren entfernen ---
while IFS= read -r L; do
  [ -z "$L" ] && continue
  if [ -z "$(find "$L" -mmin -2 2>/dev/null)" ]; then
    rm -f "$L" && echo "      · entfernte hängengebliebene Sperre: $L"
  else
    abbruch "Es läuft gerade ein anderer Git-Vorgang ($L). Kurz warten und erneut starten."
  fi
done < <(find .git -name "*.lock" -not -name "*.weg*" -not -name "*.bak*" -not -name "*.old*" 2>/dev/null)

git config user.name  >/dev/null 2>&1 || git config user.name  "x-media-music"
git config user.email >/dev/null 2>&1 || git config user.email "info@xmedia24.com"

# --- Was würde übertragen? ---
git add -A || abbruch "Vormerken fehlgeschlagen (siehe Meldung oben)."
echo ""
echo "[2/5] Diese Dateien kämen ins Repo:"
ANZAHL="$(git diff --cached --name-only | wc -l | tr -d ' ')"
git diff --cached --name-only | sed 's/^/      · /'
if [ "$ANZAHL" = "0" ] && ! git rev-parse HEAD >/dev/null 2>&1; then
  abbruch "Nichts vorgemerkt und noch kein Commit vorhanden. Bitte melden."
fi

# --- Sicherheitsprüfung: keine Geheimnisse ---
echo ""
echo "[3/5] Sicherheitsprüfung ..."
VERBOTEN="$(git diff --cached --name-only | grep -v -E '(^|/)\.env\.example$' | grep -E '(^|/)\.env$|(^|/)\.env\.|node_modules/|_lesen3\.mjs' || true)"
if [ -n "$VERBOTEN" ]; then
  git reset -q
  abbruch "Diese Dateien dürfen nicht ins Repo: $VERBOTEN"
fi
TREFFER="$(git diff --cached --name-only | while read -r f; do
  [ -f "$f" ] || continue
  grep -lE 'eyJhbGciOiJIUzI1NiI' "$f" 2>/dev/null
done)"
if [ -n "$TREFFER" ]; then
  git reset -q
  abbruch "In diesen Dateien steht ein Schlüssel im Klartext: $TREFFER"
fi
echo "      $ANZAHL Datei(en), keine Zugangsdaten darunter.  ✅"

echo ""
read -n 1 -s -r -p "      Weiter mit beliebiger Taste — abbrechen mit Strg+C ..."
echo ""

# --- Commit ---
if git diff --cached --quiet; then
  echo "[4/5] Nichts Neues zu committen."
else
  git commit -q -m "Bestandsaufnahme 25.08.2026: MCP-Server unter Versionskontrolle" || abbruch "Commit fehlgeschlagen."
  echo "[4/5] Commit $(git rev-parse --short HEAD) erstellt.  ✅"
fi
git rev-parse HEAD >/dev/null 2>&1 || abbruch "Es gibt noch keinen Commit — ohne den kann kein Repo übertragen werden."

# --- GitHub ---
echo ""
echo "[5/5] Privates GitHub-Repo ..."
if git remote get-url origin >/dev/null 2>&1; then
  git push -u origin main || abbruch "Push fehlgeschlagen. Prüfe:  gh auth status"
elif gh repo view "$REPO" >/dev/null 2>&1; then
  echo "      Repo besteht bereits — verknüpfe und übertrage."
  git remote add origin "https://github.com/$REPO.git" || abbruch "Remote konnte nicht eingetragen werden."
  git push -u origin main || abbruch "Push fehlgeschlagen. Prüfe:  gh auth status"
else
  gh repo create "$REPO" --private --source=. --remote=origin --push \
    || abbruch "GitHub-Repo konnte nicht angelegt werden. Prüfe:  gh auth status"
fi
echo "      https://github.com/$REPO  ✅"

echo ""
echo "==============================================="
echo " FERTIG. Der MCP-Server ist versioniert und gesichert."
echo " Ab jetzt läuft er in der automatischen Sicherung mit —"
echo " dafür einmal CRM-Schritt-3-Backup-Einrichten.command erneut starten."
echo "==============================================="
echo ""
read -n 1 -s -r -p "Taste drücken zum Schließen ..."
echo ""

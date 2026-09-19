#!/bin/bash
# =====================================================================
#  SCHRITT 2 von 3 — CRM zusammenführen: ein Ordner, ein Zweig
#
#  Voraussetzung: CRM-Schritt-1-Sicherung.command ist gelaufen.
#  Was passiert:  Der Ordner x-media/crm bekommt auf dem Zweig 'main' den
#                 produktiven Stand. Vier Kontrollen entscheiden danach, ob
#                 das Ergebnis übernommen oder sofort zurückgedreht wird.
#  Nicht mit:     LANDINGPAGE-PROJEKT (bleibt in der Historie auf
#                 'vite-migration' und in der Sicherheitskopie).
# =====================================================================
set -uo pipefail

CRM="/Users/dirkwoehrle/Documents/Claude/Projects/x-media/crm"
QUELLE="origin/vite-migration"
ERWARTETES_REMOTE="https://github.com/x-media-music/xmedia-crm.git"
RETTUNG="/tmp/crm-umzug-$(date +%Y%m%d-%H%M%S)"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

abbruch() { echo ""; echo "❌ ABBRUCH: $*"; echo ""; read -n 1 -s -r -p "Taste drücken zum Schließen ..."; exit 1; }

zurueck() {
  echo ""
  echo "⚠️  Kontrolle fehlgeschlagen — drehe zurück ..."
  git -C "$CRM" reset --hard origin/main >/dev/null 2>&1
  git -C "$CRM" clean -fdq -e node_modules -e API-KEYS.md >/dev/null 2>&1
  echo "   Der Ordner steht wieder auf dem Stand von vorher."
  abbruch "$*"
}

echo "==============================================="
echo " SCHRITT 2 — CRM zusammenführen"
echo "==============================================="
echo ""

cd "$CRM" 2>/dev/null || abbruch "Ordner nicht gefunden: $CRM"
[ "$(git remote get-url origin 2>/dev/null)" = "$ERWARTETES_REMOTE" ] || abbruch "Falsches Repo."

# --- Hängengebliebene Git-Sperren entfernen (siehe 04.05.2026) ---
while IFS= read -r L; do
  [ -z "$L" ] && continue
  if [ -z "$(find "$L" -mmin -2 2>/dev/null)" ]; then
    rm -f "$L" && echo "      · entfernte hängengebliebene Sperre: $L"
  fi
done < <(find .git -name "*.lock" -not -name "*.weg*" -not -name "*.bak*" -not -name "*.old*" -not -name "*.ALTLAST*" -not -name "*.removed*" 2>/dev/null)


echo "[1/7] Hole den aktuellen Stand von GitHub ..."
git fetch -q origin || abbruch "Kein Zugriff auf GitHub."

# --- Beweis, dass Schritt 1 gelaufen ist ---
# In eine Datei schreiben statt durch eine Pipe schicken:
# "git show | grep -q" bricht bei grossen Dateien mit SIGPIPE ab und wird
# durch 'set -o pipefail' faelschlich als Fehler gewertet.
GH_DATEI="$(mktemp -t crmgh)"
git show "$QUELLE:crm-source.html" > "$GH_DATEI" 2>/dev/null \
  || abbruch "Konnte den Stand von GitHub nicht lesen. Bitte zuerst CRM-Schritt-1-Sicherung.command ausführen."
grep -q "n8n.srv1596684" "$GH_DATEI" \
  || abbruch "Auf GitHub fehlt der Live-Stand. Bitte zuerst CRM-Schritt-1-Sicherung.command ausführen — und dessen Meldungen lesen: bricht es dort ab, hier nicht weitermachen."
grep -q "9616a328" "$GH_DATEI" \
  || abbruch "Auf GitHub fehlt die DATEV-Adresse vom 03.08. Bitte zuerst Schritt 1 ausführen."
SOLL_MD5="$(md5 -q "$GH_DATEI")"
rm -f "$GH_DATEI"
echo "      Live-Stand auf GitHub bestätigt.  ✅"

# --- Nur-hier-Dateien retten ---
mkdir -p "$RETTUNG"
for f in CRM-MCP-KONZEPT.md WIEDERHERSTELLUNG.md RUNBOOK-Sicherung-und-Umzug-2026-08-25.md; do
  [ -f "$f" ] && cp "$f" "$RETTUNG/"
done
echo "[2/7] Eigene Dokumente gesichert nach $RETTUNG  ✅"

# --- Auf main, sauber ---
git checkout -q main || abbruch "Wechsel auf 'main' fehlgeschlagen."
git pull -q --ff-only || abbruch "'main' ließ sich nicht aktualisieren."
echo "[3/7] Auf Zweig 'main', Stand von GitHub.  ✅"

# --- Baum ersetzen ---
echo "[4/7] Übernehme den produktiven Stand ..."
git rm -rq --ignore-unmatch -- . || zurueck "Konnte den alten Stand nicht ablösen."
if ! git checkout "$QUELLE" -- . ':(exclude)LANDINGPAGE-PROJEKT' 2>/dev/null; then
  git checkout "$QUELLE" -- . || zurueck "Konnte den neuen Stand nicht einlesen."
  git rm -rq --cached --ignore-unmatch -- LANDINGPAGE-PROJEKT
  rm -rf LANDINGPAGE-PROJEKT
fi

# --- Die vier Kontrollen ---
echo "[5/7] Kontrolle:"
IST_MD5="$(md5 -q crm-source.html 2>/dev/null || echo fehlt)"
[ "$IST_MD5" = "$SOLL_MD5" ] || zurueck "crm-source.html stimmt nicht mit GitHub überein."
echo "      · crm-source.html identisch mit GitHub   ✅"
grep -q "n8n.srv1596684"  crm-source.html || zurueck "n8n-Adresse fehlt."
echo "      · n8n zeigt auf den VPS                  ✅"
grep -q "9616a328"        crm-source.html || zurueck "DATEV-Adresse fehlt."
echo "      · DATEV-Adresse vom 03.08.               ✅"
grep -q "ApiKeysSettings" crm-source.html || zurueck "API-Keys-Reiter fehlt."
echo "      · API-Keys-Reiter vorhanden              ✅"
N_EXP="$(ls exposes 2>/dev/null | wc -l | tr -d ' ')"
[ "$N_EXP" = "22" ] || zurueck "Exposés: $N_EXP statt 22."
echo "      · 22 Exposés                             ✅"

# --- Eigene Dokumente zurück, Zugangsdaten-Verweis umhängen ---
cp -n "$RETTUNG"/*.md . 2>/dev/null
rm -f API-KEYS.md
ln -s ../API-KEYS.md API-KEYS.md
[ -r API-KEYS.md ] || zurueck "Verweis auf API-KEYS.md funktioniert nicht."
echo "[6/7] Dokumente zurückgelegt, Zugangsdaten-Verweis zeigt nach x-media/.  ✅"

# --- Korrigierte Fassungen einsetzen (Deploy-Wächter, Doku-Pfade) ---
NEU="/Users/dirkwoehrle/Documents/Claude/Projects/x-media/_neu-fuer-crm"
if [ -f "$NEU/deploy-hostinger.js" ] && [ -f "$NEU/CRM-REFERENZ-AKTUELL.md" ]; then
  cp "$NEU/deploy-hostinger.js" deploy-hostinger.js
  cp "$NEU/CRM-REFERENZ-AKTUELL.md" CRM-REFERENZ-AKTUELL.md
  node --check deploy-hostinger.js || zurueck "Das korrigierte Deploy-Skript ist fehlerhaft."
  grep -q "ERWARTETER_ORDNER" deploy-hostinger.js || zurueck "Der Deploy-Waechter fehlt."
  echo "      Deploy-Skript und CRM-Referenz auf die neuen Pfade umgestellt.  ✅"
else
  echo "      ⚠️  Korrigierte Fassungen nicht gefunden — Deploy-Skript bleibt unveraendert."
fi

# --- .gitignore härten ---
cat > .gitignore <<'IGN'
API-KEYS.md
*.zip
*.skill
.DS_Store
node_modules/
zi2cQ972

# ergänzt 25.08.2026 — damit Zugangsdaten und Build-Reste nie mitgesichert werden
.next/
.env
.env.*
credentials.json
_SICHERUNG-CRM-*/
IGN

# --- Committen und übertragen ---
git add -A
if git diff --cached --quiet; then
  echo "[7/7] Nichts zu übertragen — Ordner war bereits auf Stand."
else
  git commit -q -m "Konsolidierung 25.08.2026: produktiver Stand aus vite-migration auf main; LANDINGPAGE-PROJEKT ausgegliedert; .gitignore gehaertet" \
    || zurueck "Commit fehlgeschlagen."
  git push origin main || abbruch "Push fehlgeschlagen — lokal ist alles in Ordnung. Prüfe:  gh auth status"
  echo "[7/7] Übertragen zu GitHub.  ✅"
fi

echo ""
echo "==============================================="
echo " FERTIG. Der produktive CRM-Ordner ist jetzt:"
echo "   $CRM   (Zweig main)"
echo ""
echo " Noch offen:"
echo "  · GitHub: Standard-Zweig auf 'main' stellen"
echo "    (Settings > Branches, oder:  gh repo edit x-media-music/xmedia-crm --default-branch main)"
echo "  · In der Claude-Desktop-App den verbundenen Ordner auf diesen Pfad umstellen"
echo "  · Dann: CRM-Schritt-3-Backup-Einrichten.command"
echo "==============================================="
echo ""
read -n 1 -s -r -p "Taste drücken zum Schließen ..."
echo ""

#!/bin/bash
# =====================================================================
#  SCHRITT 1 von 3 — Den Live-Stand des CRM nach GitHub retten
#
#  Was passiert:  Die Arbeit vom 13.07., 03.08. und 07.08.2026 liegt bisher
#                 nur als Datei auf der Platte. Dieses Skript sichert sie
#                 in Git und schiebt sie zu GitHub.
#  Was NICHT passiert: Es wird nichts gelöscht, nichts verschoben, nichts
#                 überschrieben. Nur hinzugefügt.
#
#  Fassung 2 (25.08.2026): räumt hängengebliebene Git-Sperren weg und
#  prüft am Ende hart nach, dass der Stand wirklich auf GitHub liegt.
# =====================================================================
set -uo pipefail

CRM_ALT="/Users/dirkwoehrle/Library/CloudStorage/Dropbox/x-media MUSIC GmbH/CRM"
BRANCH="vite-migration"
ERWARTETES_REMOTE="https://github.com/x-media-music/xmedia-crm.git"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

abbruch() { echo ""; echo "❌ ABBRUCH: $*"; echo ""; echo "Es wurde nichts verändert."; echo ""; read -n 1 -s -r -p "Taste drücken zum Schließen ..."; exit 1; }

echo "==============================================="
echo " SCHRITT 1 — CRM-Live-Stand nach GitHub sichern"
echo "==============================================="
echo ""

cd "$CRM_ALT" 2>/dev/null || abbruch "Ordner nicht gefunden: $CRM_ALT"

# --- 0) Hängengebliebene Sperren entfernen -------------------------------
#     Eine vergessene .git/index.lock lässt JEDEN Commit scheitern — genau
#     das ist hier am 04.05.2026 passiert und blieb 3½ Monate unbemerkt.
GEFUNDEN=0
while IFS= read -r L; do
  [ -z "$L" ] && continue
  # nur Sperren, die älter als 2 Minuten sind (also niemand arbeitet gerade)
  if [ -z "$(find "$L" -mmin -2 2>/dev/null)" ]; then
    rm -f "$L" && { echo "      · entfernte hängengebliebene Sperre: ${L#$CRM_ALT/}"; GEFUNDEN=1; }
  else
    abbruch "Es läuft gerade ein anderer Git-Vorgang ($L). Bitte kurz warten und erneut starten."
  fi
done < <(find .git -name "*.lock" -not -name "*.weg*" -not -name "*.bak*" -not -name "*.old*" -not -name "*.ALTLAST*" -not -name "*.removed*" 2>/dev/null)
[ "$GEFUNDEN" = "1" ] && echo ""

# --- 1) Kontrollen, bevor irgendetwas passiert ---
[ "$(git remote get-url origin 2>/dev/null)" = "$ERWARTETES_REMOTE" ] || abbruch "Falsches Repo."
AKT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[ "$AKT_BRANCH" = "$BRANCH" ] || abbruch "Falscher Zweig ('$AKT_BRANCH', erwartet '$BRANCH')."
grep -q "n8n.srv1596684" crm-source.html || abbruch "crm-source.html sieht nicht nach dem Live-Stand aus."
SOLL_MD5="$(md5 -q crm-source.html)"
echo "[1/5] Ordner, Repo und Zweig stimmen.  ✅"

# --- 2) Was wird gesichert? ---
echo ""
echo "[2/5] Bereite die Sicherung vor ..."
git add crm-source.html backups/ || abbruch "Vormerken fehlgeschlagen (siehe Meldung oben)."
GEPLANT="$(git diff --cached --name-only)"

if [ -z "$GEPLANT" ]; then
  # Nichts vorgemerkt — nur in Ordnung, wenn der Stand schon committet IST.
  if [ "$(git show HEAD:crm-source.html > /tmp/crm_head_$ ; md5 -q /tmp/crm_head_$ ; rm -f /tmp/crm_head_$)" != "$SOLL_MD5" ]; then
    abbruch "Es wurde nichts vorgemerkt, obwohl crm-source.html vom letzten Commit abweicht. Bitte melden."
  fi
  echo "      (bereits gesichert — nichts Neues)"
else
  echo "$GEPLANT" | sed 's/^/      · /'
fi

UNERWARTET="$(git diff --cached --name-only | grep -v -E '^(crm-source\.html|backups/)' || true)"
[ -z "$UNERWARTET" ] || { git reset -q; abbruch "Unerwartete Dateien im Commit: $UNERWARTET"; }

echo ""
read -n 1 -s -r -p "      Weiter mit beliebiger Taste — abbrechen mit Strg+C ..."
echo ""

# --- 3) Committen ---
if [ -n "$GEPLANT" ]; then
  git commit -q -m "Sicherung Live-Stand 25.08.2026: Technik-MwSt 13.07., Nachlass-Fix + DATEV-Adresse 03.08., Positionen-Scroll + Menge x Einzelpreis 07.08." \
    || abbruch "Commit fehlgeschlagen."
  echo "[3/5] Gesichert als Commit $(git rev-parse --short HEAD).  ✅"
else
  echo "[3/5] Nichts zu committen.  ✅"
fi

# --- 4) Pushen ---
echo ""
echo "[4/5] Übertrage zu GitHub ..."
git push origin "$BRANCH" || abbruch "Push fehlgeschlagen. Prüfe die Anmeldung:  gh auth status"

# --- 5) Harter Beweis: liegt der Live-Stand wirklich auf GitHub? ---
git fetch -q origin
GH_DATEI="$(mktemp -t crmgh)"
git show "origin/$BRANCH:crm-source.html" > "$GH_DATEI" || abbruch "Konnte den Stand von GitHub nicht lesen."
[ "$(md5 -q "$GH_DATEI")" = "$SOLL_MD5" ] || { rm -f "$GH_DATEI"; abbruch "Auf GitHub liegt eine ANDERE Fassung als hier. Bitte melden."; }
grep -q "9616a328" "$GH_DATEI" || { rm -f "$GH_DATEI"; abbruch "Auf GitHub fehlt die DATEV-Adresse vom 03.08."; }
rm -f "$GH_DATEI"

echo "[5/5] Kontrolle: GitHub hat exakt diese Fassung.  ✅"
echo ""
echo "==============================================="
echo " FERTIG. Der Live-Stand liegt jetzt auf GitHub."
echo " Nächster Schritt: CRM-Schritt-2-Umzug.command"
echo "==============================================="
echo ""
read -n 1 -s -r -p "Taste drücken zum Schließen ..."
echo ""

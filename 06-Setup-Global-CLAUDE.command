#!/bin/bash
#
# Global-CLAUDE-Setup
# ===================
#
# Legt einen Symlink unter ~/.claude/CLAUDE.md an, der auf das DACH
# unter ~/Documents/Claude/Projects/_dach/CLAUDE.md zeigt.
# (Das Dach routet von dort ins passende Gehirn: business_hub / x-media.)
#
# Wirkung: Claude Code liest diese Datei BEI JEDEM START — egal aus welchem
# Verzeichnis du Claude Code startest. Du musst nie wieder vorher cd-en.
#
# Vorhandener Inhalt in ~/.claude/CLAUDE.md (falls vorhanden) wird gesichert.
# Wirkt sich NUR auf Claude Code aus (CLI), nicht auf Cowork.
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

CLAUDE_DIR="$HOME/.claude"
GLOBAL_MD="$CLAUDE_DIR/CLAUDE.md"
TARGET="$HOME/Documents/Claude/Projects/_dach/CLAUDE.md"

clear
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Global CLAUDE.md für Claude Code einrichten${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "Das richtet ein, dass Claude Code IMMER zuerst das DACH liest"
echo "(routet ins passende Gehirn), egal aus welchem Verzeichnis du startest."
echo

# Voraussetzungen
if [ ! -f "$TARGET" ]; then
  echo -e "${RED}✗ Dach-CLAUDE.md nicht gefunden:${NC}"
  echo "  $TARGET"
  echo "  Hast du den _dach-Ordner schon eingerichtet?"
  read -p "Drücke Return zum Beenden..." dummy
  exit 1
fi
echo -e "${GREEN}✓ Dach-CLAUDE.md gefunden${NC}"

# .claude/-Ordner anlegen falls noch nicht vorhanden
if [ ! -d "$CLAUDE_DIR" ]; then
  mkdir -p "$CLAUDE_DIR"
  echo -e "${GREEN}✓ ~/.claude/ Ordner angelegt${NC}"
else
  echo -e "${GREEN}✓ ~/.claude/ existiert${NC}"
fi

# Aktuellen Zustand prüfen
echo
echo -e "${BOLD}[1/3] Aktueller Stand von ~/.claude/CLAUDE.md...${NC}"

if [ -L "$GLOBAL_MD" ]; then
  CURRENT=$(readlink "$GLOBAL_MD")
  if [ "$CURRENT" = "$TARGET" ]; then
    echo -e "${GREEN}✓ Symlink zeigt bereits richtig auf:${NC}"
    echo "    $TARGET"
    echo
    echo -e "${YELLOW}Nichts zu tun — Setup ist schon fertig.${NC}"
    read -p "Drücke Return zum Beenden..." dummy
    exit 0
  else
    echo -e "${YELLOW}ℹ Symlink existiert, zeigt aber woanders hin:${NC}"
    echo "    aktuell: $CURRENT"
    echo "    soll:    $TARGET"
    read -p "Soll ich den Symlink umbiegen? [j/n] " ok
    if [[ ! "$ok" =~ ^[Jj] ]]; then
      echo "Abbruch."
      read -p "Return..." dummy; exit 0
    fi
    rm "$GLOBAL_MD"
  fi
elif [ -f "$GLOBAL_MD" ]; then
  echo -e "${YELLOW}⚠ Es gibt schon eine echte Datei (kein Symlink) unter:${NC}"
  echo "    $GLOBAL_MD"
  echo
  echo "  Inhalt (erste 10 Zeilen):"
  head -10 "$GLOBAL_MD" | sed 's/^/    │ /'
  echo
  read -p "Soll ich die Datei als Backup sichern und durch Symlink ersetzen? [j/n] " ok
  if [[ ! "$ok" =~ ^[Jj] ]]; then
    echo "Abbruch. Du kannst die Datei manuell sichern und das Skript erneut starten."
    read -p "Return..." dummy; exit 0
  fi
  BACKUP="$GLOBAL_MD.backup-$(date +%Y-%m-%d-%H%M%S)"
  mv "$GLOBAL_MD" "$BACKUP"
  echo -e "${GREEN}✓ Backup angelegt: $BACKUP${NC}"
else
  echo "  (noch nichts da)"
fi
echo

echo -e "${BOLD}[2/3] Symlink anlegen...${NC}"
ln -s "$TARGET" "$GLOBAL_MD"
echo -e "${GREEN}✓ Symlink erstellt:${NC}"
ls -la "$GLOBAL_MD" | sed 's/^/    /'
echo

echo -e "${BOLD}[3/3] Verifikation...${NC}"
if [ "$(readlink "$GLOBAL_MD")" = "$TARGET" ]; then
  echo -e "${GREEN}✓ Symlink zeigt korrekt auf Master-Doku${NC}"
  echo
  echo "  Erste Zeile der Datei (über den Symlink gelesen):"
  head -1 "$GLOBAL_MD" | sed 's/^/    /'
else
  echo -e "${RED}✗ Verifikation fehlgeschlagen${NC}"
  read -p "Return..." dummy; exit 1
fi
echo

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ Fertig${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
echo "  Ab sofort liest Claude Code automatisch zuerst das Dach,"
echo "  egal in welchem Verzeichnis du startest."
echo
echo "  Test (in einem Terminal):"
echo "    cd ~/"
echo "    claude"
echo "    > Was sagt CLAUDE.md über meine Projekte?"
echo
echo "  Claude sollte das Dach nennen und ins passende Gehirn routen können."
echo
read -p "Drücke Return zum Beenden..." dummy

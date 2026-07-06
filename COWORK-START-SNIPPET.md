# Cowork-Eröffnungs-Snippets

Diese Texte am **Anfang einer neuen Cowork-Session** einfügen, damit Claude sofort den vollen Kontext über dein x-media-Ökosystem hat. Cowork lädt — anders als Claude Code — keine `CLAUDE.md` automatisch.

---

## Standard-Eröffnung (universell)

Kopier diesen Text und füg ihn als allerersten Prompt in eine neue Cowork-Session ein, bevor du deine eigentliche Frage stellst:

```
Bevor wir loslegen: lies zuerst die Master-Doku unter
~/Documents/Claude/Projects/x-media/CLAUDE.md
und beachte dabei besonders die Pfad-Override- und Skill-Status-Tabellen
am Anfang. Halte den Kontext für unsere Session bereit.

Meine eigentliche Frage:
[hier deine Frage]
```

**Tipp:** Stell dir das als macOS-Textersetzung ein!
- Systemeinstellungen → Tastatur → Textersetzung
- Kürzel: `;;xm` (oder ein anderes Kürzel deiner Wahl, das nie versehentlich getippt wird)
- Phrase: den ganzen Block oben

Dann tippst du in jeder Cowork-Session `;;xm`, drückst Leertaste, und der ganze Eröffnungstext erscheint automatisch.

---

## Kurzversion (wenn du in Eile bist)

```
Lies erst ~/Documents/Claude/Projects/x-media/CLAUDE.md, dann:
[deine Frage]
```

---

## Projektspezifische Varianten

Wenn du WEISST, dass es nur um ein einzelnes Sub-Projekt geht, kannst du den Hinweis präziser machen — Claude lädt dann gezielt das richtige:

**CRM-Arbeit:**
```
Wir arbeiten am x-media CRM (~/Documents/Claude/Projects/x-media/crm/).
Lies kurz die Master-Doku ~/Documents/Claude/Projects/x-media/CLAUDE.md
und lade das xmedia-crm Skill. Dann:
[deine Frage]
```

**Website-Arbeit:**
```
Wir arbeiten an xmedia24.com (~/Documents/Claude/Projects/x-media/website-xmedia24/).
Lies erst ~/Documents/Claude/Projects/x-media/CLAUDE.md.
Dann: [deine Frage]
```

**Landingpage-Arbeit:**
```
Wir arbeiten an [oktoberfestbands24.de | partybands24.de].
Pfad: ~/Documents/Claude/Projects/x-media/website-[oktoberfestbands24 | partybands24]/.
Doku: ~/Documents/Claude/Projects/x-media/docs/landingpages/.
Lies erst die Master-Doku. Dann: [deine Frage]
```

**Brevo / Newsletter:**
```
Wir arbeiten am Brevo-Setup (~/Documents/Claude/Projects/BREVO-Account/).
xmedia-brevo Skill ist die Quelle der Wahrheit.
Lies kurz die Master-Doku ~/Documents/Claude/Projects/x-media/CLAUDE.md. Dann:
[deine Frage]
```

**Creative Studio:**
```
Wir arbeiten am Creative Studio (~/Documents/Claude/Projects/x-media/creative-studio/).
content-creator Skill ist die Quelle der Wahrheit.
Lies kurz die Master-Doku. Dann: [deine Frage]
```

**Buchhaltungsassistent:**
```
Wir arbeiten am Buchhaltungsassistenten
(~/Documents/Claude/Projects/x-media/buchhaltungsassistent/).
buchhaltungsassistent Skill ist die Quelle der Wahrheit — und beachte:
Buchhaltungs-Supabase ist hsvpjtpzsnfdpibdkxut (NICHT das CRM-Projekt).
Lies kurz die Master-Doku. Dann: [deine Frage]
```

---

## Warum das nötig ist

- **Claude Code** (CLI) liest `CLAUDE.md` automatisch aus cwd + parent dirs (bzw. global via `~/.claude/CLAUDE.md`-Symlink, eingerichtet durch `06-Setup-Global-CLAUDE.command`).
- **Cowork** hat dieses Verhalten nicht. Skills triggern zwar automatisch über Keywords, aber die zentrale Master-Doku wird ohne explizite Anweisung nicht gelesen.

Mit dem Eröffnungs-Snippet stellst du sicher, dass Claude in Cowork denselben Überblick hat wie in Claude Code.

---

## Bonus: Permanent als Cowork-Project-Context?

Falls Cowork-Updates irgendwann eine "Project-Level-Instructions"-Funktion bekommen
(analog zu Claude Code), kann der Inhalt der `CLAUDE.md` dort direkt eingetragen
werden — dann entfällt das manuelle Snippet-Einfügen. Bis dahin ist der Snippet
die robusteste Lösung.

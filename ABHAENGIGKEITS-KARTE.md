# Abhängigkeits-Karte — was hängt am CRM?

**Erstellt:** 19.09.2026 · **Zweck:** Vor jedem Eingriff ins CRM beantworten, wer davon betroffen ist.
**Methode:** Nicht aus der Erinnerung geschrieben, sondern aus dem Code gelesen — jede Zeile unten
ist an diesem Tag gegen die tatsächlichen Dateien und gegen den Live-Server geprüft.

---

## Die eine Regel, die alles erklärt

> **Fast nichts spricht mit dem CRM. Fast alles spricht mit der Datenbank.**

Das CRM ist keine Zentrale, durch die der Verkehr läuft. Es ist eine Bedienoberfläche —
eine einzige HTML-Datei, die im Browser läuft und direkt mit Supabase redet. Alle anderen
Systeme (Websites, n8n, MCP-Server, Business Hub, Brevo-Sync) reden **ebenfalls direkt mit
Supabase**, nicht mit dem CRM.

**Praktische Folge:** Wer die CRM-Adresse verändert, sperrt oder abschaltet, trifft damit
**nicht** die Automationen. Wer dagegen an der Datenbank dreht, trifft alles gleichzeitig.

```
                    ┌──────────────────────────────────┐
                    │  Supabase  vrntqlmrxlbnhetskwjw  │   ← das eigentliche Herz
                    │  Datenbank + Dateispeicher       │
                    └──────────────────────────────────┘
       ▲            ▲            ▲            ▲            ▲
       │            │            │            │            │
  ┌────┴────┐  ┌────┴────┐  ┌────┴─────┐ ┌────┴─────┐ ┌────┴──────────┐
  │   CRM   │  │Websites │  │   n8n    │ │MCP-Server│ │Creative Studio│
  │(Browser)│  │(4 Stück)│  │(13 Work- │ │    ↓     │ │               │
  └─────────┘  └─────────┘  │ flows)   │ │Business  │ └───────────────┘
                            └────┬─────┘ │   Hub    │
                                 │       └──────────┘
                                 ▼
                          ┌─────────────┐
                          │    Brevo    │
                          └─────────────┘
```

---

## Wer ruft die CRM-Adresse tatsächlich auf?

Live-Adresse: `https://ivory-lapwing-435564.hostingersite.com`

Am 19.09.2026 wurde der gesamte Projektordner durchsucht. Es gibt genau **drei** Aufrufer:

| Wer | Was er aufruft | Darf gesperrt werden? |
|---|---|---|
| **Dirk / Team im Browser** | `/` und alle Unterseiten | **Ja** — genau das ist das Ziel des Passwortschutzes |
| **Endkunden mit Exposé-Link** | `/exposes/expose-*.html` (22 Stück) | **NEIN** — steht in verschickten Angeboten und Verträgen |
| **Endkunden mit Auswahl-Link** | `/auswahl.html?token=…` | **NEIN** — steht in verschickten Band-Auswahl-Mails |

Beide Kundenlinks werden vom CRM selbst erzeugt, in `crm-source.html` Zeile 6107–6145:
die Konstante `SITE` setzt die Adresse davor. Sie landen per Mail beim Veranstalter und
sind damit aus unserer Kontrolle — einmal verschickt, gilt der Link für immer.

---

## Wer ruft die CRM-Adresse NICHT auf — geprüft, nicht vermutet

| System | Redet stattdessen mit | Beleg |
|---|---|---|
| **MCP-Server (`mcp-crm-server`)** | Supabase direkt + n8n-Webhooks | Kein einziger Treffer für `ivory-lapwing` oder `hostingersite` im gesamten Quellcode |
| **Business Hub** | ausschließlich über den MCP-Server | nutzt dessen 17 Werkzeuge, keine eigene Web-Verbindung zum CRM |
| **n8n (13 Workflows)** | Supabase + Brevo + Mailserver | Adressen in den Workflows: nur `supabase.co`, `api.brevo.com`, `api.anthropic.com` |
| **website-xmedia24** | Supabase | 0 Treffer für die CRM-Adresse |
| **partybands24 / oktoberfestbands24** | Supabase + n8n | 0 Treffer |
| **hofbraeu-regiment.de** | Supabase + n8n + Brevo | 0 Treffer |
| **vips-partyband.de** | n8n (CF7-Formular) | 0 Treffer |
| **Brevo** | wird von n8n befüllt | am 19.09.2026 direkt im Brevo-Konto geprüft: alle **6 Vorlagen** und alle **7 Kampagnen** durchsucht — 0 Treffer für die CRM-Adresse, `/exposes/` oder `auswahl.html` |
| **Creative Studio** | Supabase (eigene Tabellen) | 0 Treffer |
| **Buchhaltungsassistent** | eigenes Supabase-Projekt `hsvpjtpzsnfdpibdkxut` | getrennt vom CRM |
| **Google-Ads-Export** | Supabase + Google | läuft lokal auf dem Mac |

**Das ist die wichtigste Aussage dieser Karte:** Ein Passwort vor der CRM-Adresse kann den
Business Hub, den MCP-Server, die Automationen und die Websites nicht stören, weil keines
dieser Systeme diese Adresse jemals aufruft.

---

## Was am CRM hängt — nach Schadensklasse

### 🔴 Klasse 1 — trifft sofort das Tagesgeschäft

| Baustein | Was kaputtgeht, wenn es ausfällt |
|---|---|
| **Supabase-Datenbank** | Alles gleichzeitig: CRM, Websites, Automationen, Business Hub |
| **`crm-source.html`** | Die komplette Bedienoberfläche — Anfragen, Angebote, Rechnungen, Kalender |
| **n8n auf dem VPS** | Kein Mailversand aus dem CRM, kein Brevo-Sync, keine Formular-Eingänge der Websites |

### 🟠 Klasse 2 — trifft den Kundenkontakt, aber nicht den Betrieb

| Baustein | Was kaputtgeht |
|---|---|
| **`exposes/` (22 Dateien)** | Bereits verschickte Exposé-Links laufen ins Leere — beim Kunden, nicht bei uns |
| **`auswahl.html`** | Bereits verschickte Band-Auswahl-Links funktionieren nicht mehr |
| **`.htaccess`** | Deeplinks brechen, Browser zeigen alte Fassungen aus dem Zwischenspeicher |

### 🟡 Klasse 3 — trifft die Arbeitsweise, nicht den Kunden

| Baustein | Was kaputtgeht |
|---|---|
| **MCP-Server** | Business Hub kann Anfragen, Angebote und Kalender nicht mehr lesen oder schreiben |
| **Brevo-Sync** | Newsletter-Listen laufen aus dem Takt (2 Workflows, 30/60-Minuten-Takt) |

---

## ⚠️ Offener Befund vom 19.09.2026: `auswahl.html` ist live nicht vorhanden

**Was festgestellt wurde:** `https://ivory-lapwing-435564.hostingersite.com/auswahl.html`
liefert nicht die Auswahl-Seite, sondern die CRM-Oberfläche (1.154.590 Bytes — exakt die
Größe von `index.html`). Die Datei existiert lokal (16.932 B, in Git) und wird vom CRM aktiv
verlinkt, aber auf dem Server liegt sie nicht.

**Warum:** Das Deploy-Paket besteht laut `CRM-Deploy.command` aus genau zwei Dingen —
`index.html` und `exposes/`. `auswahl.html` ist nicht dabei. Da ein Hostinger-Deploy den
Inhalt ersetzt (Goldene Regel 3), ist die Datei bei einem der letzten Deploys verschwunden.

**Was das für Kunden bedeutet:** Wer einen Auswahl-Link aus einer älteren Mail anklickt,
bekommt kein Fehlerbild, sondern **die interne CRM-Oberfläche** — ohne Anmeldung, weil es
bis heute keine gibt. Zuletzt wurden solche Links am **04.05.2026** verschickt (5 Stück laut
Datenbank-Sicherung).

**Warum das hier steht:** Es ist gleichzeitig ein Argument **für** den Passwortschutz
(er würde genau diese Tür schließen) und eine Aufgabe, die **vorher** geklärt sein muss —
sonst sperrt der Schutz eine Seite aus, die ohnehin schon fehlt, und niemand merkt den
Unterschied. Siehe `crm/PLAN-PASSWORTSCHUTZ-2026-04-29.md`, Abschnitt 3.8 d.

---

## Sicherungslage — Stand 19.09.2026

| Was | Sicherung | Stand | Zurücksetzen dauert |
|---|---|---|---|
| **CRM-Code** | GitHub `x-media-music/xmedia-crm` | Commit `136fdeb` vom 25.08.2026, deckungsgleich mit `origin/main`, 0 offene Stände | Minuten |
| **CRM-Code (Handsicherungen)** | `crm/backups/` | 6 Stände, März–August 2026 | Minuten |
| **Datenbank** | `x-media/_DB-Sicherung/` | ⚠️ **nur 2 Stände** (25.08. und 07.09.) statt der eingerichteten 7 rollierenden | Stunden |
| **Live-Server** | Hostinger-Backup im hPanel | nicht von hier prüfbar — vor jedem Eingriff im Panel nachsehen | 5–15 Min |
| **`.htaccess` (live)** | ⚠️ **keine** — existiert nur auf dem Server, nicht lokal, nicht in Git | — | nicht möglich |
| **MCP-Server** | eigenes Git + Kopie `mcp-crm-server_SICHERUNG_2026-09-15` | 15.09.2026 | Minuten |
| **Websites (5)** | je eigenes Git-Repo | alle versioniert | Minuten |
| **n8n-Workflows** | Git `xmedia-n8n-workflows` + `_n8n-Sicherung/` | siehe Repo | Minuten |

### Drei Lücken, die auffallen

1. **Die laufende `.htaccess` ist nirgends gesichert.** Sie steuert Deeplinks, den
   Exposé-Bypass und die Cache-Header — und existiert nur auf dem Hostinger-Server.
   Geht sie verloren, muss sie aus einer fünf Monate alten Doku rekonstruiert werden.
2. **Die automatischen Sicherungen stehen — Ursache am 19.09.2026 gefunden.**
   In `crm/.git/` **und** in `x-media/.git/` liegt je eine hängengebliebene Sperrdatei
   (`index.lock`), beide vom **07.09.2026, 08:20 Uhr**. Solange sie da ist, scheitert
   jeder schreibende Git-Vorgang in diesem Ordner.

   Das Sicherungsskript hat für genau diesen Fall einen Wächter eingebaut, der alte
   Sperren wegräumt (Wächter 5, seit 25.08.2026). Dass die Sperre trotzdem zwölf Tage
   liegen geblieben ist, heißt: **das Skript wurde seit dem 07.09. nicht mehr
   ausgeführt** — der Hintergrunddienst läuft also nicht.

   **Woher die Sperre kam — am 19.09.2026 reproduziert:** Führt eine Cowork-Sitzung in
   diesen Ordnern einen Git-Befehl aus, legt Git das Schild an, darf es danach aber nicht
   selbst entfernen (die Sitzung hat auf den gemounteten Ordnern standardmäßig kein
   Löschrecht). Schon ein reines `git status` genügt. Genau so entstand die Sperre vom
   07.09., und genau so ist sie am 19.09. versehentlich noch einmal entstanden.
   **Regel daraus: aus Cowork heraus keine Git-Befehle in diesen Ordnern** — lesen ja,
   aber über `cat`, `grep` und Co., nicht über `git`.

   Erschwerend: Es gibt zwei Einrichtungs-Skripte, die denselben Dienstnamen
   (`com.xmedia.crm-git-backup`) überschreiben —
   `CRM-Schritt-3-Backup-Einrichten.command` (richtig: 5×/Tag + beim Anmelden + Datenbank)
   und `Install-CRM-Daily-Backup.command` (veraltet: nur 20:00 Uhr, ohne MCP-Server und
   ohne Datenbank). Wer zuletzt geklickt hat, bestimmt den Zeitplan.

   **Behebung:** einmal `CRM-Schritt-3-Backup-Einrichten.command` doppelklicken. Es setzt
   den richtigen Zeitplan, räumt die Sperre weg, sichert alles Offene und zeigt am Ende,
   ob die Aufgaben aktiv sind.

3. **Die x-media-Klammer ist in keiner Automatik.** `backup-alle.command` sichert nur
   `crm/` und `mcp-crm-server/`. Der Ordner `x-media/` selbst ist ein eigenes Git-Repo
   (mit `CLAUDE.md`, `README.md`, dieser Karte) und wird von niemandem automatisch
   gesichert. Eigene Aufgabe.

---

## Vor jedem CRM-Eingriff: die vier Fragen

1. **Ändere ich die Datenbank oder nur die Oberfläche?** Datenbank trifft alles, Oberfläche nur das CRM.
2. **Ändere ich etwas, das ein Kunde per Link erreicht?** `exposes/`, `auswahl.html` — dann ist der Kunde betroffen, nicht nur wir.
3. **Kommt alles, was live bleiben soll, im Deploy-Paket mit?** Das Paket ersetzt den Serverinhalt.
4. **Gibt es einen frischen Sicherungsstand, auf den ich zurück kann?** Wenn nein: erst sichern.

---

*Diese Karte ist Ebene 1 im Sinne von `_dach/AUFRAEUM-PLAN.md` — sie verhindert Schaden und
gehört deshalb zu dem, was vor einer Änderung gelesen wird. Sie wird fortgeschrieben, wenn
sich Systeme ändern.*

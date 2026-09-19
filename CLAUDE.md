# x-media — Projekt-Ökosystem

> ## ⚙️ ZUERST: `_dach/WERKZEUGE.md`
> Dort steht auf **einer Seite**, was Claude kann und wie es aufgerufen wird.
> **Bevor du sagst „das geht nicht" — erst dort nachsehen.** (03.09.2026)


> **Stand:** 26.05.2026 · **Pflege:** Diese Datei bei jeder größeren Änderung aktualisieren.
> **Lese-Reihenfolge für Claude:** Diese Datei zuerst — dann projektspezifische `CLAUDE.md` im jeweiligen Unterordner — dann passenden Skill (`xmedia-crm`, `xmedia-website`, `xmedia-hofbraeu-regiment`, `xmedia-n8n` etc.).

## ⚠️ Pfad-Override (gilt vor allen Skills!)

Skills referenzieren ggf. noch alte Dropbox-Pfade. **Diese Tabelle hat Vorrang** — wenn ein Skill einen Pfad in der linken Spalte erwähnt, verwende stattdessen den in der rechten Spalte:

| Veralteter Pfad (in Skills) | Aktueller Pfad (verwende DIESEN) |
|---|---|
| `~/Library/CloudStorage/Dropbox/x-media MUSIC GmbH/CRM/` | `~/Documents/Claude/Projects/x-media/crm/` — **existiert seit 25.08.2026 nicht mehr** |
| `~/Dropbox/x-media MUSIC GmbH/CRM/` | `~/Documents/Claude/Projects/x-media/crm/` |
| `Dropbox → Website 2026/xmedia24.com/` | `~/Documents/Claude/Projects/x-media/website-xmedia24/` |
| `~/Dropbox/Content Creator/` | `~/Documents/Claude/Projects/x-media/creative-studio/` |
| `~/Dropbox/x-media MUSIC GmbH/Buchhaltungsassistent/` | `~/Documents/Claude/Projects/x-media/buchhaltungsassistent/` |
| `Dropbox/x-media MUSIC GmbH/CRM/LANDINGPAGE-PROJEKT/` | siehe `website-oktoberfestbands24/` + `website-partybands24/` + `docs/landingpages/` |

**API-KEYS.md** liegt seit 2026-07-01 unter `~/Documents/Claude/Projects/x-media/API-KEYS.md` (x-media Root, außerhalb aller Git-Repos, kein Dropbox mehr). Alte Dropbox-Version ist als "VERALTET" markiert und wird nicht mehr gepflegt. Der Symlink `crm/API-KEYS.md → ../API-KEYS.md` zeigt jetzt relativ auf die neue Location.

## ⚠️ Skill-Status-Override

| Skill | Hinweis |
|---|---|
| `xmedia-newsletter-project` | **veraltet** — beschreibt nur den Plan vom 15.03.2026, nicht den Ist-Zustand. Brevo ist inzwischen produktiv → siehe `xmedia-brevo` Skill. |
| `crm-newsletter` | **DEPRECATED** — beschreibt den CRM-internen Block-Editor, der nicht mehr genutzt wird. Newsletter laufen über Brevo. Code im CRM existiert noch, soll aber nicht weiterentwickelt werden. |
| ~~`xmedia-n8n` Abschnitt 11~~ | **ERLEDIGT 03.09.2026.** Die Warnung war selbst falsch: Der Skill hat die Brevo-Sync-Workflows nie als defekt beschrieben, sondern den Fix vom 05.05.2026 als historischen Kontext dokumentiert. Skill am 03.09. überarbeitet (Cloud gekündigt, Dropbox-Pfade, Rollback). |
| `crm-architektur` Backup-Diagramm | **Pfade veraltet** — der "lokale Dateien"-Pfad ist nicht mehr `~/Library/CloudStorage/Dropbox/...`, sondern `~/Documents/Claude/Projects/x-media/crm/`. |

---

## GitHub-Sync (Phase 2 · seit 06.07.2026)

Die x-media-**Klammer** (dieser Ordner, ohne Unterprojekte) ist ein privates Git-Repo:
`github.com/x-media-music/x-media-hub`. Gesichert werden nur die Top-Level-Dateien
(CLAUDE.md, README, saubere `.command`-Skripte). **Ausgeschlossen** (siehe `.gitignore`):
alle Sub-Repos (crm, website-*, creative-studio, n8n-workflows, tools/gsc-mcp …), `docs/`,
`crm-rebuild/`, `node_modules/`, `API-KEYS.md`, `03-Setup-n8n-Workflows-Backup.command`.

Die Sub-Repos haben **eigene** GitHub-Repos und werden dort separat gesichert — hier nicht anfassen.

- **Vor** Arbeit an der Klammer: `git pull`. **Nach** Arbeit: `git add -A && git commit`,
  dann `git push` — **nur mit Dirks Freigabe** (OWNER-GATE).
- **Secrets NIE committen.** Vor jedem Commit `git status` prüfen.
- Git-Operationen **nativ auf dem Mac** ausführen, nicht aus der Cowork-Sandbox.

---

## Wer & Was

**Unternehmen:** x-media music GmbH (Musikagentur, Künstlermanagement, Musikverlag) + x-media event GmbH (Eventproduktion)
**Inhaber:** Dirk Wöhrle (`info@xmedia24.com`)
**Adresse:** Obere Str. 13, 70190 Stuttgart
**Geschäftsmodell:** Vermittlung von Bands & Künstlern an Veranstalter (Oktoberfeste, Firmenfeiern, Hochzeiten); eigene Künstler unter Vertrag; Musikverlag.

---

## Das Kernsystem im Überblick

```
                    ┌────────────────────────────────┐
                    │  Supabase Haupt-Projekt        │
                    │  vrntqlmrxlbnhetskwjw          │
                    │  (PostgreSQL + Storage)        │
                    └────────────────────────────────┘
                          ▲          ▲          ▲
                          │          │          │
        ┌─────────────────┘          │          └─────────────────┐
        │                            │                            │
   ┌────┴─────┐              ┌───────┴────────┐           ┌───────┴─────────┐
   │   CRM    │              │  xmedia24.com  │           │ Creative Studio │
   │  (live)  │              │   (Website)    │           │  (Bilder/Video) │
   └────┬─────┘              └────────────────┘           └─────────────────┘
        │                            │
        │     ┌──────────────────────┴────────────────┐
        │     │                                       │
        ▼     ▼                                       ▼
   ┌──────────────────┐                    ┌──────────────────────┐
   │  n8n auf VPS     │◄───── Webhooks ────│  Landingpages        │
   │  (13 Workflows)  │                    │  - Oktoberfestbands  │
   │  SMTP/IMAP/Auto  │                    │  - partybands24      │
   └────┬─────────────┘                    │  - (Hofbräu, VIPs)   │
        │                                  └──────────────────────┘
        │  BrvSyncIns01abc01 (60 Min)
        │  BrvSyncUpd01abc01 (30 Min)
        ▼
   ┌──────────────────────────────┐
   │   Brevo (E-Mail-Marketing)   │
   │   Hauptliste 6 + Liste 35    │
   │   + 21 Event-Listen          │
   └──────────────────────────────┘

                    ┌────────────────────────────────┐
                    │  Supabase Buchhaltung          │
                    │  hsvpjtpzsnfdpibdkxut          │
                    │  (eigenes Projekt, inaktiv)    │
                    └────────────────────────────────┘
                                  ▲
                                  │
                         ┌────────┴─────────┐
                         │ Buchhaltungs-    │
                         │ assistent        │
                         │ (PWA, in Pause)  │
                         └──────────────────┘
```

**Merksatz:** CRM, Website und Creative Studio teilen sich EIN Supabase-Projekt. Buchhaltung hat ein EIGENES. Brevo ist die produktive E-Mail-Marketing-Plattform — die Sync-Workflows leben auf demselben n8n-VPS wie der CRM-Mailversand.

---

## Projekt-Register

### 🔴 Kritische Live-Systeme

| Projekt | Lokaler Ordner | GitHub | Live unter | Skill |
|---|---|---|---|---|
| **crm** | `~/Documents/claude/Projects/x-media/crm/` | `x-media-music/xmedia-crm` (privat) | `ivory-lapwing-435564.hostingersite.com` | `xmedia-crm` |
| **website-xmedia24** | `~/Documents/claude/Projects/x-media/website-xmedia24/` | `x-media-music/xmedia24-website` (privat) | `xmedia24.com` | `xmedia-website` |
| **n8n-workflows** | `~/Documents/claude/Projects/x-media/n8n-workflows/` | `x-media-music/xmedia-n8n-workflows` (privat, neu) | VPS `n8n.srv1596684.hstgr.cloud` | `xmedia-n8n` |
| **brevo-account** | `~/Documents/Claude/Projects/BREVO-Account/` *(✓ schon dort)* | (noch nicht git-versioniert — Phase 2) | `app.brevo.com` (Account `info@xmedia24.com`) | `xmedia-brevo` |

### 🟡 Live-Landingpages

| Projekt | Lokaler Ordner | GitHub | Live unter | Anmerkung |
|---|---|---|---|---|
| **website-oktoberfestbands24** | `~/Documents/Claude/Projects/x-media/website-oktoberfestbands24/` | `x-media-music/oktoberfestbands24` (privat) | `oktoberfestbands24.de` | Next.js 16 + React 19 + Supabase + Tailwind 4. Live seit ~13.04.2026. |
| **website-partybands24** | `~/Documents/Claude/Projects/x-media/website-partybands24/` | `x-media-music/partybands24` (privat) | `partybands24.de` | identischer Stack. Live seit ~13.04.2026. |
| **website-hofbraeu-regiment** | `~/Documents/Claude/Projects/x-media/website-hofbraeu-regiment/` | `x-media-music/website-hofbraeu-regiment` (privat) | **`hofbraeu-regiment.de` — live seit DNS-Cutover 17.06.2026** | Next.js 16 + React 19 + Tailwind 4 + i18n DE/EN. Eigener DOI-Flow für Reservisten (Brevo direkt + HMAC-Token). Skill: `xmedia-hofbraeu-regiment`. Master-Doku: `~/Documents/Claude/Projects/hofbraeu-regiment 2026/PROJEKT-DOKUMENTATION.md` |
| **xmedia-gsc-mcp** | `~/Documents/Claude/Projects/x-media/tools/gsc-mcp/` | `x-media-music/xmedia-gsc-mcp` (privat) | (lokales Python-Tool) | Google Search Console MCP-Server für SEO-Monitoring der Landingpages |

### 🟢 In Entwicklung / Pause

| Projekt | Lokaler Ordner | GitHub | Status | Skill |
|---|---|---|---|---|
| **creative-studio** | `~/Documents/Claude/Projects/x-media/creative-studio/` | `x-media-music/xmedia-creative-studio` (privat) | aktiv in Entwicklung, eigene Supabase-Tabellen im Hauptprojekt | `content-creator` |
| **buchhaltungsassistent** | `~/Documents/Claude/Projects/x-media/buchhaltungsassistent/` | `x-media-music/xmedia-buchhaltungsassistent` (privat) | pausiert, eigenes Supabase-Projekt (`hsvpjtpzsnfdpibdkxut`) | `buchhaltungsassistent` |
| **crm-rebuild** | `~/Documents/Claude/Projects/x-media/crm-rebuild/` | (noch nicht git-versioniert) | ⏸️ Pause seit 17.04.2026. CRM 2.0 (Vite 8 + React 19 + TS 6 + Tailwind 4) als Foundation für später. Konzept-Doku komplett (1.000+ Zeilen). | — (eigenes Skill kommt bei Reaktivierung) |

### 🔵 Externe Sites (in Migration auf Next.js)

| Projekt | Plattform | Integration | Migration |
|---|---|---|---|
| **hofbraeu-regiment.de** | ~~WordPress (Avada)~~ → **Next.js, migriert** | CF7-Formular → n8n → Supabase; iCal-Feed Band-ID 22 | ✅ **abgeschlossen.** DNS-Cutover 17.06.2026, Domain zeigt auf die Next.js-App (Hostinger). Alte WP-Installation liegt nur noch als Backup (mind. 90 Tage, siehe `DECOMMISSIONING-Runbook.md`) — **nicht mehr die Live-Seite**. Ab hier gilt die Zeile in „Live-Landingpages" oben. |
| **vips-partyband.de** | WordPress (extern) | CF7-Formular → n8n → Supabase; iCal-Feed Band-ID 25 | ⏳ Migration nach HBR-Vorbild geplant. Schritt-für-Schritt: `~/Documents/Claude/Projects/hofbraeu-regiment 2026/VIPS-PARTYBAND-Blueprint.md` |

---

## Goldene Regeln

### CRM (kritisch)

1. **Live-System nie direkt ändern.** Deploy ausschließlich über `deploy-hostinger.js` in `x-media/crm/` (Zweig `main`). Das Skript sichert vorher nach GitHub und **bricht ab**, wenn das misslingt oder wenn es nicht im produktiven Ordner liegt. Gesichert wird außerdem automatisch: Code 5× täglich, Datenbank täglich 20:30 — siehe `backup-crm-git.command` und `backup-crm-datenbank.command`.
2. **SW-Cache-Version hochzählen** vor jedem Deploy (`sw.js`).
3. **`exposes/` muss immer im Deploy-Zip sein** — Deployment ersetzt den ganzen `public_html`.
4. **`API-KEYS.md` bleibt LOKAL** (in `~/Documents/Claude/Projects/x-media/API-KEYS.md`, x-media Root außerhalb aller Git-Repos), nie auf GitHub — kein Repo trackt diesen Pfad.

### Brevo — Tabu-Liste (NICHT anfassen, gehört zum CRM-E-Mail-Tool, nicht zu Brevo)

5. **`EmailSendView`** (React-Komponente im CRM) bleibt unverändert — sie versendet **Geschäftsmails**, nicht Newsletter.
6. **n8n `WF-2 CRM E-Mail Versand`** + Webhook `/crm-email-send` + Supabase-Tabelle `email_versand` gehören zum CRM-Mailversand und bleiben in Betrieb.
7. **`crm-newsletter` Skill ist DEPRECATED** — der CRM-interne Newsletter-Editor (`NewsletterEditorView`, MJML-Block-Editor, `newsletter_templates`-Tabelle) wird **nicht mehr genutzt**. Wenn am Code etwas zu tun ist, dann nur Entfernen — keine neuen Features.

### Generell

8. **Code lebt unter `~/Documents/claude/Projects/x-media/`**, nicht in Dropbox.
9. **Dokumente, Assets, Belege, Verträge bleiben in Dropbox** — das ist der richtige Ort dafür.
10. **Credentials niemals in den Code committen.** Immer per `.env.local` oder über Symlink zu `API-KEYS.md`.
11. **Supabase Service Role Key niemals im Frontend** — nur in n8n-Workflows oder Edge Functions.
12. **Brevo-API-Keys niemals in Code, HTML, GitHub-Repos oder Markdown** — Brevo-Key lebt in n8n-Credentials, Claude-Desktop-Config (lokal) und im VPS-Env.

---

## Wo liegt was

### Lokal (auf jedem Mac via Git)

```
~/Documents/Claude/Projects/
├── x-media/                        ← Wurzelordner für x-media-Projekte (neu zu schaffen)
│   ├── CLAUDE.md                   (diese Datei)
│   ├── README.md
│   ├── crm/                        (Git-Repo)
│   ├── website-xmedia24/           (Git-Repo)
│   ├── website-oktoberfestbands24/ (Git-Repo, neu)
│   ├── website-partybands24/       (Git-Repo, neu)
│   ├── creative-studio/            (Git-Repo, neu)
│   ├── buchhaltungsassistent/      (Git-Repo, neu)
│   ├── n8n-workflows/              (Git-Repo, neu — JSON-Backups)
│   ├── shared/                     (gemeinsame Konventionen, Snippets)
│   └── docs/                       (übergreifende Doku, SEO-Strategie)
│
└── BREVO-Account/                  ← bereits vorhanden! (siehe Hinweis unten)
    ├── workflow_brevo_insert.json
    ├── workflow_brevo_update.json
    ├── _import_*.py                (Import-Skripte)
    ├── _repair_*.py                (Repair-Tools)
    ├── _diag_*.py                  (Diagnose)
    ├── _fix_*.py                   (Fix-Skripte)
    └── newsletter_die_neue_107_7.html
```

**Hinweis zum BREVO-Account-Ordner:** Der lag schon vor der Reorganisation in `~/Documents/Claude/Projects/` — das macht ihn zum perfekten Vorbild. Bei der Migration belassen wir ihn dort, ergänzen aber zwei Dinge: (a) eine eigene `CLAUDE.md` im Ordner, (b) Git-Initialisierung + eigenes privates GitHub-Repo `x-media-music/xmedia-brevo`. Ob er später unter `x-media/brevo-account/` mit-einsortiert oder als Geschwister-Ordner bleibt, entscheiden wir gemeinsam.

### Dropbox (bleibt für nicht-Code)

```
~/Library/CloudStorage/Dropbox/x-media MUSIC GmbH/
├── Buchhaltung/                    (Belege, PDFs, Scans)
├── Verträge/
├── Marketing/                      (Bilder, Assets)
├── Designvorlagen/
└── [die alten Website/, Buchhaltungsassisitent/, Content Creator/]
    └── ↑ reines Backup, nicht mehr aktiv ändern
```

> **CRM/ gibt es hier seit dem 25.08.2026 nicht mehr.** Der Ordner wurde stillgelegt und gelöscht,
> weil dort trotz gegenteiliger Regel weitergearbeitet wurde und dadurch der Live-Stand
> 3½ Monate ohne Sicherung blieb. Das CRM lebt ausschließlich in `x-media/crm/` (Zweig `main`).
> `API-KEYS.md` liegt seit 01.07.2026 in `x-media/API-KEYS.md`, nicht mehr in Dropbox.

### Cloud-Services

| Service | URL | Zweck |
|---|---|---|
| Supabase (Hauptprojekt) | `vrntqlmrxlbnhetskwjw.supabase.co` | CRM + Website + Creative Studio |
| Supabase (Buchhaltung) | `hsvpjtpzsnfdpibdkxut.supabase.co` | Buchhaltungsassistent |
| n8n VPS | `n8n.srv1596684.hstgr.cloud` | 13 Workflows (SMTP/IMAP/Webhooks + Brevo-Sync) |
| Hostinger Shared | `u666011067` | CRM, Landingpages, Buchhaltung |
| Hostinger JS Hosting | (Domain `xmedia24.com`) | Next.js Website |
| Hostinger VPS | `srv1596684.hstgr.cloud` | n8n-Server |
| GitHub | `github.com/x-media-music` | alle Repos |
| Strato | — | DNS für xmedia24.com, SMTP/IMAP |
| Brevo | `app.brevo.com` (Account `info@xmedia24.com`, User-ID 10812187) | E-Mail-Marketing, Newsletter, produktiv |

---

## Welcher Skill für was

Wenn Claude an einem Projekt arbeitet, sollten zusätzlich zu dieser Datei diese Skills geladen werden:

| Arbeit an … | Primärer Skill | Hilfsskills |
|---|---|---|
| CRM-Frontend | `xmedia-crm` | `crm-architektur`, `crm-api-verbindungen` |
| Datenbank-Schema | passende `crm-*`-Skills (anfragen/angebote/bands/...) | `crm-architektur` |
| n8n-Workflows | `xmedia-n8n` | `crm-n8n-verbindungen`, `n8n-workflow-patterns`, `n8n-code-javascript` |
| Website xmedia24.com | `xmedia-website` | `crm-api-verbindungen` |
| Landingpages | `xmedia-website` (als Vorlage) | `xmedia-crm` für CRM-Anbindung |
| Buchhaltung | `buchhaltungsassistent` | `xmedia-n8n` |
| Bilder/Video-AI | `content-creator` | — |
| **Newsletter / Brevo / Massen-Mails** | **`xmedia-brevo`** | `xmedia-n8n` (für Sync-Workflows), `crm-veranstalter` (Datenquelle) |
| Geschäftsmail-Versand aus CRM | `crm-email-kampagnen` (EmailSendView bleibt aktiv) | `xmedia-crm` |
| Band-Exposés | `band-expose-generator` | `xmedia-crm` |
| **Hofbräu-Regiment-Site** (`hofbraeu-regiment.de`) | **`xmedia-hofbraeu-regiment`** | `xmedia-website` (Pattern-Vorlage), `xmedia-brevo` (DOI-Liste 8), `crm-anfragen` (Datenfluss) |
| **VIPS-Partyband-Migration** | `xmedia-hofbraeu-regiment` (als Vorlage) + `VIPS-PARTYBAND-Blueprint.md` | `xmedia-website`, `xmedia-brevo` |
| SEO | `marketing:seo-audit` (allgemein) | — |

### ⚠️ Veraltete Skills (nicht mehr verwenden)

| Skill | Status | Anmerkung |
|---|---|---|
| `xmedia-newsletter-project` | **ZUR LÖSCHUNG** (Dirk, 03.09.2026) | Konzept vom 15.03.2026, inzwischen über Brevo umgesetzt (`xmedia-brevo`). Skill soll entfernt werden. |
| `crm-newsletter` | **ZUR LÖSCHUNG** (Dirk, 03.09.2026) | CRM-interner MJML-Block-Editor, wird nicht mehr genutzt. Newsletter laufen über Brevo. Skill soll entfernt werden, ebenso n8n-Workflow 07 `0JPdCeB5extwHsDQ`. |

---

## Offene Themen (technische Schulden)

Diese Punkte sind nicht akut blockierend, sollten aber bei Gelegenheit angegangen werden:

1. ~~**`xmedia-n8n` Skill ist hier veraltet**~~ — **ERLEDIGT 03.09.2026.** Der Vorwurf traf nicht zu; der Skill war korrekt. Überarbeitet wurden stattdessen: n8n-Cloud-Abo gekündigt (Rollback-Abschnitt neu), Dropbox-Pfade, doppelte Kapitelnummer. **Offen: der Skill muss noch neu installiert werden** (`crm-rebuild/skills/xmedia-n8n/INSTALL.md`), sonst läuft die alte Fassung weiter.
2. **DNS-Records für xmedia24.com:** Aktueller Stand laut `xmedia-brevo/references/senders-and-dns.md` prüfen (Brevo erzwingt DKIM/SPF, hat möglicherweise schon eingerichtet). Falls dort dokumentiert: aus dieser Liste streichen.
3. **n8n Service Role Keys hardcoded** in Workflow-Nodes statt als Credentials — bei Rotation aufwendig.
4. **Hostinger-MCP** in Cowork registriert, aber Actions nicht aktiviert.
5. **Authentifizierung im CRM** noch offen (Supabase Auth geplant).
6. **Code-Aufräumen im CRM:** `NewsletterEditorView` und zugehörige Tabellen (`newsletter_templates`) sind im Code, werden aber nicht mehr genutzt. Optional bei nächster größerer Überarbeitung entfernen.
7. **Brevo-Projekt versionieren:** Aktuell nicht in Git. Bei Phase 2 der Migration: privates Repo `x-media-music/xmedia-brevo` anlegen (Workflow-JSONs und Python-Skripte; Newsletter-HTMLs nach Bedarf).
8. **Brevo Phase D:** Webhook-Receiver Brevo → CRM (Bounces, Unsubscribes setzen `newsletter_opt_in=false`). Konzept steht in `xmedia-brevo/references/n8n-sync-workflows.md`.

---

## Verweise

- **Detail-Bestandsaufnahme:** `~/Documents/claude/Projects/x-media/docs/bestandsaufnahme-2026-05.md`
- **Skill-Verzeichnis:** in Claude über `mcp__skills__list_skills`
- **Credentials:** `~/Documents/Claude/Projects/x-media/API-KEYS.md` (x-media Root, außerhalb aller Git-Repos)
- **Hofbräu-Regiment-Site (neu, Next.js):**
  - Master-Doku: `~/Documents/Claude/Projects/hofbraeu-regiment 2026/PROJEKT-DOKUMENTATION.md`
  - VIPS-Blueprint: `~/Documents/Claude/Projects/hofbraeu-regiment 2026/VIPS-PARTYBAND-Blueprint.md`
  - API-Zugänge & MCP: `~/Documents/Claude/Projects/hofbraeu-regiment 2026/API-ZUGAENGE-UND-MCP.md`
  - Skill-Datei (zur Installation): `~/Documents/Claude/Projects/hofbraeu-regiment 2026/skills/xmedia-hofbraeu-regiment/SKILL.md`
  - Konzept-Phasen: `KONZEPT-Phase1.md`, `KONZEPT-Phase2-Praezisierungen.md` (im selben Ordner)
  - Decommissioning-Plan: `DECOMMISSIONING-Runbook.md` (für Cutover-Tag)

---

## Persönliche Werkzeuge (nicht x-media)

- **Video-Verstehen-Werkzeug** — Claude kann Videos „anschauen" (Frames + Transkript).
  Aufruf in jeder Sitzung, auch in Cowork:
  ```
  bash ~/Documents/Claude/Projects/tools/claude-video/watch.sh "<URL-oder-Dateipfad>"
  ```
  Danach die ausgegebenen `frame_*.jpg` mit dem Read-Tool öffnen + Transkript lesen.
  Details/Optionen/Whisper-Key: `~/Documents/Claude/Projects/tools/claude-video/ANLEITUNG.md`.
  Voraussetzung: lokale Sitzung auf Dirks Mac (ffmpeg/yt-dlp via Homebrew installiert).

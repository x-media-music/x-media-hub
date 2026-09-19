# x-media Projekte — Wurzelordner

Dies ist der zentrale Arbeitsordner für alle Code-Projekte von **x-media music GmbH** und **x-media event GmbH**.

## Quickstart für Claude (Code, Cowork, VS Code)

1. Lies zuerst [`CLAUDE.md`](./CLAUDE.md) — das ist die Landkarte des gesamten Ökosystems.
2. Wechsle in das Unterprojekt, an dem du arbeitest (z. B. `cd crm/`).
3. Lies dessen `CLAUDE.md`, falls vorhanden — sie ergänzt die Master-Datei mit projektspezifischen Hinweisen.
4. Bei Bedarf den passenden Skill laden (siehe Skill-Tabelle in der Master-CLAUDE.md).

## Quickstart für Dirk (neuer Mac)

```bash
# 1. Repos parallel klonen (ein Befehl)
cd ~/Documents/Claude/Projects/x-media
git clone https://github.com/x-media-music/xmedia-crm.git crm
git clone https://github.com/x-media-music/xmedia24-website.git website-xmedia24

# 2. API-KEYS per relativem Symlink ins CRM (NICHT aus Dropbox!)
cd ~/Documents/Claude/Projects/x-media/crm && ln -s ../API-KEYS.md API-KEYS.md && cd ..

# 3. Fertig — testen, dass alles da ist
ls crm/ website-xmedia24/
```

## Wichtige Regeln

- **Code lebt hier**, nicht in Dropbox. Der frühere CRM-Ordner in Dropbox wurde am 25.08.2026 stillgelegt und gelöscht.
- **Dokumente, Verträge, Belege, Marketing-Assets bleiben in Dropbox.**
- **Credentials niemals committen.** Siehe Goldene Regeln in der Master-CLAUDE.md.
- **Live-Systeme (CRM, n8n) niemals direkt ändern** — alles über Git + Deploy-Skripte.

## Status

Diese Ordnerstruktur ist im Aufbau. Stand 23.05.2026: nur Master-Doku und README. Repos werden in Phase A der Migration geklont (siehe `docs/migrations-plan.md` — kommt noch).

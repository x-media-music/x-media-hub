// =====================================================================
//  CRM-Datenbank sichern  —  liest alle Tabellen über die Supabase-REST-
//  Schnittstelle und legt sie als JSON ab. Kein Passwort nötig: der
//  Service-Key wird zur Laufzeit aus API-KEYS.md gelesen und nirgends
//  gespeichert. Es werden nur Daten GELESEN.
//  Nicht enthalten: Dateien im Storage (PDFs, Bilder).
// =====================================================================
import { readFileSync, mkdirSync, writeFileSync, readdirSync, rmSync, existsSync } from "node:fs";
import { join } from "node:path";

const KEYS  = process.env.CRM_KEYS_MD || "/Users/dirkwoehrle/Documents/Claude/Projects/x-media/API-KEYS.md";
const ZIEL  = process.env.CRM_DB_ZIEL || "/Users/dirkwoehrle/Documents/Claude/Projects/x-media/_DB-Sicherung";
const STAENDE = 7;

if (!existsSync(KEYS)) { console.error("FEHLER: API-KEYS.md nicht gefunden:", KEYS); process.exit(1); }
const md = readFileSync(KEYS, "utf8");
const block = md.split(/^## /m).find(s => s.startsWith("Supabase (Primary"));
if (!block) { console.error("FEHLER: Abschnitt 'Supabase (Primary Database + Storage)' nicht gefunden."); process.exit(1); }
const url = (block.match(/Project URL:\*\*\s*(\S+)/) || [])[1];
const key = (block.match(/Service Role Key:\*\*\s*`([^`]+)`/) || [])[1];
if (!url || !key) { console.error("FEHLER: Project URL oder Service Role Key nicht lesbar."); process.exit(1); }

const H = { apikey: key, Authorization: `Bearer ${key}` };
const tag = new Date().toISOString().slice(0, 10);
const ordner = join(ZIEL, tag);
mkdirSync(ordner, { recursive: true });

const spec = await (await fetch(`${url}/rest/v1/`, { headers: H })).json();
const tabellen = Object.keys(spec.definitions || spec.components?.schemas || {}).sort();
if (!tabellen.length) { console.error("FEHLER: Keine Tabellen gefunden."); process.exit(1); }
console.log(`${tabellen.length} Tabellen gefunden.`);

let zeilenGesamt = 0, fehler = 0;
for (const t of tabellen) {
  const alle = [];
  for (let von = 0; ; von += 1000) {
    const r = await fetch(`${url}/rest/v1/${t}?select=*`, {
      headers: { ...H, Range: `${von}-${von + 999}`, "Range-Unit": "items" },
    });
    if (!r.ok) { console.log(`  ⚠️  ${t}: ${r.status}`); fehler++; break; }
    const teil = await r.json();
    alle.push(...teil);
    if (teil.length < 1000) break;
  }
  writeFileSync(join(ordner, `${t}.json`), JSON.stringify(alle, null, 1));
  zeilenGesamt += alle.length;
  console.log(`  · ${t}: ${alle.length}`);
}

writeFileSync(join(ordner, "_INFO.txt"),
  `CRM-Datenbanksicherung ${new Date().toISOString()}\n` +
  `Projekt: ${url}\nTabellen: ${tabellen.length}\nZeilen gesamt: ${zeilenGesamt}\n` +
  `Fehlgeschlagene Tabellen: ${fehler}\n\nNicht enthalten: Storage-Dateien (PDFs, Bilder).\n`);

// --- alte Stände aufräumen ---
const staende = readdirSync(ZIEL).filter(d => /^\d{4}-\d{2}-\d{2}$/.test(d)).sort();
for (const alt of staende.slice(0, Math.max(0, staende.length - STAENDE))) {
  rmSync(join(ZIEL, alt), { recursive: true, force: true });
  console.log(`  (alter Stand entfernt: ${alt})`);
}

console.log(`\nFERTIG: ${zeilenGesamt} Zeilen in ${ordner}`);
if (fehler > 0) process.exit(2);

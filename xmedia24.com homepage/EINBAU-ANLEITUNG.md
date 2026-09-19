# Referenzen-Seite für xmedia24.com – Einbau-Anleitung

Die Seite zeigt **exakt die gleiche Referenzliste** wie hofbraeu-regiment.de/referenzen.
Beide Sites lesen dieselbe Supabase-Tabelle `hofbraeu_referenzen` (85 aktive Einträge,
5 Kategorien) im selben Projekt `vrntqlmrxlbnhetskwjw`. Die RLS-Policy
`hofbraeu_referenzen_anon_read` erlaubt öffentliches Lesen – der Anon-Key reicht.
Wenn du auf der HBR-Seite eine Referenz änderst, ändert sie sich also automatisch auch
hier (nach spätestens 1 h, wegen ISR `revalidate = 3600`).

Das Design ist auf x-media umgestellt: Orange `#fc6000`, Inter, dunkler Hero, weiße Karten,
graue Abschluss-CTA. Nav und Footer kommen automatisch aus dem Root-Layout.

## 1. Seite anlegen

Datei `referenzen-page.tsx` umbenennen und ablegen als:

```
src/app/referenzen/page.tsx
```

Keine weiteren Imports/Pakete nötig – `@supabase/supabase-js` ist bereits Dependency.

## 2. Footer verlinken

In `src/components/Footer.tsx`, in der Spalte **Navigation**, direkt nach dem
Musikagentur-Link ergänzen:

```tsx
<li>
  <Link href="/referenzen">Referenzen</Link>
</li>
```

Die aktuelle Reihenfolge dort ist: Musikagentur · Management · Musikverlag ·
Unsere Künstler · Termine/Tickets · Veranstalter-Anfrage. „Referenzen" kommt
direkt hinter „Musikagentur".

## 3. Menü verlinken (Empfehlung: unter „Musikagentur")

In `src/components/Navigation.tsx` „Referenzen" **direkt nach „Musikagentur"**
einfügen (also zwischen Musikagentur und Management):

```tsx
<Link href="/referenzen">Referenzen</Link>
```

Aktuelle Hauptnavigation:
`Start · Veranstalter-Anfrage · Musikagentur · [Referenzen] · Management · Musikverlag · Künstler · Termine/Tickets · Kontakt`

Falls das mobile Menü dieselbe Link-Liste nutzt, dort ebenfalls ergänzen.

## 4. Sitemap (optional, empfohlen)

In `src/app/sitemap.ts` `/referenzen` zu den statischen Routen hinzufügen, damit
Google die Seite sicher findet.

## 5. Deploy

Committen + pushen wie gewohnt (GitHub `main` → Hostinger baut automatisch). Danach prüfen:
`https://www.xmedia24.com/referenzen`.

---

## Menü-Platzierung – meine Empfehlung

**Unter „Musikagentur" einordnen** (deine Wahl) ist inhaltlich am stimmigsten:
Referenzen sind der Beleg für die Agentur-Kompetenz und gehören direkt neben die
Musikagentur-Seite. Zwei saubere Varianten:

1. **Eigener Top-Level-Punkt direkt hinter „Musikagentur"** (einfachste, in dieser
   Anleitung umgesetzte Lösung). Vorteil: 1 Klick, keine Dropdown-Mechanik nötig.
2. **Als Dropdown-Unterpunkt unter „Musikagentur"** (Musikagentur → Referenzen).
   Sauberer, wenn du die Top-Leiste schlank halten willst – erfordert aber ein
   Dropdown, das die aktuelle Navigation noch nicht hat.

Empfehlung: Variante 1 jetzt, weil sie ohne Umbau der Navigation auskommt und die
Seite sofort sichtbar ist. Wenn die Menüleiste zu voll wird, später auf ein
„Musikagentur"-Dropdown (Variante 2) umstellen.

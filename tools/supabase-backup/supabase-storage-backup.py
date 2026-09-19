#!/usr/bin/env python3
"""Sichert alle Dateien aus den Storage-Buckets eines Supabase-Projekts.
Aufruf:  SUPABASE_ACCESS_TOKEN=sbp_... python3 supabase-storage-backup.py <project-ref> <zielordner>
Holt den service_role-Key selbst ueber die Management-API - kein Key im Skript.
Bereits vorhandene, gleich grosse Dateien werden uebersprungen (inkrementell).
"""
import json, os, sys, urllib.request, urllib.parse, datetime

TOKEN = os.environ["SUPABASE_ACCESS_TOKEN"]
REF = sys.argv[1]
OUT = sys.argv[2]
HDR = {"Authorization": f"Bearer {TOKEN}", "User-Agent": "curl/8.0", "Accept": "*/*"}


def api(path, data=None):
    req = urllib.request.Request(
        f"https://api.supabase.com/v1{path}",
        data=json.dumps(data).encode() if data is not None else None,
        headers={**HDR, "Content-Type": "application/json"},
        method="POST" if data is not None else "GET")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


keys = api(f"/projects/{REF}/api-keys?reveal=true")
SRK = next(k["api_key"] for k in keys if k.get("name") == "service_role")
BASE = f"https://{REF}.supabase.co/storage/v1"
SH = {"Authorization": f"Bearer {SRK}", "apikey": SRK, "User-Agent": "curl/8.0"}


def storage(path, data=None):
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(data).encode() if data is not None else None,
        headers={**SH, "Content-Type": "application/json"},
        method="POST" if data is not None else "GET")
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read())


def walk(bucket, prefix=""):
    """Listet einen Bucket rekursiv."""
    out = []
    offset = 0
    while True:
        items = storage(f"/object/list/{bucket}", {
            "prefix": prefix, "limit": 1000, "offset": offset,
            "sortBy": {"column": "name", "order": "asc"}})
        if not items:
            break
        for it in items:
            name = f"{prefix}{it['name']}"
            if it.get("id") is None:              # Ordner
                out.extend(walk(bucket, name + "/"))
            else:
                out.append((name, (it.get("metadata") or {}).get("size", 0)))
        if len(items) < 1000:
            break
        offset += len(items)
    return out


total_files = total_bytes = skipped = 0
report = []
for b in storage("/bucket"):
    bucket = b["name"]
    files = walk(bucket)
    report.append((bucket, len(files), sum(s for _, s in files)))
    for name, size in files:
        dest = os.path.join(OUT, bucket, name)
        if os.path.exists(dest) and os.path.getsize(dest) == size:
            skipped += 1
            continue
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        req = urllib.request.Request(f"{BASE}/object/{bucket}/{urllib.parse.quote(name)}", headers=SH)
        try:
            with urllib.request.urlopen(req, timeout=180) as r, open(dest, "wb") as f:
                f.write(r.read())
            total_files += 1
            total_bytes += size
        except Exception as e:
            print(f"  FEHLER {bucket}/{name}: {e}")

os.makedirs(OUT, exist_ok=True)
with open(os.path.join(OUT, "MANIFEST.txt"), "w") as f:
    f.write(f"Storage-Sicherung Projekt {REF}\n")
    f.write(f"Erzeugt: {datetime.datetime.now():%d.%m.%Y %H:%M}\n\n")
    f.write("Bucket                 Objekte        Bytes\n" + "-" * 44 + "\n")
    for b, n, s in report:
        f.write(f"{b:<22} {n:>7} {s:>12,}\n")
    f.write("-" * 44 + "\n")
    f.write(f"{'SUMME':<22} {sum(n for _, n, _ in report):>7} {sum(s for _, _, s in report):>12,}\n")

print(f"neu geladen: {total_files} Dateien ({total_bytes:,} Bytes), unveraendert uebersprungen: {skipped}")
for b, n, s in report:
    print(f"  {b}: {n} Objekte, {s:,} Bytes")

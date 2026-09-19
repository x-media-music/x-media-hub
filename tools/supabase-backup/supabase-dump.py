#!/usr/bin/env python3
"""Logischer Dump eines Supabase-Projekts ueber die Management-API.
Erzeugt: schema.sql (DDL), data.sql (INSERTs), <tabelle>.json (Rohdaten), MANIFEST.txt
Braucht kein Datenbank-Passwort - nur den Management-Token.
"""
import json, os, sys, urllib.request, datetime, decimal

TOKEN = os.environ["SUPABASE_ACCESS_TOKEN"]

def q(ref, sql):
    req = urllib.request.Request(
        f"https://api.supabase.com/v1/projects/{ref}/database/query",
        data=json.dumps({"query": sql}).encode(),
        headers={"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json",
                 "User-Agent": "curl/8.0", "Accept": "*/*"},
        method="POST")
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read())

def lit(v):
    if v is None: return "NULL"
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, (int, float, decimal.Decimal)): return str(v)
    if isinstance(v, (dict, list)):
        return "'" + json.dumps(v, ensure_ascii=False).replace("'", "''") + "'"
    return "'" + str(v).replace("'", "''") + "'"

def dump(ref, name, outdir):
    os.makedirs(outdir, exist_ok=True)
    tables = [r["table_name"] for r in q(ref,
        "select table_name from information_schema.tables "
        "where table_schema='public' and table_type='BASE TABLE' order by table_name")]

    schema = [f"-- Schema-Dump {name} ({ref})",
              f"-- erzeugt {datetime.datetime.now():%d.%m.%Y %H:%M}",
              "-- Quelle: Supabase Management API (information_schema + pg_catalog)",
              "", "SET client_min_messages = warning;", ""]

    # --- Sequenzen ---
    seqs = q(ref, "select sequence_name from information_schema.sequences where sequence_schema='public' order by 1")
    if seqs:
        schema.append("-- Sequenzen")
        for s in seqs:
            schema.append(f'CREATE SEQUENCE IF NOT EXISTS public."{s["sequence_name"]}";')
        schema.append("")

    # --- Tabellen ---
    for t in tables:
        cols = q(ref, f"""select column_name, data_type, udt_name, character_maximum_length,
                 numeric_precision, numeric_scale, is_nullable, column_default
                 from information_schema.columns
                 where table_schema='public' and table_name='{t}' order by ordinal_position""")
        lines = []
        for c in cols:
            dt = c["data_type"]
            if dt == "USER-DEFINED":
                dt = c["udt_name"]
            elif dt == "ARRAY":
                dt = c["udt_name"].lstrip("_") + "[]"
            elif dt in ("character varying", "character") and c["character_maximum_length"]:
                dt += f'({c["character_maximum_length"]})'
            elif dt == "numeric" and c["numeric_precision"]:
                dt += f'({c["numeric_precision"]},{c["numeric_scale"] or 0})'
            s = f'  "{c["column_name"]}" {dt}'
            if c["column_default"]: s += f' DEFAULT {c["column_default"]}'
            if c["is_nullable"] == "NO": s += " NOT NULL"
            lines.append(s)
        schema.append(f'CREATE TABLE IF NOT EXISTS public."{t}" (')
        schema.append(",\n".join(lines))
        schema.append(");\n")

    # --- Constraints (PK, FK, UNIQUE, CHECK) ---
    cons = q(ref, """select rel.relname as tbl, con.conname as name,
             pg_get_constraintdef(con.oid) as def, con.contype
             from pg_constraint con join pg_class rel on rel.oid=con.conrelid
             join pg_namespace n on n.oid=rel.relnamespace
             where n.nspname='public' order by con.contype, rel.relname""")
    if cons:
        schema.append("-- Constraints")
        for c in cons:
            schema.append(f'ALTER TABLE public."{c["tbl"]}" ADD CONSTRAINT "{c["name"]}" {c["def"]};')
        schema.append("")

    # --- Indizes (ohne die, die schon durch Constraints entstehen) ---
    idx = q(ref, """select indexdef from pg_indexes where schemaname='public'
            and indexname not in (select conname from pg_constraint) order by indexname""")
    if idx:
        schema.append("-- Indizes")
        for i in idx:
            schema.append(i["indexdef"] + ";")
        schema.append("")

    # --- Views ---
    views = q(ref, "select table_name, view_definition from information_schema.views where table_schema='public' order by 1")
    if views:
        schema.append("-- Views")
        for v in views:
            schema.append(f'CREATE OR REPLACE VIEW public."{v["table_name"]}" AS\n{v["view_definition"]}\n')

    # --- Funktionen ---
    fns = q(ref, """select pg_get_functiondef(p.oid) as def from pg_proc p
            join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'
            and p.prokind in ('f','p') order by p.proname""")
    if fns:
        schema.append("-- Funktionen")
        for f in fns:
            schema.append(f["def"] + ";\n")

    # --- Trigger ---
    trg = q(ref, """select pg_get_triggerdef(t.oid) as def from pg_trigger t
            join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace
            where n.nspname='public' and not t.tgisinternal order by t.tgname""")
    if trg:
        schema.append("-- Trigger")
        for t_ in trg:
            schema.append(t_["def"] + ";")
        schema.append("")

    # --- RLS + Policies ---
    rls = q(ref, "select relname from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relrowsecurity")
    pol = q(ref, """select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
            from pg_policies where schemaname='public' order by tablename, policyname""")
    if rls or pol:
        schema.append("-- Row Level Security")
        for r in rls:
            schema.append(f'ALTER TABLE public."{r["relname"]}" ENABLE ROW LEVEL SECURITY;')
        for p in pol:
            roles = ", ".join(p["roles"]) if isinstance(p["roles"], list) else str(p["roles"]).strip("{}")
            s = f'CREATE POLICY "{p["policyname"]}" ON public."{p["tablename"]}"'
            s += f' AS {p["permissive"]} FOR {p["cmd"]} TO {roles}'
            if p["qual"]: s += f' USING ({p["qual"]})'
            if p["with_check"]: s += f' WITH CHECK ({p["with_check"]})'
            schema.append(s + ";")
        schema.append("")

    with open(f"{outdir}/schema.sql", "w") as f:
        f.write("\n".join(schema))

    # --- Daten ---
    data = [f"-- Daten-Dump {name} ({ref})",
            f"-- erzeugt {datetime.datetime.now():%d.%m.%Y %H:%M}", "", "BEGIN;", ""]
    manifest = []
    for t in tables:
        rows = q(ref, f'select * from public."{t}"')
        with open(f"{outdir}/{t}.json", "w") as f:
            json.dump(rows, f, ensure_ascii=False, indent=1, default=str)
        manifest.append((t, len(rows)))
        if not rows:
            data.append(f"-- {t}: leer\n"); continue
        cols = list(rows[0].keys())
        collist = ", ".join(f'"{c}"' for c in cols)
        data.append(f"-- {t}: {len(rows)} Zeilen")
        for i in range(0, len(rows), 100):
            chunk = rows[i:i+100]
            vals = ",\n  ".join("(" + ", ".join(lit(r.get(c)) for c in cols) + ")" for r in chunk)
            data.append(f'INSERT INTO public."{t}" ({collist}) VALUES\n  {vals}\nON CONFLICT DO NOTHING;')
        data.append("")
    data.append("COMMIT;")
    with open(f"{outdir}/data.sql", "w") as f:
        f.write("\n".join(data))

    with open(f"{outdir}/MANIFEST.txt", "w") as f:
        f.write(f"Projekt : {name}\nRef     : {ref}\n")
        f.write(f"Erzeugt : {datetime.datetime.now():%d.%m.%Y %H:%M}\n")
        f.write("Methode : Supabase Management API (logischer Dump, kein pg_dump)\n\n")
        f.write("Tabelle                          Zeilen\n")
        f.write("-" * 42 + "\n")
        for t, n in manifest:
            f.write(f"{t:<32} {n:>6}\n")
        f.write("-" * 42 + "\n")
        f.write(f"{'SUMME':<32} {sum(n for _, n in manifest):>6}\n\n")
        f.write("Wiederherstellen:\n  psql <ziel-db> -f schema.sql\n  psql <ziel-db> -f data.sql\n")
    return manifest

if __name__ == "__main__":
    for ref, name, out in [
        ("hsvpjtpzsnfdpibdkxut", "Buchhaltungsassistent", sys.argv[1] + "/buchhaltungsassistent"),
        ("rnztxhbsccnldagxjryt", "musiker-gesucht", sys.argv[1] + "/musiker-gesucht"),
    ]:
        m = dump(ref, name, out)
        print(f"{name}: {len(m)} Tabellen, {sum(n for _, n in m)} Zeilen -> {out}")

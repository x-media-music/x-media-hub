// src/app/referenzen/page.tsx
// Referenzen-Seite für xmedia24.com
// Liest die identische Referenzliste aus der gemeinsamen Supabase-Tabelle
// `hofbraeu_referenzen` (RLS-Policy hofbraeu_referenzen_anon_read erlaubt
// öffentlichen Lesezugriff auf ist_aktiv = true) und stellt sie im
// x-media-Design dar. Nav + Footer kommen automatisch aus dem Root-Layout.

import type { Metadata } from "next";
import Link from "next/link";
import { createClient } from "@supabase/supabase-js";

export const revalidate = 3600;

export const metadata: Metadata = {
  title: "Referenzen – Firmen, Sport & Volksfeste | x-media Musikagentur",
  description:
    "Auszug unserer Referenzen: Firmen-Events für Mercedes-Benz, Porsche, Bosch und Allianz, Sport-Highlights wie das DFB-Pokalfinale sowie Bierzelt-Klassiker wie das Cannstatter Volksfest. Über 20 Jahre Erfahrung als Musikagentur in Süddeutschland.",
  alternates: { canonical: "https://www.xmedia24.com/referenzen" },
  openGraph: {
    title: "Referenzen | x-media Musikagentur",
    description:
      "Firmen, Sport, Bierzelt & Stadtfeste – ein Auszug der Veranstaltungen, die wir mit unseren Bands und Künstlern begleitet haben.",
    url: "https://www.xmedia24.com/referenzen",
    type: "website",
  },
  robots: { index: true, follow: true },
};

type Referenz = {
  id: number;
  kategorie: string;
  kunde: string;
  jahre: string | null;
  location: string | null;
  sort_order: number | null;
  ist_aktiv: boolean | null;
};

// Anzeige-Reihenfolge + Überschriften der Kategorien (identisch zur HBR-Seite)
const KATEGORIEN: { key: string; label: string }[] = [
  { key: "firmen", label: "Firmen & Sport" },
  { key: "fernsehen", label: "Fernsehauftritte" },
  { key: "bierzelt", label: "Bierzelt & Volksfest" },
  { key: "halle", label: "Hallenveranstaltungen" },
  { key: "stadtfest", label: "Stadtfeste & Open Air" },
];

async function getReferenzen(): Promise<Referenz[]> {
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    { auth: { persistSession: false } }
  );

  const { data, error } = await supabase
    .from("hofbraeu_referenzen")
    .select("id, kategorie, kunde, jahre, location, sort_order, ist_aktiv")
    .eq("ist_aktiv", true)
    .order("sort_order", { ascending: true });

  if (error) {
    console.error("Referenzen laden fehlgeschlagen:", error.message);
    return [];
  }
  return (data ?? []) as Referenz[];
}

export default async function ReferenzenPage() {
  const alle = await getReferenzen();

  const gruppen = KATEGORIEN.map((kat) => ({
    ...kat,
    eintraege: alle.filter((r) => r.kategorie === kat.key),
  })).filter((g) => g.eintraege.length > 0);

  return (
    <main className="bg-white">
      {/* Hero */}
      <section className="relative overflow-hidden bg-[#191919] text-white">
        <div
          className="pointer-events-none absolute inset-0 opacity-40"
          style={{
            background:
              "radial-gradient(circle at 20% 20%, rgba(252,96,0,0.35), transparent 45%)",
          }}
        />
        <div className="relative mx-auto max-w-6xl px-4 py-20 md:py-28">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-[#fc6000]">
            Auszug unserer Referenzen
          </p>
          <h1 className="mt-4 text-4xl font-bold leading-tight md:text-6xl">
            Referenzen
          </h1>
          <p className="mt-6 max-w-2xl text-lg text-white/80">
            Von Firmen-Events für Mercedes-Benz, Porsche und Bosch über
            Sport-Highlights wie das DFB-Pokalfinale bis zu Bierzelt-Klassikern
            wie dem Cannstatter Volksfest – ein Auszug der Veranstaltungen, die
            wir mit unseren Bands und Künstlern begleiten durften.
          </p>
          <Link
            href="/veranstalter-anfrage"
            className="mt-8 inline-block rounded-md border-2 border-[#fc6000] bg-[#fc6000] px-7 py-3 font-semibold text-white transition-colors hover:bg-white hover:text-[#fc6000]"
          >
            Jetzt unverbindlich anfragen
          </Link>
        </div>
      </section>

      {/* Kategorien */}
      <div className="mx-auto max-w-6xl px-4 py-16 md:py-20">
        {gruppen.map((gruppe) => (
          <section key={gruppe.key} className="mb-16 last:mb-0">
            <div className="mb-8">
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#fc6000]">
                Auszug
              </p>
              <h2 className="mt-2 text-2xl font-bold text-[#191919] md:text-3xl">
                {gruppe.label}
              </h2>
            </div>

            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {gruppe.eintraege.map((ref) => (
                <article
                  key={ref.id}
                  className="rounded-xl border border-black/10 bg-white p-5 shadow-sm transition-all hover:-translate-y-0.5 hover:border-[#fc6000]/50 hover:shadow-md"
                >
                  <h3 className="font-semibold leading-snug text-[#191919]">
                    {ref.kunde}
                  </h3>
                  {ref.jahre && (
                    <p className="mt-2 text-sm font-medium text-[#fc6000]">
                      {ref.jahre}
                    </p>
                  )}
                  {ref.location && (
                    <p className="mt-0.5 text-sm text-[#747474]">
                      {ref.location}
                    </p>
                  )}
                </article>
              ))}
            </div>
          </section>
        ))}

        <p className="mt-12 text-sm text-[#747474]">
          Dies ist ein Auszug – nicht jede Veranstaltung ist dokumentiert. Ihre
          Veranstaltung ist noch nicht dabei?{" "}
          <Link
            href="/veranstalter-anfrage"
            className="font-medium text-[#fc6000] hover:underline"
          >
            Anfrage stellen →
          </Link>
        </p>
      </div>

      {/* Abschluss-CTA */}
      <section className="bg-[#f5f5f5]">
        <div className="mx-auto max-w-6xl px-4 py-16 text-center md:py-20">
          <h2 className="text-2xl font-bold text-[#191919] md:text-3xl">
            Ihr Event auf dieser Liste?
          </h2>
          <p className="mx-auto mt-4 max-w-2xl text-[#747474]">
            Von der Firmenfeier bis zum großen Festzelt – wir finden den
            passenden Act für Ihre Veranstaltung und kalkulieren transparent und
            unverbindlich nach Ihrer Anfrage.
          </p>
          <Link
            href="/veranstalter-anfrage"
            className="mt-8 inline-block rounded-md border-2 border-[#fc6000] bg-[#fc6000] px-7 py-3 font-semibold text-white transition-colors hover:bg-white hover:text-[#fc6000]"
          >
            Unverbindliche Anfrage
          </Link>
        </div>
      </section>
    </main>
  );
}

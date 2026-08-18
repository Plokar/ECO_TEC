import type { Metadata } from "next";
import { CTA, Card, Cloud, Eyebrow, Flower, H2, Lead, Section } from "../_components/brand";

export const metadata: Metadata = {
  title: "For cities",
  description:
    "Anonymised, continuously updated maps of where litter actually accumulates — reported by residents and verified on-device.",
};

const PANELS = [
  {
    title: "Hotspot map",
    body: "Aggregated pins showing where residents keep finding litter, weighted by how much and how often. The bins that need emptying twice as often become obvious.",
    tone: "bg-streak-fire",
  },
  {
    title: "Material breakdown",
    body: "Plastic, glass, metal, paper, cigarettes — per district, over time. Useful for deciding what a deposit scheme or a bin redesign would actually shift.",
    tone: "bg-impact-cyan",
  },
  {
    title: "Participation",
    body: "How many residents are active, in which neighbourhoods, and whether a campaign moved either number.",
    tone: "bg-gold",
  },
  {
    title: "Cleanup events",
    body: "Publish an event to the in-app map and watch attendance and collected volume against it.",
    tone: "bg-quest-green",
  },
  {
    title: "Campaign quests",
    body: "Commission a city-branded quest — a canal stretch, a park, a specific material — and see the response within a day.",
    tone: "bg-duel-violet",
  },
  {
    title: "City-versus-city",
    body: "A public league table. It is, bluntly, the part that gets you press coverage and residents arguing in your favour.",
    tone: "bg-leaf",
  },
];

/// Hotspots on the mock map. Percentages, so the card scales with the layout.
const HOTSPOTS = [
  { x: 22, y: 30, size: "size-10", tone: "bg-streak-fire", delay: "0s" },
  { x: 48, y: 55, size: "size-14", tone: "bg-alert-red", delay: "-1.1s" },
  { x: 70, y: 26, size: "size-8", tone: "bg-gold", delay: "-2.2s" },
  { x: 78, y: 66, size: "size-11", tone: "bg-streak-fire", delay: "-0.6s" },
  { x: 34, y: 74, size: "size-7", tone: "bg-gold", delay: "-1.7s" },
];

export default function Cities() {
  return (
    <>
      <section className="relative overflow-hidden bg-sky">
        <Cloud className="animate-drift absolute left-0 top-16 w-44 text-white/80" />
        <Cloud
          className="animate-drift absolute left-0 top-44 w-28 text-white/60"
          style={{ animationDelay: "-20s", animationDuration: "48s" }}
        />
        <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-6 py-20 sm:py-28 lg:grid-cols-[1fr_0.85fr]">
          <div>
            <Eyebrow tone="bg-impact-cyan">City dashboard</Eyebrow>
            <H2>Where the litter actually is, not where the survey said</H2>
            <Lead>
              Municipal waste data is usually a snapshot, commissioned annually and
              out of date on arrival. EcoQuest produces a continuous one as a side
              effect of people playing a game.
            </Lead>
            <div className="mt-10">
              <CTA href="/about#contact">Request a pilot</CTA>
            </div>
          </div>

          {/* The dashboard, drawn. Hotspots breathe so the card reads as live. */}
          <div className="sticker bg-page p-5" style={{ rotate: "1.5deg" }}>
            <div className="flex items-center justify-between">
              <p className="text-xs font-extrabold tracking-[0.14em] uppercase text-ink-dim">
                Plzeň · last 7 days
              </p>
              <span className="flex items-center gap-1.5 text-[10px] font-extrabold uppercase text-alert-red">
                <span className=" size-2 rounded-full bg-alert-red" />
                live
              </span>
            </div>
            <div className="relative mt-3 h-64 overflow-hidden rounded-2xl border-[3px] border-ink bg-page-subtle">
              <svg viewBox="0 0 300 240" className="absolute inset-0 size-full" aria-hidden="true">
                <rect width="300" height="240" fill="#EAF7EC" />
                <path d="M0 90h300M0 170h300M90 0v240M200 0v240" stroke="#C7DFCD" strokeWidth="10" />
                <path d="M20 240C60 170 120 150 150 90S220 10 300 0" stroke="#BFE8FA" strokeWidth="16" fill="none" />
              </svg>
              {HOTSPOTS.map((spot) => (
                <span
                  key={`${spot.x}-${spot.y}`}
                  className={`animate-bob absolute rounded-full border-[3px] border-ink opacity-80 ${spot.size} ${spot.tone}`}
                  style={{ left: `${spot.x}%`, top: `${spot.y}%`, animationDelay: spot.delay }}
                  aria-hidden="true"
                />
              ))}
            </div>
            <dl className="mt-4 grid grid-cols-3 gap-2 text-center">
              {[
                { v: "1 842", k: "items" },
                { v: "61%", k: "plastic" },
                { v: "312", k: "residents" },
              ].map((cell) => (
                <div key={cell.k} className="rounded-xl border-[3px] border-ink bg-page-subtle py-2">
                  <dt className="display tabular text-lg text-ink">{cell.v}</dt>
                  <dd className="text-[10px] font-extrabold uppercase text-ink-dim">{cell.k}</dd>
                </div>
              ))}
            </dl>
          </div>
        </div>
      </section>

      <Section className="bg-page">
        <div className="reveal">
          <H2>What you see</H2>
        </div>
        <div className="mt-12 grid gap-7 sm:grid-cols-2 lg:grid-cols-3">
          {PANELS.map((card, i) => (
            <div key={card.title} className="reveal">
              <Card className="h-full" tilt={i % 2 ? 1 : -1}>
                <span className={`h-3 w-14 rounded-full border-2 border-ink ${card.tone}`} />
                <h3 className="display mt-4 text-xl text-ink">{card.title}</h3>
                <p className="mt-2 text-sm font-semibold leading-relaxed text-ink-dim">
                  {card.body}
                </p>
              </Card>
            </div>
          ))}
        </div>
      </Section>

      <Section className="bg-page-subtle">
        <div className="grid gap-14 lg:grid-cols-2">
          <div className="reveal">
            <Eyebrow tone="bg-duel-violet">Privacy</Eyebrow>
            <H2>You get the pattern, never the person</H2>
            <Lead>
              This only works if residents trust it, so the dashboard is built to
              make individual identification impossible rather than merely
              discouraged.
            </Lead>
          </div>
          <ul className="reveal flex flex-col gap-4 self-center">
            {[
              "Locations are aggregated to a grid before they reach the dashboard. Raw coordinates never leave our systems.",
              "No names, no user identifiers, no profile data — cities see counts and materials, not people.",
              "Cells with too few reports are suppressed entirely rather than shown as a lone pin that could identify someone’s route.",
              "Self-reported actions are excluded from every municipal figure. Only on-device verified items are counted.",
              "Residents can delete their history, and the aggregates recompute without it.",
            ].map((line) => (
              <li key={line} className="flex gap-3">
                <Flower className="mt-0.5 size-5 shrink-0" petal="#00A855" heart="#FFF7EA" />
                <span className="font-semibold leading-relaxed text-ink-dim">{line}</span>
              </li>
            ))}
          </ul>
        </div>
      </Section>

      <Section className="bg-page">
        <div className="reveal">
          <H2>How a pilot works</H2>
        </div>
        <ol className="mt-12 grid gap-7 sm:grid-cols-3">
          {[
            {
              step: "01",
              title: "One district, one season",
              body: "Thirty days, one defined area. Enough to see whether residents in your city actually engage, cheap enough that finding out they don’t costs you very little.",
              tone: "bg-gold",
            },
            {
              step: "02",
              title: "We report honestly",
              body: "Including the parts that didn’t work. A dashboard that only ever shows good news isn’t a dataset, it’s marketing.",
              tone: "bg-impact-cyan",
            },
            {
              step: "03",
              title: "Then you decide",
              body: "Annual licence for the dashboard, priced per resident population. No lock-in, and you keep the data we produced during the pilot.",
              tone: "bg-quest-green",
            },
          ].map((item, i) => (
            <li key={item.step} className="reveal">
              <Card className="h-full" tilt={i === 1 ? 1.2 : -1.2}>
                <span
                  className={`display flex size-12 items-center justify-center rounded-full border-[3px] border-ink shadow-[3px_3px_0_var(--color-ink)] ${item.tone}`}
                >
                  {item.step}
                </span>
                <h3 className="display mt-4 text-xl text-ink">{item.title}</h3>
                <p className="mt-2 font-semibold leading-relaxed text-ink-dim">{item.body}</p>
              </Card>
            </li>
          ))}
        </ol>
      </Section>
    </>
  );
}

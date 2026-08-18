import type { Metadata } from "next";
import {
  CTA,
  Card,
  Cloud,
  Eyebrow,
  Flower,
  H2,
  Lead,
  Section,
} from "../_components/brand";

export const metadata: Metadata = {
  title: "For schools",
  description:
    "Set up a school EcoLeague in an afternoon. Classes compete, the school gets the statistics, and cleanups actually happen.",
};

const LEADERBOARD = [
  { klass: "2.P", xp: "14 820", items: 412, pct: 100, tone: "bg-gold" },
  { klass: "3.A", xp: "12 420", items: 351, pct: 84, tone: "bg-impact-cyan" },
  { klass: "1.B", xp: "10 230", items: 288, pct: 69, tone: "bg-duel-violet" },
  { klass: "4.C", xp: "8 940", items: 244, pct: 60, tone: "bg-streak-fire" },
];

const STEPS = [
  {
    title: "A teacher creates the league",
    body: "Name it, pick which classes take part, share one join code. No accounts to provision, no IT ticket.",
    tone: "bg-gold",
  },
  {
    title: "Students play as themselves",
    body: "Their own profile, their own streak, their own friends — the class total is just the sum of what they were doing anyway.",
    tone: "bg-impact-cyan",
  },
  {
    title: "Classes compete",
    body: "A visible table turns a vague environmental topic into something 2.P wants to win before Friday.",
    tone: "bg-duel-violet",
  },
  {
    title: "The school gets the numbers",
    body: "Participation, items collected, materials breakdown — enough to report on, and enough to justify a cleanup day.",
    tone: "bg-quest-green",
  },
];

export default function Schools() {
  return (
    <>
      <section className="relative overflow-hidden bg-sky">
        <Cloud className="animate-drift absolute left-0 top-12 w-40 text-white/80" />
        <Cloud
          className="animate-drift absolute left-0 top-32 w-24 text-white/60"
          style={{ animationDelay: "-18s", animationDuration: "46s" }}
        />
        <div className="relative mx-auto max-w-6xl px-6 py-20 sm:py-28">
          <Eyebrow>School mode</Eyebrow>
          <H2>Three hundred students in one afternoon</H2>
          <Lead>
            Convincing teenagers one at a time is slow. A teacher creating a league
            for their year group is not. School mode is how EcoQuest grows — and it
            gives the school something real in return.
          </Lead>
          <div className="mt-10 flex flex-wrap gap-4">
            <CTA href="/about#contact">Talk to us about your school</CTA>
          </div>
        </div>
      </section>

      <Section className="bg-page">
        <div className="grid gap-14 lg:grid-cols-2">
          <div className="reveal">
            <H2>How a league runs</H2>
            <ol className="mt-10 flex flex-col gap-5">
              {STEPS.map((step, i) => (
                <li key={step.title} className="flex gap-4">
                  <span
                    className={`display flex size-11 shrink-0 items-center justify-center rounded-full border-[3px] border-ink shadow-[3px_3px_0_var(--color-ink)] ${step.tone}`}
                  >
                    {i + 1}
                  </span>
                  <div>
                    <h3 className="display text-xl text-ink">{step.title}</h3>
                    <p className="mt-1 font-semibold leading-relaxed text-ink-dim">
                      {step.body}
                    </p>
                  </div>
                </li>
              ))}
            </ol>
          </div>

          <Card className="reveal self-start bg-page-subtle" tilt={1}>
            <p className="text-xs font-extrabold tracking-[0.14em] uppercase text-ink-dim">
              Example league
            </p>
            <h3 className="display mt-2 text-2xl text-ink">SPŠE Plzeň EcoLeague</h3>

            <ul className="mt-7 flex flex-col gap-4">
              {LEADERBOARD.map((row, i) => (
                <li key={row.klass}>
                  <div className="flex items-baseline gap-3">
                    <span className="display w-10 text-lg text-ink">{row.klass}</span>
                    {i === 0 && (
                      <span className="animate-wiggle rounded-full border-2 border-ink bg-gold px-2 text-[10px] font-extrabold">
                        leading
                      </span>
                    )}
                    <span className="ml-auto text-xs font-bold text-ink-dim">
                      {row.items} items
                    </span>
                    <span className="display tabular w-16 text-right text-ink">{row.xp}</span>
                  </div>
                  <div className="mt-1.5 h-4 overflow-hidden rounded-full border-2 border-ink bg-page">
                    <div
                      className={`h-full origin-left animate-[grow-bar_1.6s_cubic-bezier(0.2,1.4,0.4,1)_both] rounded-full ${row.tone}`}
                      style={{ width: `${row.pct}%`, animationDelay: `${i * 0.12}s` }}
                    />
                  </div>
                </li>
              ))}
            </ul>

            <p className="mt-6 text-xs font-semibold text-ink-dim">
              Illustrative figures — this is what the table looks like, not a real
              school’s data.
            </p>
          </Card>
        </div>
      </Section>

      <Section className="relative overflow-hidden bg-page-subtle">
        <Flower className="animate-sway absolute -right-6 top-10 size-32 opacity-50" />
        <div className="reveal relative">
          <H2>What it costs, and what we ask</H2>
          <div className="mt-12 grid gap-7 sm:grid-cols-2">
            <Card className="bg-quest-green" tilt={-1}>
              <h3 className="display text-xl text-ink">Free for schools</h3>
              <p className="mt-2 font-semibold leading-relaxed text-ink/80">
                Leagues, class tables and the school statistics view cost nothing.
                Students who want EcoQuest+ can buy it; nobody has to, and no feature
                a league depends on sits behind it.
              </p>
            </Card>
            <Card tilt={1}>
              <h3 className="display text-xl text-ink">What we need from you</h3>
              <p className="mt-2 font-semibold leading-relaxed text-ink-dim">
                A member of staff to own the league, and honesty about the numbers. A
                league that inflates its totals is worthless to the school and to us —
                which is why items are verified on-device rather than typed in.
              </p>
            </Card>
          </div>
        </div>
      </Section>
    </>
  );
}

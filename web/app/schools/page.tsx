import type { Metadata } from "next";
import { CTA, Eyebrow, H2, Lead, Section } from "../_components/brand";

export const metadata: Metadata = {
  title: "For schools",
  description:
    "Set up a school EcoLeague in an afternoon. Classes compete, the school gets the statistics, and cleanups actually happen.",
};

const LEADERBOARD = [
  { klass: "2.P", xp: "14 820", items: 412 },
  { klass: "3.A", xp: "12 420", items: 351 },
  { klass: "1.B", xp: "10 230", items: 288 },
  { klass: "4.C", xp: "8 940", items: 244 },
];

export default function Schools() {
  return (
    <>
      <Section className="bg-deep-forest">
        <Eyebrow>School mode</Eyebrow>
        <H2 dark>Three hundred students in one afternoon</H2>
        <Lead dark>
          Convincing teenagers one at a time is slow. A teacher creating a league
          for their year group is not. School mode is how EcoQuest grows — and it
          gives the school something real in return.
        </Lead>
        <div className="mt-10 flex flex-wrap gap-3">
          <CTA href="/about#contact">Talk to us about your school</CTA>
        </div>
      </Section>

      <Section>
        <div className="grid gap-14 lg:grid-cols-2">
          <div>
            <H2>How a league runs</H2>
            <ol className="mt-8 flex flex-col gap-6">
              {[
                {
                  title: "A teacher creates the league",
                  body: "Name it, pick which classes take part, share one join code. No accounts to provision, no IT ticket.",
                },
                {
                  title: "Students play as themselves",
                  body: "Their own profile, their own streak, their own friends — the class total is just the sum of what they were doing anyway.",
                },
                {
                  title: "Classes compete",
                  body: "A visible table turns a vague environmental topic into something 2.P wants to win before Friday.",
                },
                {
                  title: "The school gets the numbers",
                  body: "Participation, items collected, materials breakdown — enough to report on, and enough to justify a cleanup day.",
                },
              ].map((step, i) => (
                <li key={step.title} className="flex gap-4">
                  <span className="display tabular text-quest-green-deep">
                    {String(i + 1).padStart(2, "0")}
                  </span>
                  <div>
                    <h3 className="display text-lg text-ink">{step.title}</h3>
                    <p className="mt-1 leading-relaxed text-ink-dim">{step.body}</p>
                  </div>
                </li>
              ))}
            </ol>
          </div>

          <div className="self-start rounded-xl border border-hairline bg-page-subtle p-7">
            <p className="text-xs font-semibold tracking-[0.14em] uppercase text-ink-dim">
              Example league
            </p>
            <h3 className="display mt-2 text-2xl text-ink">SPŠE Plzeň EcoLeague</h3>
            <table className="mt-6 w-full text-sm">
              <caption className="sr-only">
                Class standings by XP earned this season
              </caption>
              <thead>
                <tr className="border-b border-hairline text-left text-xs uppercase tracking-[0.1em] text-ink-dim">
                  <th scope="col" className="pb-2 font-semibold">Class</th>
                  <th scope="col" className="pb-2 text-right font-semibold">Items</th>
                  <th scope="col" className="pb-2 text-right font-semibold">XP</th>
                </tr>
              </thead>
              <tbody>
                {LEADERBOARD.map((row, i) => (
                  <tr key={row.klass} className="border-b border-hairline/60">
                    <td className="py-3">
                      <span
                        className={`display ${i === 0 ? "text-gold" : "text-ink"}`}
                      >
                        {row.klass}
                      </span>
                    </td>
                    <td className="tabular py-3 text-right text-ink-dim">
                      {row.items}
                    </td>
                    <td className="display tabular py-3 text-right text-ink">
                      {row.xp}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <p className="mt-5 text-xs text-ink-dim">
              Illustrative figures — this is what the table looks like, not a real
              school’s data.
            </p>
          </div>
        </div>
      </Section>

      <Section className="bg-page-subtle">
        <H2>What it costs, and what we ask</H2>
        <div className="mt-10 grid gap-8 sm:grid-cols-2">
          <div>
            <h3 className="display text-lg text-quest-green-deep">Free for schools</h3>
            <p className="mt-2 leading-relaxed text-ink-dim">
              Leagues, class tables and the school statistics view cost nothing.
              Students who want EcoQuest+ can buy it; nobody has to, and no feature
              a league depends on sits behind it.
            </p>
          </div>
          <div>
            <h3 className="display text-lg text-ink">What we need from you</h3>
            <p className="mt-2 leading-relaxed text-ink-dim">
              A member of staff to own the league, and honesty about the numbers. A
              league that inflates its totals is worthless to the school and to us —
              which is why items are verified on-device rather than typed in.
            </p>
          </div>
        </div>
      </Section>
    </>
  );
}

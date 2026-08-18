import type { Metadata } from "next";
import { CTA, Eyebrow, H2, Lead, Section } from "../_components/brand";

export const metadata: Metadata = {
  title: "For cities",
  description:
    "Anonymised, continuously updated maps of where litter actually accumulates — reported by residents and verified on-device.",
};

export default function Cities() {
  return (
    <>
      <Section className="bg-deep-forest">
        <Eyebrow>City dashboard</Eyebrow>
        <H2 dark>Where the litter actually is, not where the survey said</H2>
        <Lead dark>
          Municipal waste data is usually a snapshot, commissioned annually and out
          of date on arrival. EcoQuest produces a continuous one as a side effect of
          people playing a game.
        </Lead>
        <div className="mt-10">
          <CTA href="/about#contact">Request a pilot</CTA>
        </div>
      </Section>

      <Section>
        <H2>What you see</H2>
        <div className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {[
            {
              title: "Hotspot map",
              body: "Aggregated pins showing where residents keep finding litter, weighted by how much and how often. The bins that need emptying twice as often become obvious.",
            },
            {
              title: "Material breakdown",
              body: "Plastic, glass, metal, paper, cigarettes — per district, over time. Useful for deciding what a deposit scheme or a bin redesign would actually shift.",
            },
            {
              title: "Participation",
              body: "How many residents are active, in which neighbourhoods, and whether a campaign moved either number.",
            },
            {
              title: "Cleanup events",
              body: "Publish an event to the in-app map and watch attendance and collected volume against it.",
            },
            {
              title: "Campaign quests",
              body: "Commission a city-branded quest — a canal stretch, a park, a specific material — and see the response within a day.",
            },
            {
              title: "City-versus-city",
              body: "A public league table. It is, bluntly, the part that gets you press coverage and residents arguing in your favour.",
            },
          ].map((card) => (
            <div key={card.title} className="rounded-xl border border-hairline p-6">
              <h3 className="display text-lg text-ink">{card.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-ink-dim">{card.body}</p>
            </div>
          ))}
        </div>
      </Section>

      <Section className="bg-page-subtle">
        <div className="grid gap-14 lg:grid-cols-2">
          <div>
            <Eyebrow>Privacy</Eyebrow>
            <H2>You get the pattern, never the person</H2>
            <Lead>
              This only works if residents trust it, so the dashboard is built to
              make individual identification impossible rather than merely
              discouraged.
            </Lead>
          </div>
          <ul className="flex flex-col gap-5 self-center">
            {[
              "Locations are aggregated to a grid before they reach the dashboard. Raw coordinates never leave our systems.",
              "No names, no user identifiers, no profile data — cities see counts and materials, not people.",
              "Cells with too few reports are suppressed entirely rather than shown as a lone pin that could identify someone’s route.",
              "Self-reported actions are excluded from every municipal figure. Only on-device verified items are counted.",
              "Residents can delete their history, and the aggregates recompute without it.",
            ].map((line) => (
              <li key={line} className="flex gap-3">
                <span
                  aria-hidden="true"
                  className="mt-2 size-1.5 shrink-0 rounded-full bg-quest-green-deep"
                />
                <span className="leading-relaxed text-ink-dim">{line}</span>
              </li>
            ))}
          </ul>
        </div>
      </Section>

      <Section>
        <H2>How a pilot works</H2>
        <ol className="mt-10 grid gap-8 sm:grid-cols-3">
          {[
            {
              step: "01",
              title: "One district, one season",
              body: "Thirty days, one defined area. Enough to see whether residents in your city actually engage, cheap enough that finding out they don’t costs you very little.",
            },
            {
              step: "02",
              title: "We report honestly",
              body: "Including the parts that didn’t work. A dashboard that only ever shows good news isn’t a dataset, it’s marketing.",
            },
            {
              step: "03",
              title: "Then you decide",
              body: "Annual licence for the dashboard, priced per resident population. No lock-in, and you keep the data we produced during the pilot.",
            },
          ].map((item) => (
            <li key={item.step}>
              <p className="display tabular text-sm text-quest-green-deep">
                {item.step}
              </p>
              <h3 className="display mt-2 text-lg text-ink">{item.title}</h3>
              <p className="mt-2 leading-relaxed text-ink-dim">{item.body}</p>
            </li>
          ))}
        </ol>
      </Section>
    </>
  );
}

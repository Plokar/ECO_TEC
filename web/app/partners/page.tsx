import type { Metadata } from "next";
import { CTA, Eyebrow, H2, Lead, Section } from "../_components/brand";

export const metadata: Metadata = {
  title: "For brands",
  description:
    "Sponsor a quest or offer a reward. Always labelled, never disguised as content — reaching people at the moment they’ve just done something good.",
};

export default function Partners() {
  return (
    <>
      <Section className="bg-deep-forest">
        <Eyebrow>Partnerships</Eyebrow>
        <H2 dark>Reach someone thirty seconds after they did something good</H2>
        <Lead dark>
          There is no better moment to hand a person a reward than immediately after
          they have picked ten bottles out of a park. That moment is what we sell —
          and we sell it labelled.
        </Lead>
        <div className="mt-10">
          <CTA href="/about#contact">Start a conversation</CTA>
        </div>
      </Section>

      <Section>
        <H2>Two ways in</H2>
        <div className="mt-12 grid gap-6 lg:grid-cols-2">
          <div className="rounded-xl border border-hairline p-7">
            <h3 className="display text-xl text-ink">Sponsor a quest</h3>
            <p className="mt-3 leading-relaxed text-ink-dim">
              Your name on a challenge, with the reward you’re funding. Pick the
              material, the target and the region. You get completion counts,
              verified item totals and the aggregate CO₂ figure — never personal
              data.
            </p>
            <div className="mt-6 rounded-xl border border-hairline bg-page-subtle p-5">
              <p className="display text-base text-ink">Scrap sweep: 30 metal items</p>
              <div className="mt-3 flex flex-wrap gap-2">
                <span className="rounded-full bg-quest-green/15 px-2.5 py-1 text-xs font-semibold text-quest-green-deep">
                  +900 XP
                </span>
                <span className="rounded-full bg-impact-cyan/15 px-2.5 py-1 text-xs font-semibold text-impact-cyan">
                  +300 EcoPoints
                </span>
              </div>
              <p className="mt-4 inline-flex rounded-full border border-hairline px-2.5 py-1 text-[11px] text-ink-dim">
                Sponsored by Your Brand
              </p>
            </div>
          </div>

          <div className="rounded-xl border border-hairline p-7">
            <h3 className="display text-xl text-ink">Offer a reward</h3>
            <p className="mt-3 leading-relaxed text-ink-dim">
              List something players spend EcoPoints on: a coffee, a transport day
              ticket, a product, an event pair. You set the stock and the terms; we
              handle redemption codes and never charge the user money.
            </p>
            <ul className="mt-6 flex flex-col gap-3 text-sm text-ink-dim">
              {[
                "Priced in EcoPoints, which are only earned by verified action.",
                "You see redemption volume and which quests drove it.",
                "Stock caps are hard — a sold-out reward disappears rather than disappointing someone.",
              ].map((line) => (
                <li key={line} className="flex gap-3">
                  <span
                    aria-hidden="true"
                    className="mt-1.5 size-1.5 shrink-0 rounded-full bg-quest-green-deep"
                  />
                  <span>{line}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </Section>

      <Section className="bg-page-subtle">
        <Eyebrow>Ground rules</Eyebrow>
        <H2>What we won’t do, in writing</H2>
        <Lead>
          Greenwashing is the fastest way to kill an app like this. These aren’t
          preferences, they’re conditions of working with us.
        </Lead>
        <div className="mt-12 grid gap-8 sm:grid-cols-2">
          {[
            {
              title: "No disguised advertising",
              body: "Every sponsored quest carries a visible “Sponsored by” label. We will not blur it into the feed, and there is no premium tier that removes the label.",
            },
            {
              title: "No inflated impact",
              body: "We won’t attach a CO₂ figure to your campaign that we can’t defend from published per-material factors. Ranges where the estimate is weak, and the basis shown on tap.",
            },
            {
              title: "No personal data",
              body: "You get aggregates. Not names, not locations, not profiles, not an export. This isn’t negotiable at any budget.",
            },
            {
              title: "No claiming avoided consumption",
              body: "A user who didn’t buy something hasn’t “saved” anything measurable, and we won’t let a campaign say they did.",
            },
          ].map((rule) => (
            <div key={rule.title} className="border-t-2 border-quest-green pt-5">
              <h3 className="display text-lg text-ink">{rule.title}</h3>
              <p className="mt-2 leading-relaxed text-ink-dim">{rule.body}</p>
            </div>
          ))}
        </div>
      </Section>
    </>
  );
}

import type { Metadata } from "next";
import { CTA, Card, Cloud, Eyebrow, Flower, H2, Lead, Section } from "../_components/brand";

export const metadata: Metadata = {
  title: "For brands",
  description:
    "Sponsor a quest or offer a reward. Always labelled, never disguised as content — reaching people at the moment they’ve just done something good.",
};

const RULES = [
  {
    title: "No disguised advertising",
    body: "Every sponsored quest carries a visible “Sponsored by” label. We will not blur it into the feed, and there is no premium tier that removes the label.",
    tone: "bg-streak-fire",
  },
  {
    title: "No inflated impact",
    body: "We won’t attach a CO₂ figure to your campaign that we can’t defend from published per-material factors. Ranges where the estimate is weak, and the basis shown on tap.",
    tone: "bg-gold",
  },
  {
    title: "No personal data",
    body: "You get aggregates. Not names, not locations, not profiles, not an export. This isn’t negotiable at any budget.",
    tone: "bg-impact-cyan",
  },
  {
    title: "No claiming avoided consumption",
    body: "A user who didn’t buy something hasn’t “saved” anything measurable, and we won’t let a campaign say they did.",
    tone: "bg-duel-violet",
  },
];

export default function Partners() {
  return (
    <>
      <section className="relative overflow-hidden bg-sky">
        <Cloud className="animate-drift absolute left-0 top-14 w-36 text-white/80" />
        <Cloud
          className="animate-drift absolute left-0 top-40 w-52 text-white/60"
          style={{ animationDelay: "-24s", animationDuration: "50s" }}
        />
        <div className="relative mx-auto max-w-6xl px-6 py-20 sm:py-28">
          <Eyebrow tone="bg-duel-violet">Partnerships</Eyebrow>
          <H2>Reach someone thirty seconds after they did something good</H2>
          <Lead>
            There is no better moment to hand a person a reward than immediately
            after they have picked ten bottles out of a park. That moment is what we
            sell — and we sell it labelled.
          </Lead>
          <div className="mt-10">
            <CTA href="/about#contact">Start a conversation</CTA>
          </div>
        </div>
      </section>

      <Section className="bg-page">
        <div className="reveal">
          <H2>Two ways in</H2>
        </div>
        <div className="mt-12 grid gap-7 lg:grid-cols-2">
          <div className="reveal">
            <Card className="h-full" tilt={-1}>
              <h3 className="display text-2xl text-ink">Sponsor a quest</h3>
              <p className="mt-3 font-semibold leading-relaxed text-ink-dim">
                Your name on a challenge, with the reward you’re funding. Pick the
                material, the target and the region. You get completion counts,
                verified item totals and the aggregate CO₂ figure — never personal
                data.
              </p>

              <div
                className="mt-7 rounded-2xl border-[3px] border-ink bg-page-subtle p-5 shadow-[5px_5px_0_var(--color-ink)]"
                style={{ rotate: "-1.5deg" }}
              >
                <p className="display text-lg text-ink">Scrap sweep: 30 metal items</p>
                <div className="mt-3 flex flex-wrap gap-2">
                  <span className="rounded-full border-2 border-ink bg-quest-green px-2.5 py-1 text-xs font-extrabold text-ink">
                    +900 XP
                  </span>
                  <span className="rounded-full border-2 border-ink bg-impact-cyan px-2.5 py-1 text-xs font-extrabold text-ink">
                    +300 EcoPoints
                  </span>
                </div>
                <p className="animate-wiggle mt-4 inline-flex rounded-full border-2 border-ink bg-page px-2.5 py-1 text-[11px] font-extrabold text-ink-dim">
                  Sponsored by Your Brand
                </p>
              </div>
            </Card>
          </div>

          <div className="reveal">
            <Card className="h-full" tilt={1}>
              <h3 className="display text-2xl text-ink">Offer a reward</h3>
              <p className="mt-3 font-semibold leading-relaxed text-ink-dim">
                List something players spend EcoPoints on: a coffee, a transport day
                ticket, a product, an event pair. You set the stock and the terms; we
                handle redemption codes and never charge the user money.
              </p>
              <ul className="mt-6 flex flex-col gap-3 text-sm">
                {[
                  "Priced in EcoPoints, which are only earned by verified action.",
                  "You see redemption volume and which quests drove it.",
                  "Stock caps are hard — a sold-out reward disappears rather than disappointing someone.",
                ].map((line) => (
                  <li key={line} className="flex gap-3">
                    <Flower className="mt-0.5 size-4 shrink-0" petal="#00A855" heart="#FFF7EA" />
                    <span className="font-semibold text-ink-dim">{line}</span>
                  </li>
                ))}
              </ul>
            </Card>
          </div>
        </div>
      </Section>

      <Section className="bg-page-subtle">
        <div className="reveal">
          <Eyebrow tone="bg-alert-red">Ground rules</Eyebrow>
          <H2>What we won’t do, in writing</H2>
          <Lead>
            Greenwashing is the fastest way to kill an app like this. These aren’t
            preferences, they’re conditions of working with us.
          </Lead>
        </div>
        <div className="mt-12 grid gap-7 sm:grid-cols-2">
          {RULES.map((rule, i) => (
            <div key={rule.title} className="reveal">
              <Card className="h-full" tilt={i % 2 ? 1 : -1}>
                <span className={`h-3 w-14 rounded-full border-2 border-ink ${rule.tone}`} />
                <h3 className="display mt-4 text-xl text-ink">{rule.title}</h3>
                <p className="mt-2 font-semibold leading-relaxed text-ink-dim">{rule.body}</p>
              </Card>
            </div>
          ))}
        </div>
      </Section>
    </>
  );
}

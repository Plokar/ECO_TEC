import type { Metadata } from "next";
import { Eyebrow, H2, Lead, Section } from "../_components/brand";

export const metadata: Metadata = {
  title: "About",
  description:
    "EcoTech B.V. builds EcoQuest from Amsterdam. How we count impact, what we refuse to claim, and how to reach us.",
};

export default function About() {
  return (
    <>
      <Section className="bg-deep-forest">
        <Eyebrow>EcoTech B.V. · Amsterdam</Eyebrow>
        <H2 dark>We think the guilt approach has had its turn</H2>
        <Lead dark>
          Two decades of environmental messaging has told people what they’re doing
          wrong. It produced awareness and very little action. EcoQuest tries the
          opposite: make the action itself the fun part, and let the impact be a
          consequence rather than a lecture.
        </Lead>
      </Section>

      <Section>
        <div className="grid gap-14 lg:grid-cols-2">
          <div>
            <H2>What we’re building</H2>
            <Lead>
              A social game whose scoreboard happens to be made of real actions.
              Everything else — the verification model, the map, the leagues, the
              rewards — exists to make that scoreboard trustworthy enough to be
              worth competing over.
            </Lead>
          </div>
          <div>
            <H2>What we’re honest about</H2>
            <Lead>
              This is early. The detector isn’t perfect and never will be. The app is
              worth little until enough people in one city are using it. Retention
              for social apps is brutal. We’d rather say that than pretend otherwise
              in a pitch deck.
            </Lead>
          </div>
        </div>
      </Section>

      <Section id="impact-method" className="bg-page-subtle">
        <Eyebrow>Method</Eyebrow>
        <H2>How we count impact</H2>
        <Lead>
          The fastest way to destroy trust in something like this is one number
          nobody believes. So the rules we hold ourselves to are published rather
          than implied.
        </Lead>
        <div className="mt-12 grid gap-8 sm:grid-cols-2">
          {[
            {
              title: "Every figure shows its basis",
              body: "Tap a CO₂ number in the app and you get the material and the factor it came from. No unexplained totals.",
            },
            {
              title: "Ranges where the estimate is weak",
              body: "A crushed unlabelled fragment isn’t a known mass. When we can’t be precise we show a range instead of inventing a decimal place.",
            },
            {
              title: "Unverified means unverified",
              body: "Self-reported actions carry a visible label and are excluded from every city, school and country total.",
            },
            {
              title: "We don’t count what you didn’t do",
              body: "Not buying something is not the same as saving something measurable, and we won’t convert one into the other.",
            },
            {
              title: "Aggregates only, for everyone else",
              body: "Cities and brands see patterns. No names, no coordinates, no exports of personal data — at any price.",
            },
            {
              title: "Verification runs on your device",
              body: "Your photos are scored on your phone. That’s a privacy decision first and a cost decision second.",
            },
          ].map((item) => (
            <div key={item.title} className="border-t-2 border-quest-green pt-5">
              <h3 className="display text-lg text-ink">{item.title}</h3>
              <p className="mt-2 leading-relaxed text-ink-dim">{item.body}</p>
            </div>
          ))}
        </div>
      </Section>

      <Section id="contact">
        <div className="grid gap-14 lg:grid-cols-2">
          <div>
            <Eyebrow>Contact</Eyebrow>
            <H2>Get in touch</H2>
            <Lead>
              Schools and municipalities get answered first — they’re how this grows.
              Brand enquiries are welcome, provided you’ve read the ground rules.
            </Lead>
          </div>
          <dl className="flex flex-col gap-6 self-center">
            {[
              { label: "Schools", value: "schools@ecoquest.app" },
              { label: "Cities & municipalities", value: "cities@ecoquest.app" },
              { label: "Brand partnerships", value: "partners@ecoquest.app" },
              { label: "Press", value: "press@ecoquest.app" },
              { label: "Everything else", value: "hello@ecoquest.app" },
            ].map((item) => (
              <div key={item.label}>
                <dt className="text-xs font-semibold tracking-[0.14em] uppercase text-ink-dim">
                  {item.label}
                </dt>
                <dd className="mt-1">
                  <a
                    href={`mailto:${item.value}`}
                    className="text-lg text-quest-green-deep underline decoration-hairline underline-offset-4 hover:decoration-quest-green-deep"
                  >
                    {item.value}
                  </a>
                </dd>
              </div>
            ))}
          </dl>
        </div>
        <p className="mt-14 max-w-2xl text-sm text-ink-dim">
          These addresses are placeholders for the fictional company used in this
          project. Replace them with real ones before the site goes anywhere public.
        </p>
      </Section>
    </>
  );
}

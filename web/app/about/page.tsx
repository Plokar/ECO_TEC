import type { Metadata } from "next";
import { Card, Cloud, Eyebrow, Flower, H2, Lead, Section } from "../_components/brand";

export const metadata: Metadata = {
  title: "About",
  description:
    "EcoTech B.V. builds EcoQuest from Amsterdam. How we count impact, what we refuse to claim, and how to reach us.",
};

const METHOD = [
  {
    title: "Every figure shows its basis",
    body: "Tap a CO₂ number in the app and you get the material and the factor it came from. No unexplained totals.",
    tone: "bg-quest-green",
  },
  {
    title: "Ranges where the estimate is weak",
    body: "A crushed unlabelled fragment isn’t a known mass. When we can’t be precise we show a range instead of inventing a decimal place.",
    tone: "bg-gold",
  },
  {
    title: "Unverified means unverified",
    body: "Self-reported actions carry a visible label and are excluded from every city, school and country total.",
    tone: "bg-streak-fire",
  },
  {
    title: "We don’t count what you didn’t do",
    body: "Not buying something is not the same as saving something measurable, and we won’t convert one into the other.",
    tone: "bg-duel-violet",
  },
  {
    title: "Aggregates only, for everyone else",
    body: "Cities and brands see patterns. No names, no coordinates, no exports of personal data — at any price.",
    tone: "bg-impact-cyan",
  },
  {
    title: "Verification runs on your device",
    body: "Your photos are scored on your phone. That’s a privacy decision first and a cost decision second.",
    tone: "bg-leaf",
  },
];

const CONTACT = [
  { label: "Schools", value: "schools@ecoquest.app" },
  { label: "Cities & municipalities", value: "cities@ecoquest.app" },
  { label: "Brand partnerships", value: "partners@ecoquest.app" },
  { label: "Press", value: "press@ecoquest.app" },
  { label: "Everything else", value: "hello@ecoquest.app" },
];

export default function About() {
  return (
    <>
      <section className="relative overflow-hidden bg-sky">
        <Cloud className="animate-drift absolute left-0 top-12 w-44 text-white/80" />
        <Cloud
          className="animate-drift absolute left-0 top-40 w-28 text-white/60"
          style={{ animationDelay: "-22s", animationDuration: "46s" }}
        />
        <Flower className="animate-spin-slow absolute right-8 top-10 size-24 opacity-70" />
        <div className="relative mx-auto max-w-6xl px-6 py-20 sm:py-28">
          <Eyebrow>EcoTech B.V. · Amsterdam</Eyebrow>
          <H2>We think the guilt approach has had its turn</H2>
          <Lead>
            Two decades of environmental messaging has told people what they’re doing
            wrong. It produced awareness and very little action. EcoQuest tries the
            opposite: make the action itself the fun part, and let the impact be a
            consequence rather than a lecture.
          </Lead>
        </div>
      </section>

      <Section className="bg-page">
        <div className="grid gap-7 lg:grid-cols-2">
          <div className="reveal">
            <Card className="h-full bg-page-subtle" tilt={-1}>
              <H2>What we’re building</H2>
              <Lead>
                A social game whose scoreboard happens to be made of real actions.
                Everything else — the verification model, the map, the leagues, the
                rewards — exists to make that scoreboard trustworthy enough to be
                worth competing over.
              </Lead>
            </Card>
          </div>
          <div className="reveal">
            <Card className="h-full bg-gold/40" tilt={1}>
              <H2>What we’re honest about</H2>
              <Lead>
                This is early. The detector isn’t perfect and never will be. The app
                is worth little until enough people in one city are using it.
                Retention for social apps is brutal. We’d rather say that than
                pretend otherwise in a pitch deck.
              </Lead>
            </Card>
          </div>
        </div>
      </Section>

      <Section id="impact-method" className="bg-page-subtle">
        <div className="reveal">
          <Eyebrow tone="bg-impact-cyan">Method</Eyebrow>
          <H2>How we count impact</H2>
          <Lead>
            The fastest way to destroy trust in something like this is one number
            nobody believes. So the rules we hold ourselves to are published rather
            than implied.
          </Lead>
        </div>
        <div className="mt-12 grid gap-7 sm:grid-cols-2 lg:grid-cols-3">
          {METHOD.map((item, i) => (
            <div key={item.title} className="reveal">
              <Card className="h-full" tilt={i % 2 ? 1 : -1}>
                <span className={`h-3 w-14 rounded-full border-2 border-ink ${item.tone}`} />
                <h3 className="display mt-4 text-xl text-ink">{item.title}</h3>
                <p className="mt-2 font-semibold leading-relaxed text-ink-dim">{item.body}</p>
              </Card>
            </div>
          ))}
        </div>
      </Section>

      <Section id="contact" className="relative overflow-hidden bg-page">
        <Flower className="animate-float absolute -right-10 top-20 size-40 opacity-30" />
        <div className="relative grid gap-14 lg:grid-cols-2">
          <div className="reveal">
            <Eyebrow tone="bg-quest-green">Contact</Eyebrow>
            <H2>Get in touch</H2>
            <Lead>
              Schools and municipalities get answered first — they’re how this grows.
              Brand enquiries are welcome, provided you’ve read the ground rules.
            </Lead>
          </div>
          <dl className="reveal flex flex-col gap-4 self-center">
            {CONTACT.map((item, i) => (
              <div
                key={item.label}
                className="sticker lift bg-page-subtle px-5 py-4"
                style={{ rotate: `${i % 2 ? 0.6 : -0.6}deg` }}
              >
                <dt className="text-xs font-extrabold tracking-[0.14em] uppercase text-ink-dim">
                  {item.label}
                </dt>
                <dd className="mt-1">
                  <a
                    href={`mailto:${item.value}`}
                    className="display text-lg text-quest-green-deep underline decoration-2 underline-offset-4"
                  >
                    {item.value}
                  </a>
                </dd>
              </div>
            ))}
          </dl>
        </div>
        <p className="mt-14 max-w-2xl text-sm font-semibold text-ink-dim">
          These addresses are placeholders for the fictional company used in this
          project. Replace them with real ones before the site goes anywhere public.
        </p>
      </Section>
    </>
  );
}

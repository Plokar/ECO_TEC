import type { Metadata } from "next";
import { CTA, Card, Cloud, Eyebrow, Flower, H2, Lead, Section } from "../_components/brand";

export const metadata: Metadata = {
  title: "Pricing",
  description:
    "Free for players, free for schools, paid for brands and cities. Four revenue streams so the product never has to depend on advertising.",
};

const TIERS = [
  {
    name: "Free",
    price: "€0",
    unit: "forever",
    summary: "Everything the game actually needs.",
    features: [
      "Daily quests and on-device verification",
      "Friends, duels and all leaderboards",
      "City, school and country leagues",
      "The Eco Map",
      "EcoPoints and reward redemption",
      "Occasional ads",
    ],
    cta: { href: "/#get-the-app", label: "Get the app" },
    tone: "bg-page",
    tilt: -1.2,
    highlight: false,
  },
  {
    name: "EcoQuest+",
    price: "€3.99",
    unit: "per month",
    summary: "For people who are going to play this daily anyway.",
    features: [
      "No ads",
      "Custom and exclusive quests",
      "Full statistics history and trends",
      "Advanced profile and customisation",
      "Early access to seasonal events",
      "Nothing competitive — plus never buys you rank",
    ],
    cta: { href: "/#get-the-app", label: "Get the app" },
    tone: "bg-quest-green",
    tilt: 0,
    highlight: true,
  },
  {
    name: "Schools",
    price: "€0",
    unit: "for the school",
    summary: "The distribution channel, so it can’t have a price tag.",
    features: [
      "Unlimited class leagues",
      "School statistics view",
      "Cleanup event tools",
      "Exportable participation reports",
      "No per-student licence, ever",
    ],
    cta: { href: "/schools", label: "See school mode" },
    tone: "bg-page",
    tilt: 1.2,
    highlight: false,
  },
];

const B2B = [
  {
    name: "Brand partnerships",
    body: "Sponsored quests and funded rewards, priced per campaign by reach and duration. Always visibly labelled.",
    href: "/partners",
    label: "For brands",
    tone: "bg-gold",
  },
  {
    name: "City dashboard",
    body: "Annual licence, priced against resident population, starting with a single-district pilot season.",
    href: "/cities",
    label: "For cities",
    tone: "bg-impact-cyan",
  },
];

const FAQ = [
  {
    q: "Does EcoQuest+ give a competitive advantage?",
    a: "No. It removes ads and adds statistics and customisation. It cannot buy XP, EcoPoints or rank, because a league where the top spot is purchasable is not a league.",
  },
  {
    q: "Is the app usable without paying anything?",
    a: "Yes, permanently. Every quest type, every leaderboard, the map and the rewards shop are in the free tier.",
  },
  {
    q: "Do I need a data connection to play?",
    a: "Not to complete a quest. Verification runs on your phone; submissions queue and sync when you’re back in signal, and the XP lands immediately either way.",
  },
  {
    q: "Are my photos sent anywhere?",
    a: "Verification happens entirely on your device. The photo uploads afterwards as proof attached to your submission, and you can delete your history.",
  },
  {
    q: "Why is school mode free when schools are your best channel?",
    a: "Precisely because they’re the best channel. Charging a school to bring us hundreds of users would be charging for our own distribution.",
  },
];

export default function Pricing() {
  return (
    <>
      <section className="relative overflow-hidden bg-sky">
        <Cloud className="animate-drift absolute left-0 top-10 w-40 text-white/80" />
        <Cloud
          className="animate-drift absolute left-0 top-36 w-24 text-white/60"
          style={{ animationDelay: "-16s", animationDuration: "42s" }}
        />
        <div className="relative mx-auto max-w-6xl px-6 py-20 sm:py-28">
          <Eyebrow>Pricing</Eyebrow>
          <H2>Players don’t pay. Four other people do.</H2>
          <Lead>
            Advertising alone is too thin to build this on, and a paywall on the
            competitive parts would break the only thing that makes it work. So the
            money comes from subscriptions, brands, cities and partners — and the
            game stays free.
          </Lead>
        </div>
      </section>

      <Section className="bg-page">
        <div className="grid gap-7 lg:grid-cols-3">
          {TIERS.map((tier) => (
            <div key={tier.name} className="reveal relative">
              {tier.highlight && (
                <span className="animate-wiggle absolute -top-4 left-6 z-10 rounded-full border-[3px] border-ink bg-gold px-3 py-1 text-xs font-extrabold shadow-[3px_3px_0_var(--color-ink)]">
                  most played
                </span>
              )}
              <Card
                className={`flex h-full flex-col ${tier.tone} ${
                  tier.highlight ? "shadow-[10px_10px_0_var(--color-ink)] sm:scale-105" : ""
                }`}
                tilt={tier.tilt}
              >
                <h3 className="display text-2xl text-ink">{tier.name}</h3>
                <p className="mt-4 flex items-baseline gap-2">
                  <span className="display tabular text-5xl text-ink">{tier.price}</span>
                  <span className="text-sm font-bold text-ink-dim">{tier.unit}</span>
                </p>
                <p className="mt-3 font-semibold text-ink-dim">{tier.summary}</p>
                <ul className="mt-6 flex flex-1 flex-col gap-3 text-sm">
                  {tier.features.map((feature) => (
                    <li key={feature} className="flex gap-3">
                      <Flower className="mt-0.5 size-4 shrink-0" petal="#00A855" heart="#FFF7EA" />
                      <span className="font-semibold text-ink-dim">{feature}</span>
                    </li>
                  ))}
                </ul>
                <div className="mt-7">
                  <CTA href={tier.cta.href} variant={tier.highlight ? "ghost" : "primary"}>
                    {tier.cta.label}
                  </CTA>
                </div>
              </Card>
            </div>
          ))}
        </div>
      </Section>

      <Section className="bg-page-subtle">
        <div className="reveal">
          <H2>Business plans</H2>
        </div>
        <div className="mt-12 grid gap-7 sm:grid-cols-2">
          {B2B.map((item, i) => (
            <div key={item.name} className="reveal">
              <Card className="flex h-full flex-col" tilt={i ? 1 : -1}>
                <span className={`h-3 w-14 rounded-full border-2 border-ink ${item.tone}`} />
                <h3 className="display mt-4 text-xl text-ink">{item.name}</h3>
                <p className="mt-3 flex-1 font-semibold leading-relaxed text-ink-dim">
                  {item.body}
                </p>
                <div className="mt-6">
                  <CTA href={item.href} variant="ghost">
                    {item.label}
                  </CTA>
                </div>
              </Card>
            </div>
          ))}
        </div>
      </Section>

      {/* ponytail: <details> is an accordion. No state, no library, keyboard
          accessible for free. */}
      <Section className="bg-page">
        <div className="reveal">
          <H2>Straight answers</H2>
        </div>
        <div className="mt-10 flex max-w-3xl flex-col gap-4">
          {FAQ.map((item, i) => (
            <details
              key={item.q}
              className="sticker group bg-page-subtle px-6 py-5 open:bg-gold/40"
              style={{ rotate: `${i % 2 ? 0.4 : -0.4}deg` }}
            >
              <summary className="display flex cursor-pointer list-none items-center gap-4 text-lg text-ink marker:hidden">
                <span className="flex-1">{item.q}</span>
                <span className="display flex size-8 shrink-0 items-center justify-center rounded-full border-[3px] border-ink bg-page transition-transform group-open:rotate-45">
                  +
                </span>
              </summary>
              <p className="mt-4 font-semibold leading-relaxed text-ink-dim">{item.a}</p>
            </details>
          ))}
        </div>
      </Section>
    </>
  );
}

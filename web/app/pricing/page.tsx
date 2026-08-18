import type { Metadata } from "next";
import { CTA, Eyebrow, H2, Lead, Section } from "../_components/brand";

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
    highlight: false,
  },
];

const B2B = [
  {
    name: "Brand partnerships",
    body: "Sponsored quests and funded rewards, priced per campaign by reach and duration. Always visibly labelled.",
    href: "/partners",
    label: "For brands",
  },
  {
    name: "City dashboard",
    body: "Annual licence, priced against resident population, starting with a single-district pilot season.",
    href: "/cities",
    label: "For cities",
  },
];

export default function Pricing() {
  return (
    <>
      <Section className="bg-deep-forest">
        <Eyebrow>Pricing</Eyebrow>
        <H2 dark>Players don’t pay. Four other people do.</H2>
        <Lead dark>
          Advertising alone is too thin to build this on, and a paywall on the
          competitive parts would break the only thing that makes it work. So the
          money comes from subscriptions, brands, cities and partners — and the game
          stays free.
        </Lead>
      </Section>

      <Section>
        <div className="grid gap-6 lg:grid-cols-3">
          {TIERS.map((tier) => (
            <div
              key={tier.name}
              className={`flex flex-col rounded-xl border p-7 ${
                tier.highlight
                  ? "border-quest-green-deep bg-page-subtle"
                  : "border-hairline"
              }`}
            >
              <h3 className="display text-xl text-ink">{tier.name}</h3>
              <p className="mt-4 flex items-baseline gap-2">
                <span className="display tabular text-4xl text-ink">{tier.price}</span>
                <span className="text-sm text-ink-dim">{tier.unit}</span>
              </p>
              <p className="mt-3 text-sm text-ink-dim">{tier.summary}</p>
              <ul className="mt-6 flex flex-1 flex-col gap-3 text-sm">
                {tier.features.map((feature) => (
                  <li key={feature} className="flex gap-3">
                    <svg
                      viewBox="0 0 20 20"
                      className="mt-0.5 size-4 shrink-0 text-quest-green-deep"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path d="M8 13.4 4.6 10l-1.2 1.2L8 15.8l8.6-8.6L15.4 6z" />
                    </svg>
                    <span className="text-ink-dim">{feature}</span>
                  </li>
                ))}
              </ul>
              <div className="mt-7">
                <CTA
                  href={tier.cta.href}
                  variant={tier.highlight ? "primary" : "ghost"}
                >
                  {tier.cta.label}
                </CTA>
              </div>
            </div>
          ))}
        </div>
      </Section>

      <Section className="bg-page-subtle">
        <H2>Business plans</H2>
        <div className="mt-10 grid gap-6 sm:grid-cols-2">
          {B2B.map((item) => (
            <div
              key={item.name}
              className="flex flex-col rounded-xl border border-hairline bg-page p-7"
            >
              <h3 className="display text-lg text-ink">{item.name}</h3>
              <p className="mt-3 flex-1 leading-relaxed text-ink-dim">{item.body}</p>
              <div className="mt-6">
                <CTA href={item.href} variant="ghost">
                  {item.label}
                </CTA>
              </div>
            </div>
          ))}
        </div>
      </Section>

      <Section>
        <H2>Straight answers</H2>
        <dl className="mt-10 flex flex-col divide-y divide-hairline">
          {[
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
          ].map((item) => (
            <div key={item.q} className="py-6">
              <dt className="display text-lg text-ink">{item.q}</dt>
              <dd className="mt-2 max-w-3xl leading-relaxed text-ink-dim">{item.a}</dd>
            </div>
          ))}
        </dl>
      </Section>
    </>
  );
}

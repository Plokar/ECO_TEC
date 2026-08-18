import { CTA, Eyebrow, H2, Lead, Section, Stat } from "./_components/brand";
import { PhoneMock } from "./_components/phone-mock";

const LOOP = [
  {
    step: "01",
    title: "Get a quest",
    body: "One a day, the same for everyone, so city-versus-city stays fair. Location-aware ones fire when you’re near a park or a cleanup.",
  },
  {
    step: "02",
    title: "Do it for real",
    body: "Pick up ten bottles. Clear the butts off a playground. Cycle instead of driving. Real actions, not taps.",
  },
  {
    step: "03",
    title: "Photograph the proof",
    body: "One tap to the shutter from anywhere in the app. No caption to write, no feed to curate.",
  },
  {
    step: "04",
    title: "The AI checks it",
    body: "A detector runs on your phone and counts what it sees, item by item, with the boxes drawn on your photo.",
  },
  {
    step: "05",
    title: "Collect and climb",
    body: "XP, EcoPoints, streak. Then find out where that puts you against your friends, your school and your city.",
  },
];

const FEATURES = [
  {
    title: "AI eco verification",
    body: "A litter detector trained on real photos of real rubbish, running offline on the phone. It counts items, names the material, and tells you which bin it belongs in.",
    tone: "text-quest-green",
  },
  {
    title: "The Eco Map",
    body: "Litter hotspots, recycling points and community cleanups, built from what players actually find. The aggregate is what cities pay for.",
    tone: "text-impact-cyan",
  },
  {
    title: "Friend duels",
    body: "Plastic collected, streak, XP — side by side with someone you know. Beating an abstract environmental goal motivates nobody. Beating Alex does.",
    tone: "text-duel-violet",
  },
  {
    title: "City battles",
    body: "Prague versus Amsterdam, updated live. Schools, universities and youth groups field their own teams.",
    tone: "text-gold",
  },
  {
    title: "Streaks that aren’t the whole app",
    body: "Daily, friend and community streaks run in parallel, so one missed day doesn’t undo everything you’ve built.",
    tone: "text-streak-fire",
  },
  {
    title: "Seasons",
    body: "Thirty-day cycles instead of an endless leaderboard. Rankings reset, badges rotate, and everyone gets another shot at the top.",
    tone: "text-quest-green",
  },
];

const HIERARCHY = [
  "World",
  "Country",
  "City",
  "School",
  "Class",
  "Friends",
  "You",
];

export default function Home() {
  return (
    <>
      {/* Hero */}
      <section className="bg-deep-forest">
        <div className="mx-auto grid max-w-6xl items-center gap-14 px-6 py-20 sm:py-28 lg:grid-cols-2">
          <div>
            <p className="mb-5 inline-flex rounded-full border border-forest-line px-3 py-1 text-xs font-semibold tracking-[0.14em] uppercase text-quest-green">
              EcoTech · Amsterdam
            </p>
            <h1 className="display text-4xl text-bone sm:text-6xl">
              Save the planet.
              <br />
              <span className="text-gradient">Beat your friends.</span>
            </h1>
            <p className="mt-6 max-w-xl text-lg leading-relaxed text-bone-dim">
              EcoQuest is a social gaming platform that turns real-world
              environmental actions into challenges, competition and rewards.
              Every bottle you pick up is worth something — in points, and to the
              place you live.
            </p>
            <div className="mt-9 flex flex-wrap gap-3">
              <CTA href="/#get-the-app">Get the app</CTA>
              <CTA href="/schools" variant="ghost-dark">
                Bring it to my school
              </CTA>
            </div>

            <dl className="mt-14 grid grid-cols-3 gap-6 border-t border-forest-line pt-8">
              <Stat value="7" caption="waste types detected" />
              <Stat value="0" caption="cloud calls to verify" tone="text-impact-cyan" />
              <Stat value="30s" caption="from open to earned" tone="text-gold" />
            </dl>
          </div>

          <div className="flex justify-center lg:justify-end">
            <PhoneMock />
          </div>
        </div>
      </section>

      {/* Positioning */}
      <Section className="bg-page-subtle">
        <Eyebrow>Why this works</Eyebrow>
        <H2>
          Three apps already proved the hard part. We pointed them at the planet.
        </H2>
        <div className="mt-12 grid gap-8 sm:grid-cols-3">
          {[
            {
              name: "BeReal",
              proved: "People show up daily for social proof.",
            },
            {
              name: "Strava",
              proved: "Competition beats good intentions, every time.",
            },
            {
              name: "Duolingo",
              proved: "A streak will get someone out of bed.",
            },
          ].map((item) => (
            <div key={item.name} className="border-t-2 border-quest-green pt-5">
              <p className="display text-xl text-ink">{item.name}</p>
              <p className="mt-2 text-ink-dim">{item.proved}</p>
            </div>
          ))}
        </div>
        <p className="mt-12 max-w-3xl text-lg text-ink">
          Most environmental apps teach, track or nudge. EcoQuest is the only one
          that combines verified real-world action with social competition — and
          the verification is what makes the competition mean anything.
        </p>
      </Section>

      {/* Core loop */}
      <Section id="how-it-works">
        <Eyebrow>The loop</Eyebrow>
        <H2>Five steps, about thirty seconds</H2>
        <Lead>
          The whole product is one loop, tightened until nothing gets in the way of
          the shutter.
        </Lead>
        <ol className="mt-14 grid gap-8 sm:grid-cols-2 lg:grid-cols-5">
          {LOOP.map((item) => (
            <li key={item.step}>
              <p className="display tabular text-sm text-quest-green-deep">
                {item.step}
              </p>
              <h3 className="display mt-2 text-lg text-ink">{item.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-ink-dim">{item.body}</p>
            </li>
          ))}
        </ol>
      </Section>

      {/* Verification — the technical differentiator */}
      <Section id="verification" className="bg-deep-forest">
        <div className="grid gap-14 lg:grid-cols-2">
          <div>
            <Eyebrow>The hard part</Eyebrow>
            <H2 dark>Verification you can see</H2>
            <Lead dark>
              A black-box &ldquo;approved&rdquo; invites distrust. So EcoQuest shows
              you exactly what the model saw: a labelled box on every item, the
              material it identified, and how confident it was.
            </Lead>
            <ul className="mt-8 flex flex-col gap-4">
              {[
                "Runs on the phone, not in the cloud — so it works in a park with no signal, and your photos aren’t shipped anywhere to be scored.",
                "Counts individual items rather than judging a scene, so a quest target is a real number and not a vibe.",
                "GPS and a server-side timestamp travel with every submission, which makes a recycled photo much harder to pass off.",
                "Self-reported actions are labelled as such and never counted in city or country totals.",
              ].map((line) => (
                <li key={line} className="flex gap-3 text-bone-dim">
                  <span aria-hidden="true" className="mt-2 size-1.5 shrink-0 rounded-full bg-quest-green" />
                  <span className="leading-relaxed">{line}</span>
                </li>
              ))}
            </ul>
          </div>

          <div className="rounded-xl border border-forest-line bg-forest-surface p-6">
            <p className="text-xs font-semibold tracking-[0.14em] uppercase text-bone-dim">
              What the model returns
            </p>
            <div className="mt-5 flex flex-col gap-3">
              {[
                { label: "Clear plastic bottle", conf: 94, tone: "bg-impact-cyan", bin: "plastic" },
                { label: "Drink can", conf: 91, tone: "bg-gold", bin: "metal" },
                { label: "Crisp packet", conf: 87, tone: "bg-impact-cyan", bin: "plastic" },
                { label: "Cigarette", conf: 71, tone: "bg-streak-fire", bin: "general" },
              ].map((row) => (
                <div key={row.label} className="flex items-center gap-3">
                  <span className={`size-2.5 shrink-0 rounded-full ${row.tone}`} aria-hidden="true" />
                  <span className="flex-1 text-sm text-bone">{row.label}</span>
                  <span className="text-xs text-bone-dim">{row.bin}</span>
                  <span className="display tabular w-10 text-right text-sm text-bone">
                    {row.conf}%
                  </span>
                </div>
              ))}
            </div>
            <div className="mt-6 border-t border-forest-line pt-5">
              <p className="display tabular text-3xl text-quest-green">+180 XP</p>
              <p className="mt-1 text-xs text-bone-dim">
                4 items · 265 g CO₂ avoided · streak kept
              </p>
            </div>
          </div>
        </div>
      </Section>

      {/* Hierarchy */}
      <Section className="bg-page-subtle">
        <Eyebrow>Seven reasons to care about your rank</Eyebrow>
        <H2>World → Country → City → School → Class → Friends → You</H2>
        <Lead>
          Most leaderboards give you one number and one way to lose. This gives
          everyone a level where they can plausibly be winning something.
        </Lead>
        <div className="mt-12 flex flex-wrap items-center gap-2">
          {HIERARCHY.map((level, i) => (
            <span key={level} className="flex items-center gap-2">
              <span
                className={`rounded-full px-4 py-2 text-sm font-semibold ${
                  i === HIERARCHY.length - 1
                    ? "bg-quest-green-deep text-white"
                    : "border border-hairline bg-page text-ink-dim"
                }`}
              >
                {level}
              </span>
              {i < HIERARCHY.length - 1 && (
                <span aria-hidden="true" className="text-hairline">
                  →
                </span>
              )}
            </span>
          ))}
        </div>
      </Section>

      {/* Features */}
      <Section>
        <Eyebrow>What’s in it</Eyebrow>
        <H2>Built to be played, not admired</H2>
        <div className="mt-14 grid gap-10 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((feature) => (
            <div key={feature.title}>
              <h3 className={`display text-lg ${feature.tone}`}>{feature.title}</h3>
              <p className="mt-2 leading-relaxed text-ink-dim">{feature.body}</p>
            </div>
          ))}
        </div>
      </Section>

      {/* B2B teasers */}
      <Section className="bg-page-subtle">
        <Eyebrow>Beyond the app</Eyebrow>
        <H2>The data is worth something to the people who run cities</H2>
        <div className="mt-12 grid gap-6 lg:grid-cols-3">
          {[
            {
              href: "/schools",
              title: "Schools",
              body: "One teacher sets up a league and three hundred students join in an afternoon. Classes compete; the school gets the statistics and a reason to run a real cleanup.",
              cta: "See school mode",
            },
            {
              href: "/cities",
              title: "Cities",
              body: "Anonymised, aggregated maps of where litter actually accumulates — reported by residents, verified by the app, not by a survey once a year.",
              cta: "See the city dashboard",
            },
            {
              href: "/partners",
              title: "Brands",
              body: "Sponsor a quest, put your reward in front of someone at the exact moment they’ve done something good. Always labelled, never disguised as content.",
              cta: "See partnerships",
            },
          ].map((card) => (
            <div
              key={card.href}
              className="flex flex-col rounded-xl border border-hairline bg-page p-7"
            >
              <h3 className="display text-xl text-ink">{card.title}</h3>
              <p className="mt-3 flex-1 leading-relaxed text-ink-dim">{card.body}</p>
              <div className="mt-6">
                <CTA href={card.href} variant="ghost">
                  {card.cta}
                </CTA>
              </div>
            </div>
          ))}
        </div>
      </Section>

      {/* Get the app */}
      <Section id="get-the-app" className="bg-deep-forest">
        <div className="text-center">
          <H2 dark>Don’t just scroll. Make an impact.</H2>
          <Lead dark>
            <span className="mx-auto block text-center">
              EcoQuest is in development. Leave an email and we’ll tell you the day
              it lands — and nothing else.
            </span>
          </Lead>

          <form
            className="mx-auto mt-10 flex max-w-md flex-col gap-3 sm:flex-row"
            /* ponytail: no backend on the marketing site. Point this at whatever
               list tool marketing actually uses — Buttondown, Loops, a Formspree
               endpoint — rather than standing up an API route for one field. */
            action="https://formspree.io/f/REPLACE_ME"
            method="POST"
          >
            <label htmlFor="email" className="sr-only">
              Email address
            </label>
            <input
              id="email"
              type="email"
              name="email"
              required
              autoComplete="email"
              placeholder="you@example.com"
              className="min-h-12 flex-1 rounded-full border border-forest-line bg-forest-surface px-5 text-bone placeholder:text-bone-dim focus:border-quest-green focus:outline-none"
            />
            <button
              type="submit"
              className="min-h-12 rounded-full bg-quest-green px-6 text-sm font-semibold text-deep-forest transition-colors hover:bg-bone"
            >
              Notify me
            </button>
          </form>
          <p className="mt-4 text-xs text-bone-dim">
            One email at launch. No newsletter, no partners, no tracking pixels.
          </p>
        </div>
      </Section>
    </>
  );
}

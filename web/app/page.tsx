import {
  CTA,
  Card,
  Cloud,
  Eyebrow,
  Flower,
  H2,
  Lead,
  PaperEdge,
  Section,
  Stat,
} from "./_components/brand";
import { Hierarchy } from "./_components/hierarchy";
import { PhoneMock } from "./_components/phone-mock";

const LOOP = [
  {
    step: "01",
    title: "Get a quest",
    body: "One a day, the same for everyone, so city-versus-city stays fair. Location-aware ones fire when you’re near a park or a cleanup.",
    tone: "bg-gold",
  },
  {
    step: "02",
    title: "Do it for real",
    body: "Pick up ten bottles. Clear the butts off a playground. Cycle instead of driving. Real actions, not taps.",
    tone: "bg-streak-fire",
  },
  {
    step: "03",
    title: "Photograph the proof",
    body: "One tap to the shutter from anywhere in the app. No caption to write, no feed to curate.",
    tone: "bg-impact-cyan",
  },
  {
    step: "04",
    title: "The AI checks it",
    body: "A detector runs on your phone and counts what it sees, item by item, with the boxes drawn on your photo.",
    tone: "bg-duel-violet",
  },
  {
    step: "05",
    title: "Collect and climb",
    body: "XP, EcoPoints, streak. Then find out where that puts you against your friends, your school and your city.",
    tone: "bg-quest-green",
  },
];

/// Six flat glyphs. Drawn here rather than pulled from an icon set so they all
/// have the same fat stroke as everything else on the page.
const ICONS: Record<string, React.ReactElement> = {
  camera: (
    <>
      <rect x="3" y="7" width="18" height="13" rx="4" />
      <circle cx="12" cy="13.5" r="3.6" />
      <path d="M8.5 7l1.6-3h3.8L15.5 7" />
    </>
  ),
  map: (
    <>
      <path d="M12 21s7-7 7-12a7 7 0 1 0-14 0c0 5 7 12 7 12Z" />
      <circle cx="12" cy="9" r="2.6" />
    </>
  ),
  duel: (
    <>
      <path d="M4 4l10 10M20 4L10 14" />
      <path d="M14 14l6 6M10 14l-6 6" />
    </>
  ),
  flag: (
    <>
      <path d="M6 21V4" />
      <path d="M6 5h11l-2.5 4L17 13H6" />
    </>
  ),
  fire: (
    <>
      <path d="M12 2s5.5 5.5 5.5 10a5.5 5.5 0 0 1-11 0c0-1.8.8-3.3 1.6-4.4C10 6.5 12 4.5 12 2Z" />
      <path d="M12 21a2.6 2.6 0 0 0 2.6-2.6c0-1.7-2.6-3.6-2.6-3.6s-2.6 1.9-2.6 3.6A2.6 2.6 0 0 0 12 21Z" />
    </>
  ),
  season: (
    <>
      <rect x="3" y="5" width="18" height="16" rx="4" />
      <path d="M3 10h18M8 3v4M16 3v4" />
      <path d="M8.5 15.5h3" />
    </>
  ),
};

const FEATURES = [
  {
    icon: "camera",
    title: "AI eco verification",
    body: "A litter detector trained on real photos of real rubbish, running offline on the phone. It counts items, names the material, and tells you which bin it belongs in.",
    tone: "bg-quest-green",
  },
  {
    icon: "map",
    title: "The Eco Map",
    body: "Litter hotspots, recycling points and community cleanups, built from what players actually find. The aggregate is what cities pay for.",
    tone: "bg-impact-cyan",
  },
  {
    icon: "duel",
    title: "Friend duels",
    body: "Plastic collected, streak, XP — side by side with someone you know. Beating an abstract environmental goal motivates nobody. Beating Alex does.",
    tone: "bg-duel-violet",
  },
  {
    icon: "flag",
    title: "City battles",
    body: "Prague versus Amsterdam, updated live. Schools, universities and youth groups field their own teams.",
    tone: "bg-gold",
  },
  {
    icon: "fire",
    title: "Streaks that aren’t the whole app",
    body: "Daily, friend and community streaks run in parallel, so one missed day doesn’t undo everything you’ve built.",
    tone: "bg-streak-fire",
  },
  {
    icon: "season",
    title: "Seasons",
    body: "Thirty-day cycles instead of an endless leaderboard. Rankings reset, badges rotate, and everyone gets another shot at the top.",
    tone: "bg-leaf",
  },
];

export default function Home() {
  return (
    <>
      {/* Hero */}
      {/* Full viewport minus the sticky header, so the whole hero — phone,
          stats and hills — lands on one screen with nothing to scroll for. */}
      <section className="relative flex min-h-[calc(100svh-4.4rem)] items-center overflow-hidden bg-sky">
        <div aria-hidden="true" className="pointer-events-none absolute inset-0">
          {/* sun */}
          <div className="animate-spin-slow absolute -right-16 top-8 size-56 rounded-full bg-gold/70" />
          {/* clouds crossing on their own clock */}
          <Cloud className="animate-drift absolute left-0 top-10 w-40 text-white/80" />
          <Cloud
            className="animate-drift absolute left-0 top-40 w-28 text-white/60"
            style={{ animationDelay: "-12s", animationDuration: "44s" }}
          />
          <Cloud
            className="animate-drift absolute left-0 top-72 w-52 text-white/70"
            style={{ animationDelay: "-26s", animationDuration: "52s" }}
          />
        </div>

        {/* hills */}
        <svg
          viewBox="0 0 1200 200"
          preserveAspectRatio="none"
          aria-hidden="true"
          className="absolute inset-x-0 bottom-0 h-40 w-full"
        >
          <path d="M0 96c140-46 260 20 400 6s240-62 400-40 260 66 400 44v94H0Z" fill="#7CC47F" />
          <path d="M0 140c160-34 280 18 440 6s280-44 420-24 220 42 340 30v48H0Z" fill="#00A855" />
        </svg>

        <div className="relative mx-auto grid w-full max-w-6xl items-center gap-10 px-6 pb-32 pt-10 sm:gap-14 sm:pt-14 lg:grid-cols-[1.05fr_1fr]">
          <div>
            <p className="mb-6 inline-block -rotate-2 rounded-full border-[3px] border-ink bg-bone px-4 py-1.5 text-xs font-extrabold tracking-[0.14em] uppercase shadow-[3px_3px_0_var(--color-ink)]">
              EcoTech · Amsterdam
            </p>
            <h1 className="display text-5xl text-ink sm:text-7xl">
              Save the planet.
              <br />
              <span className="scribble">Beat your friends.</span>
            </h1>
            <p className="mt-5 max-w-xl text-lg font-semibold leading-relaxed text-ink/80">
              EcoQuest turns picking up a bottle into something you get points for,
              argue about, and refuse to lose at. Real actions, checked by the phone
              in your hand, counted for the place you live.
            </p>
            <div className="mt-7 flex flex-wrap gap-4">
              <CTA href="/#get-the-app">Get the app</CTA>
              <CTA href="/schools" variant="ghost-dark">
                Bring it to my school
              </CTA>
            </div>

            <dl className="mt-9 grid max-w-lg grid-cols-3 gap-4">
              {[
                { value: "7", caption: "waste types detected", tone: "text-quest-green-deep" },
                { value: "0", caption: "cloud calls to verify", tone: "text-duel-violet" },
                { value: "30s", caption: "from open to earned", tone: "text-streak-fire" },
              ].map((stat, i) => (
                <div
                  key={stat.caption}
                  className="sticker lift bg-page px-4 py-4"
                  style={{ rotate: `${i === 1 ? 1.5 : -1.5}deg` }}
                >
                  <Stat value={stat.value} caption={stat.caption} tone={stat.tone} />
                </div>
              ))}
            </dl>
          </div>

          <div className="flex justify-center lg:justify-end">
            <PhoneMock />
          </div>
        </div>

        <a
          href="#how-it-works"
          className="absolute inset-x-0 bottom-5 z-10 mx-auto flex w-fit items-center gap-2 text-xs font-extrabold uppercase tracking-[0.14em] text-ink/70"
        >
          Keep going
          <span className="flex size-8 items-center justify-center rounded-full border-[3px] border-ink bg-bone shadow-[3px_3px_0_var(--color-ink)]">
            <svg
              viewBox="0 0 24 24"
              className="size-4"
              fill="none"
              stroke="currentColor"
              strokeWidth="3"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
            >
              <path d="M6 9l6 6 6-6" />
            </svg>
          </span>
        </a>
      </section>


      {/* Positioning */}
      <Section className="bg-page">
        <div className="reveal">
          <Eyebrow>Why this works</Eyebrow>
          <H2>
            Three apps already proved the hard part.
            <br />
            We pointed them at the planet.
          </H2>
        </div>
        <div className="mt-14 grid gap-8 sm:grid-cols-3">
          {[
            {
              name: "BeReal",
              proved: "People show up daily for social proof.",
              tone: "bg-impact-cyan",
              tilt: -1.5,
            },
            {
              name: "Strava",
              proved: "Competition beats good intentions, every time.",
              tone: "bg-gold",
              tilt: 1.2,
            },
            {
              name: "Duolingo",
              proved: "A streak will get someone out of bed.",
              tone: "bg-leaf",
              tilt: -0.8,
            },
          ].map((item) => (
            <div key={item.name} className="reveal">
              <Card className={`${item.tone} h-full`} tilt={item.tilt}>
                <p className="display text-2xl text-ink">{item.name}</p>
                <p className="mt-2 font-semibold text-ink/80">{item.proved}</p>
              </Card>
            </div>
          ))}
        </div>
        <p className="reveal mt-14 max-w-3xl text-xl font-bold leading-relaxed">
          Most environmental apps teach, track or nudge. EcoQuest is the only one
          that combines verified real-world action with social competition — and
          the verification is what makes the competition mean anything.
        </p>
      </Section>

      {/* Core loop */}
      <Section id="how-it-works" className="bg-page-subtle">
        <div className="reveal">
          <Eyebrow tone="bg-streak-fire">The loop</Eyebrow>
          <H2>Five steps, about thirty seconds</H2>
          <Lead>
            The whole product is one loop, tightened until nothing gets in the way
            of the shutter.
          </Lead>
        </div>
        <ol className="mt-14 grid gap-7 sm:grid-cols-2 lg:grid-cols-5">
          {LOOP.map((item, i) => (
            <li key={item.step} className="reveal">
              <Card className="h-full" tilt={i % 2 ? 1.2 : -1.2}>
                <span
                  className={`display flex size-12 items-center justify-center rounded-full border-[3px] border-ink text-lg text-ink shadow-[3px_3px_0_var(--color-ink)] ${item.tone}`}
                >
                  {item.step}
                </span>
                <h3 className="display mt-4 text-xl text-ink">{item.title}</h3>
                <p className="mt-2 text-sm font-semibold leading-relaxed text-ink-dim">
                  {item.body}
                </p>
              </Card>
            </li>
          ))}
        </ol>
      </Section>

      {/* Verification — the technical differentiator */}
      <section id="verification" className="relative bg-deep-forest">
        <PaperEdge flip className="absolute inset-x-0 -top-px text-page-subtle" />
        <div className="mx-auto grid max-w-6xl gap-14 px-6 pb-28 pt-32 lg:grid-cols-2">
          <div className="reveal">
            <Eyebrow tone="bg-quest-green">The hard part</Eyebrow>
            <H2 dark>Verification you can watch happen</H2>
            <Lead dark>
              A black-box “approved” invites distrust. So EcoQuest shows you exactly
              what the model saw: a labelled box on every item, the material it
              identified, and how confident it was.
            </Lead>
            <ul className="mt-8 flex flex-col gap-4">
              {[
                "Runs on the phone, not in the cloud — so it works in a park with no signal, and your photos aren’t shipped anywhere to be scored.",
                "Counts individual items rather than judging a scene, so a quest target is a real number and not a vibe.",
                "GPS and a server-side timestamp travel with every submission, which makes a recycled photo much harder to pass off.",
                "Self-reported actions are labelled as such and never counted in city or country totals.",
              ].map((line) => (
                <li key={line} className="flex gap-3 text-bone-dim">
                  <Flower className="mt-0.5 size-5 shrink-0" petal="#00E676" heart="#0A1F16" />
                  <span className="font-semibold leading-relaxed">{line}</span>
                </li>
              ))}
            </ul>
          </div>

          <div className="reveal self-start rounded-[1.5rem] border-[3px] border-quest-green bg-forest-surface p-7 shadow-[8px_8px_0_var(--color-quest-green)]">
            <p className="text-xs font-extrabold tracking-[0.14em] uppercase text-bone-dim">
              What the model returns
            </p>
            <div className="mt-6 flex flex-col gap-4">
              {[
                { label: "Clear plastic bottle", conf: 94, tone: "bg-impact-cyan", bin: "plastic" },
                { label: "Drink can", conf: 91, tone: "bg-gold", bin: "metal" },
                { label: "Crisp packet", conf: 87, tone: "bg-quest-green", bin: "plastic" },
                { label: "Cigarette", conf: 71, tone: "bg-streak-fire", bin: "general" },
              ].map((row, i) => (
                <div key={row.label}>
                  <div className="flex items-baseline gap-3">
                    <span className="flex-1 text-sm font-bold text-bone">{row.label}</span>
                    <span className="text-xs text-bone-dim">{row.bin}</span>
                    <span className="display tabular w-10 text-right text-sm text-bone">
                      {row.conf}%
                    </span>
                  </div>
                  <div className="mt-1.5 h-3 overflow-hidden rounded-full border-2 border-ink bg-forest-line">
                    <div
                      className={`h-full origin-left animate-[grow-bar_1.4s_ease-out_both] rounded-full ${row.tone}`}
                      style={{ width: `${row.conf}%`, animationDelay: `${i * 0.12}s` }}
                    />
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-7 flex items-end justify-between border-t-2 border-forest-line pt-6">
              <div>
                <p className="display tabular text-4xl text-quest-green">+180 XP</p>
                <p className="mt-1 text-xs text-bone-dim">
                  4 items · 265 g CO₂ avoided · streak kept
                </p>
              </div>
              <Flower className="animate-sway size-12" petal="#00E676" heart="#0A1F16" />
            </div>
          </div>
        </div>
        <PaperEdge className="absolute inset-x-0 -bottom-px text-page" />
      </section>

      {/* Hierarchy */}
      <Section className="bg-page">
        <div className="reveal">
          <Eyebrow tone="bg-duel-violet">Seven reasons to care about your rank</Eyebrow>
          <H2>Pick a level. You’re winning at one of them.</H2>
          <Lead>
            Most leaderboards give you one number and one way to lose. This gives
            everyone a table where they can plausibly be near the top.
          </Lead>
        </div>
        <Hierarchy />
      </Section>

      {/* Features */}
      <Section className="bg-page-subtle">
        <div className="reveal">
          <Eyebrow tone="bg-impact-cyan">What’s in it</Eyebrow>
          <H2>Built to be played, not admired</H2>
        </div>
        <div className="mt-14 grid gap-7 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((feature, i) => (
            <div key={feature.title} className="reveal">
              <Card className="h-full" tilt={i % 2 ? -1 : 1}>
                <span
                  className={`flex size-14 items-center justify-center rounded-2xl border-[3px] border-ink shadow-[4px_4px_0_var(--color-ink)] ${feature.tone}`}
                >
                  <svg
                    viewBox="0 0 24 24"
                    className="size-7 text-ink"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    aria-hidden="true"
                  >
                    {ICONS[feature.icon]}
                  </svg>
                </span>
                <h3 className="display mt-5 text-xl text-ink">{feature.title}</h3>
                <p className="mt-2 font-semibold leading-relaxed text-ink-dim">
                  {feature.body}
                </p>
              </Card>
            </div>
          ))}
        </div>
      </Section>

      {/* B2B teasers */}
      <Section className="bg-page">
        <div className="reveal">
          <Eyebrow tone="bg-gold">Beyond the app</Eyebrow>
          <H2>The data is worth something to the people who run cities</H2>
        </div>
        <div className="mt-14 grid gap-7 lg:grid-cols-3">
          {[
            {
              href: "/schools",
              title: "Schools",
              body: "One teacher sets up a league and three hundred students join in an afternoon. Classes compete; the school gets the statistics and a reason to run a real cleanup.",
              cta: "See school mode",
              tone: "bg-quest-green",
            },
            {
              href: "/cities",
              title: "Cities",
              body: "Anonymised, aggregated maps of where litter actually accumulates — reported by residents, verified by the app, not by a survey once a year.",
              cta: "See the city dashboard",
              tone: "bg-impact-cyan",
            },
            {
              href: "/partners",
              title: "Brands",
              body: "Sponsor a quest, put your reward in front of someone at the exact moment they’ve done something good. Always labelled, never disguised as content.",
              cta: "See partnerships",
              tone: "bg-gold",
            },
          ].map((card, i) => (
            <div key={card.href} className="reveal">
              <Card className="flex h-full flex-col" tilt={i === 1 ? 1 : -1}>
                <span className={`h-3 w-16 rounded-full border-2 border-ink ${card.tone}`} />
                <h3 className="display mt-4 text-2xl text-ink">{card.title}</h3>
                <p className="mt-3 flex-1 font-semibold leading-relaxed text-ink-dim">
                  {card.body}
                </p>
                <div className="mt-6">
                  <CTA href={card.href} variant="ghost">
                    {card.cta}
                  </CTA>
                </div>
              </Card>
            </div>
          ))}
        </div>
      </Section>

      {/* Get the app */}
      <section id="get-the-app" className="relative overflow-hidden bg-leaf">
        <Flower className="animate-float absolute -left-10 top-10 size-40 opacity-40" petal="#00A855" heart="#EAF7EC" />
        <Flower className="animate-float absolute -right-8 bottom-8 size-52 opacity-40" petal="#00A855" heart="#EAF7EC" />

        <div className="relative mx-auto max-w-6xl px-6 py-24 text-center sm:py-32">
          <h2 className="display text-4xl text-ink sm:text-6xl">
            Don’t just scroll.
            <br />
            <span className="scribble">Make an impact.</span>
          </h2>
          <p className="mx-auto mt-6 max-w-xl text-lg font-semibold text-ink/80">
            EcoQuest is in development. Leave an email and we’ll tell you the day it
            lands — and nothing else.
          </p>

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
              className="min-h-12 flex-1 rounded-full border-[3px] border-ink bg-page px-5 font-semibold text-ink shadow-[5px_5px_0_var(--color-ink)] placeholder:text-ink-dim focus:outline-none focus:ring-4 focus:ring-gold"
            />
            <button
              type="submit"
              className="press min-h-12 rounded-full border-[3px] border-ink bg-gold px-6 text-sm font-extrabold text-ink shadow-[5px_5px_0_var(--color-ink)]"
            >
              Notify me
            </button>
          </form>
          <p className="mt-5 text-xs font-bold text-ink/70">
            One email at launch. No newsletter, no partners, no tracking pixels.
          </p>
        </div>
      </section>
    </>
  );
}

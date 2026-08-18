import type { ReactNode } from "react";
import { Flower } from "./brand";

/// The hero's product shot. Three screens share one 15s CSS loop — home, the
/// camera check, the city table — so the phone plays the whole game by itself.
/// Pure markup rather than screenshots: sharp at any size, weighs nothing, and
/// doesn't go stale the next time the app moves.
function Screen({ delay, children }: { delay: string; children: ReactNode }) {
  return (
    <div
      className="animate-screens absolute inset-0 rounded-[1.6rem] bg-forest-surface p-5"
      style={{ animationDelay: delay }}
    >
      {children}
    </div>
  );
}

const RANKS = [
  { name: "Amsterdam", pct: 100, tone: "bg-gold", value: "18 402" },
  { name: "Rotterdam", pct: 82, tone: "bg-impact-cyan", value: "15 110" },
  { name: "Plzeň — you", pct: 71, tone: "bg-quest-green", value: "13 067" },
  { name: "Utrecht", pct: 58, tone: "bg-duel-violet", value: "10 640" },
];

const READOUT = [
  { label: "Clear plastic bottle", bin: "plastic", conf: "94%" },
  { label: "Drink can", bin: "metal", conf: "91%" },
  { label: "Crisp packet", bin: "plastic", conf: "87%" },
];

export function PhoneMock() {
  return (
    <div className="relative">
      {/* Things orbiting the phone, so this corner of the hero is never still. */}
      <div
        className="animate-float absolute -left-6 top-16 z-20 rounded-full border-[3px] border-ink bg-gold px-3 py-1.5 text-xs font-extrabold text-ink shadow-[4px_4px_0_var(--color-ink)] sm:-left-12"
        style={{ "--tilt": "-8deg" } as React.CSSProperties}
        aria-hidden="true"
      >
        +150 XP
      </div>
      <div
        className="animate-float absolute -right-4 bottom-24 z-20 rounded-full border-[3px] border-ink bg-streak-fire px-3 py-1.5 text-xs font-extrabold text-bone shadow-[4px_4px_0_var(--color-ink)] sm:-right-10"
        style={{ animationDelay: "-3.5s", "--tilt": "6deg" } as React.CSSProperties}
        aria-hidden="true"
      >
        12 day streak
      </div>
      <Flower className="animate-spin-slow absolute -right-6 -top-8 z-20 size-20" />

      <div
        className="relative w-[300px] rounded-[2.2rem] border-[4px] border-ink bg-deep-forest p-3 shadow-[10px_10px_0_var(--color-ink)]"
        role="img"
        aria-label="The EcoQuest app cycling through today's quest, the on-device litter check, and the city leaderboard."
      >
        <div className="relative h-[470px]">
          {/* 1 — home */}
          <Screen delay="0s">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-bone-dim">Hey Seb</span>
              <span className="flex items-center gap-1 rounded-full border-2 border-streak-fire/60 bg-streak-fire/15 px-2 py-1 text-xs font-extrabold text-streak-fire">
                <svg
                  viewBox="0 0 24 24"
                  className="animate-flicker size-3 origin-bottom"
                  fill="currentColor"
                  aria-hidden="true"
                >
                  <path d="M12 2s5 5 5 9a5 5 0 0 1-10 0c0-1.5.6-2.7 1.2-3.6C8.9 8.7 12 6 12 2Z" />
                </svg>
                12
              </span>
            </div>

            <div className="mt-6 text-center">
              <p className="display tabular text-5xl text-bone">4 820</p>
              <p className="mt-1 text-[10px] font-extrabold tracking-[0.16em] uppercase text-bone-dim">
                total xp
              </p>
            </div>

            <div className="mt-5">
              <div className="flex items-baseline justify-between text-[10px] font-bold">
                <span className="tracking-[0.12em] uppercase text-quest-green">level 7</span>
                <span className="tabular text-bone-dim">570 / 1 750 XP</span>
              </div>
              <div className="mt-2 h-3 overflow-hidden rounded-full border-2 border-ink bg-forest-line">
                <div className="h-full w-[33%] origin-left animate-[grow-bar_2.4s_ease-out_both] rounded-full bg-quest-green" />
              </div>
            </div>

            <div className="mt-6 rounded-2xl border-[3px] border-ink bg-deep-forest p-4 shadow-[4px_4px_0_var(--color-quest-green)]">
              <p className="text-[10px] font-extrabold tracking-[0.16em] uppercase text-bone-dim">
                today&rsquo;s quest
              </p>
              <p className="display mt-2 text-lg text-bone">Collect 10 pieces of plastic</p>
              <div className="mt-3 flex flex-wrap gap-2">
                <span className="rounded-full border-2 border-quest-green/50 bg-quest-green/15 px-2.5 py-1 text-[10px] font-extrabold text-quest-green">
                  +150 XP
                </span>
                <span className="rounded-full border-2 border-impact-cyan/50 bg-impact-cyan/15 px-2.5 py-1 text-[10px] font-extrabold text-impact-cyan">
                  +25 EcoPoints
                </span>
              </div>
              <div className="mt-4 flex min-h-9 items-center justify-center rounded-full border-[3px] border-ink bg-quest-green text-xs font-extrabold text-ink">
                Start quest
              </div>
            </div>

            <div className="mt-4 flex items-center justify-between rounded-2xl border-[3px] border-ink bg-quest-green/15 px-4 py-3">
              <span className="text-xs font-bold text-bone">You in Plzeň this week</span>
              <span className="display tabular text-xl text-gold">#3</span>
            </div>
          </Screen>

          {/* 2 — the check */}
          <Screen delay="-10s">
            <p className="text-[10px] font-extrabold tracking-[0.16em] uppercase text-bone-dim">
              checking on device
            </p>

            <div className="relative mt-3 h-[230px] overflow-hidden rounded-2xl border-[3px] border-ink">
              {/* a cartoon pile of rubbish on grass, drawn rather than photographed */}
              <svg viewBox="0 0 240 200" className="absolute inset-0 size-full" aria-hidden="true">
                <rect width="240" height="200" fill="#33452f" />
                <path d="M0 150c40-14 80 6 120-4s80-18 120-2v56H0Z" fill="#3f5a38" />
                <g stroke="#14261C" strokeWidth="3">
                  <rect x="38" y="86" width="34" height="70" rx="12" fill="#9fe0f5" />
                  <rect x="46" y="70" width="18" height="18" rx="5" fill="#00c2f0" />
                  <rect x="104" y="104" width="40" height="54" rx="8" fill="#ffc53d" />
                  <ellipse cx="124" cy="104" rx="20" ry="7" fill="#ffdc8a" />
                  <path d="M168 156c-8-22 4-40 22-44 10 16 8 36-4 44Z" fill="#ff8a5c" />
                </g>
              </svg>

              {/* the boxes the model drew */}
              <span className="absolute left-[13%] top-[30%] h-[46%] w-[19%] rounded-lg border-[3px] border-quest-green">
                <span className="absolute -top-4 left-0 rounded bg-quest-green px-1 text-[9px] font-extrabold text-ink">
                  bottle 94%
                </span>
              </span>
              <span className="absolute left-[42%] top-[48%] h-[30%] w-[19%] rounded-lg border-[3px] border-gold">
                <span className="absolute -top-4 left-0 rounded bg-gold px-1 text-[9px] font-extrabold text-ink">
                  can 91%
                </span>
              </span>
              <span className="absolute left-[68%] top-[52%] h-[26%] w-[17%] rounded-lg border-[3px] border-streak-fire">
                <span className="absolute -top-4 left-0 rounded bg-streak-fire px-1 text-[9px] font-extrabold text-bone">
                  wrapper 87%
                </span>
              </span>

              {/* ponytail: the sweep is what "verifying" looks like without a spinner.
                  A plain translate loop, not synced to the screen cycle — it reads
                  the same whenever you catch it. */}
              <span
                className="absolute inset-x-0 top-0 h-16 animate-[bob_2.6s_ease-in-out_infinite] bg-gradient-to-b from-transparent via-quest-green/30 to-transparent"
                style={{ animationDuration: "2.6s" }}
              />
            </div>

            <div className="mt-4 flex flex-col gap-2">
              {READOUT.map((row) => (
                <div key={row.label} className="flex items-center gap-2 text-[11px]">
                  <span className="flex-1 font-bold text-bone">{row.label}</span>
                  <span className="text-bone-dim">{row.bin}</span>
                  <span className="display tabular w-9 text-right text-bone">{row.conf}</span>
                </div>
              ))}
            </div>

            <div className="mt-4 rounded-2xl border-[3px] border-ink bg-quest-green px-4 py-3 text-center">
              <p className="display tabular text-2xl text-ink">+180 XP</p>
              <p className="text-[10px] font-bold text-ink/70">3 items · 265 g CO₂ avoided</p>
            </div>
          </Screen>

          {/* 3 — the table */}
          <Screen delay="-5s">
            <p className="text-[10px] font-extrabold tracking-[0.16em] uppercase text-bone-dim">
              city battle · season 4
            </p>
            <p className="display mt-2 text-2xl text-bone">Who is winning</p>

            <div className="mt-6 flex flex-col gap-4">
              {RANKS.map((row, i) => (
                <div key={row.name}>
                  <div className="flex items-baseline justify-between text-[11px] font-bold">
                    <span className={i === 2 ? "text-quest-green" : "text-bone"}>
                      {i + 1}. {row.name}
                    </span>
                    <span className="tabular text-bone-dim">{row.value}</span>
                  </div>
                  <div className="mt-1.5 h-4 overflow-hidden rounded-full border-2 border-ink bg-forest-line">
                    <div
                      className={`h-full origin-left animate-[grow-bar_1.8s_cubic-bezier(0.2,1.4,0.4,1)_both] rounded-full ${row.tone}`}
                      style={{ width: `${row.pct}%`, animationDelay: `${i * 0.14}s` }}
                    />
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-7 rounded-2xl border-[3px] border-ink bg-duel-violet/25 p-4">
              <p className="text-[11px] font-bold text-bone">
                Beat Amsterdam by <span className="text-gold">5 335 XP</span> and Plzeň takes
                the season.
              </p>
              <p className="mt-2 text-[10px] text-bone-dim">4 days 06:12 left</p>
            </div>
          </Screen>
        </div>
      </div>
    </div>
  );
}

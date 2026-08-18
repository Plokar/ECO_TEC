"use client";

import { useState } from "react";

/// The seven-level leaderboard, as a thing you poke rather than a diagram you
/// read. Picking a level swaps the panel underneath it.
const LEVELS = [
  {
    label: "World",
    tone: "bg-duel-violet text-bone",
    rank: "#412 908",
    of: "of 2.1 M players",
    blurb: "Nobody wins the world. It is there so the number keeps meaning something after you have won everything else.",
    rows: [
      { name: "Tokyo", value: "1 402 880" },
      { name: "Amsterdam", value: "988 140" },
      { name: "Prague", value: "902 615" },
    ],
  },
  {
    label: "Country",
    tone: "bg-impact-cyan text-ink",
    rank: "#8 214",
    of: "of 96 400 in Czechia",
    blurb: "Country tables run on the season clock and reset with it, so a slow start in March is not a lost year.",
    rows: [
      { name: "Czechia", value: "902 615" },
      { name: "Netherlands", value: "864 220" },
      { name: "Poland", value: "701 388" },
    ],
  },
  {
    label: "City",
    tone: "bg-gold text-ink",
    rank: "#3",
    of: "of 4 180 in Plzeň",
    blurb: "The level people actually argue about. City-versus-city is the part that gets a mayor to call you back.",
    rows: [
      { name: "Plzeň", value: "13 067" },
      { name: "Brno", value: "12 400" },
      { name: "Ostrava", value: "9 980" },
    ],
  },
  {
    label: "School",
    tone: "bg-quest-green text-ink",
    rank: "#1",
    of: "of 22 schools in the region",
    blurb: "One teacher, one join code, three hundred students by Friday. This is how the whole thing spreads.",
    rows: [
      { name: "SPŠE Plzeň", value: "48 320" },
      { name: "Gymnázium Sušice", value: "41 006" },
      { name: "SOŠ Klatovy", value: "36 774" },
    ],
  },
  {
    label: "Class",
    tone: "bg-streak-fire text-bone",
    rank: "#2",
    of: "of 14 classes",
    blurb: "Small enough that everyone can see their own contribution, which is exactly why the class table is the one that moves.",
    rows: [
      { name: "2.P", value: "14 820" },
      { name: "3.A", value: "12 420" },
      { name: "1.B", value: "10 230" },
    ],
  },
  {
    label: "Friends",
    tone: "bg-duel-violet text-bone",
    rank: "#2",
    of: "of 9 friends",
    blurb: "Beating an abstract environmental goal motivates nobody. Beating Alex, who you will see at lunch, motivates everybody.",
    rows: [
      { name: "Alex", value: "5 140" },
      { name: "You", value: "4 820" },
      { name: "Marek", value: "3 990" },
    ],
  },
  {
    label: "You",
    tone: "bg-ink text-bone",
    rank: "Level 7",
    of: "570 / 1 750 XP to level 8",
    blurb: "The only table you are guaranteed to be winning. Yesterday is the opponent, and yesterday never improves.",
    rows: [
      { name: "This week", value: "1 240" },
      { name: "Last week", value: "980" },
      { name: "Best week", value: "1 610" },
    ],
  },
];

export function Hierarchy() {
  const [active, setActive] = useState(2);
  const level = LEVELS[active];

  return (
    <div className="mt-12">
      <div className="flex flex-wrap items-center gap-2">
        {LEVELS.map((item, i) => (
          <span key={item.label} className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setActive(i)}
              aria-pressed={i === active}
              className={`press min-h-11 rounded-full border-[3px] border-ink px-4 text-sm font-extrabold shadow-[4px_4px_0_var(--color-ink)] ${
                i === active ? `${item.tone} scale-110` : "bg-page text-ink-dim"
              }`}
            >
              {item.label}
            </button>
            {i < LEVELS.length - 1 && (
              <span aria-hidden="true" className="display text-ink/30">
                →
              </span>
            )}
          </span>
        ))}
      </div>

      <div className="sticker mt-10 grid gap-8 bg-page p-7 sm:p-9 lg:grid-cols-2">
        <div>
          <p className="text-xs font-extrabold tracking-[0.14em] uppercase text-ink-dim">
            Your standing · {level.label}
          </p>
          <p className="display tabular mt-3 text-5xl text-ink">{level.rank}</p>
          <p className="mt-1 text-sm font-bold text-ink-dim">{level.of}</p>
          <p className="mt-5 max-w-md leading-relaxed text-ink-dim">{level.blurb}</p>
        </div>

        <ul className="flex flex-col gap-3 self-center">
          {level.rows.map((row, i) => (
            <li
              key={row.name}
              className="flex items-center gap-3 rounded-2xl border-[3px] border-ink bg-page-subtle px-4 py-3"
            >
              <span className="display tabular w-6 text-ink/40">{i + 1}</span>
              <span className="flex-1 font-bold text-ink">{row.name}</span>
              <span className="display tabular text-ink">{row.value}</span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}

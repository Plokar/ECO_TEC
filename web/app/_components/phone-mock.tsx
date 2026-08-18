/// The hero’s product shot: today’s quest as the app actually renders it.
/// Pure markup rather than a screenshot, so it stays sharp at any size, weighs
/// nothing, and doesn’t go stale the next time the UI moves.
export function PhoneMock() {
  return (
    <div
      className="w-[300px] rounded-[2.2rem] border border-forest-line bg-deep-forest p-3 shadow-2xl"
      role="img"
      aria-label="EcoQuest app showing today’s quest: collect 10 pieces of plastic, worth 150 XP, with the player ranked third in their city."
    >
      <div className="rounded-[1.7rem] bg-forest-surface p-5">
        {/* status row */}
        <div className="flex items-center justify-between">
          <span className="text-xs text-bone-dim">Hey Seb</span>
          <span className="flex items-center gap-1 rounded-full bg-streak-fire/15 px-2 py-1 text-xs font-semibold text-streak-fire">
            <svg viewBox="0 0 24 24" className="size-3" fill="currentColor" aria-hidden="true">
              <path d="M12 2s5 5 5 9a5 5 0 0 1-10 0c0-1.5.6-2.7 1.2-3.6C8.9 8.7 12 6 12 2Z" />
            </svg>
            12
          </span>
        </div>

        {/* hero number */}
        <div className="mt-6 text-center">
          <p className="display tabular text-4xl text-bone">4 820</p>
          <p className="mt-1 text-[10px] font-semibold tracking-[0.16em] uppercase text-bone-dim">
            total xp
          </p>
        </div>

        {/* level bar */}
        <div className="mt-5">
          <div className="flex items-baseline justify-between text-[10px]">
            <span className="font-semibold tracking-[0.12em] uppercase text-quest-green">
              level 7
            </span>
            <span className="tabular text-bone-dim">570 / 1 750 XP</span>
          </div>
          <div className="mt-2 h-2 overflow-hidden rounded-full bg-forest-line">
            <div className="h-full w-[33%] rounded-full bg-quest-green" />
          </div>
        </div>

        {/* quest card */}
        <div className="mt-6 rounded-xl border border-forest-line bg-deep-forest p-4">
          <p className="text-[10px] font-semibold tracking-[0.16em] uppercase text-bone-dim">
            today’s quest
          </p>
          <p className="display mt-2 text-base text-bone">
            Collect 10 pieces of plastic
          </p>
          <div className="mt-3 flex flex-wrap gap-2">
            <span className="rounded-full bg-quest-green/15 px-2.5 py-1 text-[10px] font-semibold text-quest-green">
              +150 XP
            </span>
            <span className="rounded-full bg-impact-cyan/15 px-2.5 py-1 text-[10px] font-semibold text-impact-cyan">
              +25 EcoPoints
            </span>
          </div>
          <div className="mt-4 flex min-h-9 items-center justify-center rounded-full bg-quest-green text-xs font-semibold text-deep-forest">
            Start quest
          </div>
        </div>

        {/* rank */}
        <div className="mt-4 flex items-center justify-between rounded-xl border border-quest-green/40 bg-quest-green/10 px-4 py-3">
          <span className="text-xs text-bone">You in Plzeň this week</span>
          <span className="display tabular text-lg text-gold">#3</span>
        </div>
      </div>
    </div>
  );
}

import Image from "next/image";
import Link from "next/link";
import type { ReactNode } from "react";

/// The flower from the wordmark, redrawn as five petals so it can spin, sit in
/// a bullet point, or be scattered across a hero without loading an image.
export function Flower({
  className = "size-8",
  petal = "#7CC47F",
  heart = "#FFF8EC",
}: {
  className?: string;
  petal?: string;
  heart?: string;
}) {
  return (
    <svg viewBox="0 0 100 100" className={className} aria-hidden="true">
      <g fill={petal}>
        {[0, 72, 144, 216, 288].map((deg) => (
          <ellipse
            key={deg}
            cx="50"
            cy="26"
            rx="19"
            ry="23"
            transform={`rotate(${deg} 50 50)`}
          />
        ))}
      </g>
      <circle cx="50" cy="50" r="12" fill={heart} />
    </svg>
  );
}

export function Cloud({
  className = "w-40",
  style,
}: {
  className?: string;
  style?: React.CSSProperties;
}) {
  return (
    <svg viewBox="0 0 200 80" className={className} style={style} aria-hidden="true">
      <path
        d="M40 70c-16 0-29-11-29-25S24 20 40 20c4-11 15-18 28-18 15 0 28 10 31 24 3-2 7-3 11-3 13 0 24 10 24 23s-11 24-24 24H40Z"
        fill="currentColor"
      />
    </svg>
  );
}

/// A wobbly hand-cut edge between two bands. `flip` puts the bite on top.
export function PaperEdge({
  className = "",
  flip = false,
}: {
  className?: string;
  flip?: boolean;
}) {
  return (
    <div className={`${className} ${flip ? "rotate-180" : ""} leading-[0]`}>
      <svg viewBox="0 0 1200 60" preserveAspectRatio="none" className="h-10 w-full sm:h-14">
        <path
          d="M0 0c86 34 172 51 258 51S430 34 516 17s172-17 258 3 172 40 258 40 168-20 168-20V60H0Z"
          fill="currentColor"
        />
      </svg>
    </div>
  );
}

export function Section({
  children,
  className = "",
  id,
}: {
  children: ReactNode;
  className?: string;
  id?: string;
}) {
  return (
    <section id={id} className={`relative ${className}`}>
      <div className="mx-auto max-w-6xl px-6 py-20 sm:py-28">{children}</div>
    </section>
  );
}

/// A stuck-on label, never level with the grid.
export function Eyebrow({
  children,
  tone = "bg-gold",
}: {
  children: ReactNode;
  tone?: string;
}) {
  return (
    <p
      className={`mb-5 inline-block -rotate-2 rounded-full border-[3px] border-ink px-4 py-1.5 text-xs font-extrabold tracking-[0.14em] uppercase text-ink shadow-[3px_3px_0_var(--color-ink)] ${tone}`}
    >
      {children}
    </p>
  );
}

export function H2({ children, dark = false }: { children: ReactNode; dark?: boolean }) {
  return (
    <h2 className={`display text-3xl sm:text-5xl ${dark ? "text-bone" : "text-ink"}`}>
      {children}
    </h2>
  );
}

export function Lead({ children, dark = false }: { children: ReactNode; dark?: boolean }) {
  return (
    <p
      className={`mt-5 max-w-2xl text-lg leading-relaxed ${
        dark ? "text-bone-dim" : "text-ink-dim"
      }`}
    >
      {children}
    </p>
  );
}

export function CTA({
  href,
  children,
  variant = "primary",
}: {
  href: string;
  children: ReactNode;
  variant?: "primary" | "ghost" | "ghost-dark";
}) {
  const styles = {
    primary: "bg-quest-green text-ink",
    ghost: "bg-page text-ink",
    "ghost-dark": "bg-bone text-ink",
  }[variant];

  return (
    <Link
      href={href}
      className={`press inline-flex min-h-12 items-center justify-center rounded-full border-[3px] border-ink px-6 text-sm font-extrabold shadow-[5px_5px_0_var(--color-ink)] ${styles}`}
    >
      {children}
    </Link>
  );
}

/// A card that looks cut out and stuck down. `tilt` keeps a grid of them from
/// lining up like a table.
export function Card({
  children,
  className = "",
  tilt = 0,
}: {
  children: ReactNode;
  className?: string;
  tilt?: number;
}) {
  return (
    <div
      className={`sticker lift bg-page p-7 ${className}`}
      style={tilt ? { rotate: `${tilt}deg` } : undefined}
    >
      {children}
    </div>
  );
}

/// One metric. Tabular figures so a row of these lines up.
export function Stat({
  value,
  caption,
  tone = "text-quest-green-deep",
}: {
  value: string;
  caption: string;
  tone?: string;
}) {
  return (
    <div>
      <p className={`display tabular text-4xl sm:text-5xl ${tone}`}>{value}</p>
      <p className="mt-1 text-xs font-extrabold tracking-[0.12em] uppercase text-ink-dim">
        {caption}
      </p>
    </div>
  );
}

export function Wordmark({ dark = false }: { dark?: boolean }) {
  return (
    <Link
      href="/"
      className="inline-block transition-transform hover:-rotate-2 hover:scale-105"
      aria-label="EcoQuest home"
    >
      <Image
        src={dark ? "/logo-bone.png" : "/logo-ink.png"}
        alt="EcoQuest"
        width={563}
        height={352}
        priority
        className="h-11 w-auto"
      />
    </Link>
  );
}

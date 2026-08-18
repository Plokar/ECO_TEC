import Link from "next/link";
import type { ReactNode } from "react";

/// The symbol: a leaf whose outline doubles as a location pin — nature plus a
/// real place, which is what the product actually is. Legible down to 16px.
export function EcoQuestMark({
  className = "h-7 w-7",
  tone = "currentColor",
}: {
  className?: string;
  tone?: string;
}) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7Z"
        fill={tone}
      />
      <path
        d="M12 15.5V8.2m0 0c0-1.6 1.2-2.9 2.9-2.9.2 1.9-1.1 3.3-2.9 3.4Zm0 2.6c-.1-1.7-1.4-3-3.1-2.8-.1 1.7 1.3 3 3.1 2.8Z"
        stroke="#0A1F16"
        strokeWidth="1.3"
        strokeLinecap="round"
      />
    </svg>
  );
}

export function Wordmark({ dark = false }: { dark?: boolean }) {
  return (
    <Link href="/" className="flex items-center gap-2" aria-label="EcoQuest home">
      <EcoQuestMark tone="#00E676" />
      <span className="text-xl tracking-tight">
        <span className={dark ? "font-semibold text-bone" : "font-semibold text-ink"}>
          eco
        </span>
        <span className="display text-quest-green-deep">Quest</span>
      </span>
    </Link>
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
    <section id={id} className={className}>
      <div className="mx-auto max-w-6xl px-6 py-20 sm:py-28">{children}</div>
    </section>
  );
}

export function Eyebrow({ children }: { children: ReactNode }) {
  return (
    <p className="mb-4 text-xs font-semibold tracking-[0.16em] uppercase text-quest-green-deep">
      {children}
    </p>
  );
}

export function H2({ children, dark = false }: { children: ReactNode; dark?: boolean }) {
  return (
    <h2
      className={`display text-3xl sm:text-4xl ${dark ? "text-bone" : "text-ink"}`}
    >
      {children}
    </h2>
  );
}

export function Lead({ children, dark = false }: { children: ReactNode; dark?: boolean }) {
  return (
    <p
      className={`mt-4 max-w-2xl text-lg leading-relaxed ${
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
    primary:
      "bg-quest-green-deep text-white hover:bg-quest-green hover:text-deep-forest",
    ghost: "border border-hairline text-ink hover:border-quest-green-deep",
    "ghost-dark": "border border-forest-line text-bone hover:border-quest-green",
  }[variant];

  return (
    <Link
      href={href}
      className={`inline-flex min-h-12 items-center justify-center rounded-full px-6 text-sm font-semibold transition-colors ${styles}`}
    >
      {children}
    </Link>
  );
}

/// One metric. Tabular figures so a row of these lines up.
export function Stat({
  value,
  caption,
  tone = "text-quest-green",
}: {
  value: string;
  caption: string;
  tone?: string;
}) {
  return (
    <div>
      <p className={`display tabular text-4xl ${tone}`}>{value}</p>
      <p className="mt-1 text-xs font-semibold tracking-[0.12em] uppercase text-bone-dim">
        {caption}
      </p>
    </div>
  );
}

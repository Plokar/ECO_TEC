"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { CTA, Wordmark } from "./brand";

const NAV = [
  { href: "/schools", label: "For schools" },
  { href: "/cities", label: "For cities" },
  { href: "/partners", label: "For brands" },
  { href: "/pricing", label: "Pricing" },
  { href: "/about", label: "About" },
];

export function SiteHeader() {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-50 border-b-[3px] border-ink bg-page/95 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center gap-6 px-6 py-3">
        <Wordmark />

        <nav className="hidden flex-1 items-center gap-6 md:flex" aria-label="Main">
          {NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              aria-current={pathname === item.href ? "page" : undefined}
              className={`text-sm font-bold transition-transform hover:-rotate-2 hover:scale-105 ${
                pathname === item.href
                  ? "scribble text-ink"
                  : "text-ink-dim hover:text-ink"
              }`}
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="ml-auto hidden md:block">
          <CTA href="/#get-the-app">Get the app</CTA>
        </div>

        <button
          type="button"
          onClick={() => setOpen(!open)}
          aria-expanded={open}
          aria-label="Toggle menu"
          className="press ml-auto flex size-12 items-center justify-center rounded-full border-[3px] border-ink bg-gold shadow-[4px_4px_0_var(--color-ink)] md:hidden"
        >
          <svg viewBox="0 0 24 24" className="size-6" fill="none" aria-hidden="true">
            <path
              d={open ? "M6 6l12 12M18 6L6 18" : "M4 7h16M4 12h16M4 17h16"}
              stroke="currentColor"
              strokeWidth="2.4"
              strokeLinecap="round"
            />
          </svg>
        </button>
      </div>

      {open && (
        <nav className="border-t-[3px] border-ink bg-page-subtle px-6 py-4 md:hidden" aria-label="Mobile">
          <ul className="flex flex-col">
            {NAV.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  onClick={() => setOpen(false)}
                  className="flex min-h-12 items-center font-bold text-ink"
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
          <div className="mt-3">
            <CTA href="/#get-the-app">Get the app</CTA>
          </div>
        </nav>
      )}
    </header>
  );
}

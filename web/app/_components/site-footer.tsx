import Link from "next/link";
import { EcoQuestMark } from "./brand";

const COLUMNS = [
  {
    title: "Product",
    links: [
      { href: "/#how-it-works", label: "How it works" },
      { href: "/#verification", label: "AI verification" },
      { href: "/pricing", label: "Pricing" },
    ],
  },
  {
    title: "Business",
    links: [
      { href: "/schools", label: "For schools" },
      { href: "/cities", label: "For cities" },
      { href: "/partners", label: "For brands" },
    ],
  },
  {
    title: "Company",
    links: [
      { href: "/about", label: "About EcoTech" },
      { href: "/about#contact", label: "Contact" },
      { href: "/about#impact-method", label: "How we count impact" },
    ],
  },
];

export function SiteFooter() {
  return (
    <footer className="bg-deep-forest text-bone-dim">
      <div className="mx-auto max-w-6xl px-6 py-16">
        <div className="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <div className="flex items-center gap-2">
              <EcoQuestMark tone="#00E676" />
              <span className="text-lg">
                <span className="font-semibold text-bone">eco</span>
                <span className="display text-quest-green">Quest</span>
              </span>
            </div>
            <p className="mt-4 text-sm leading-relaxed">
              Save the planet. Beat your friends.
            </p>
          </div>

          {COLUMNS.map((column) => (
            <div key={column.title}>
              <h3 className="text-xs font-semibold tracking-[0.14em] uppercase text-bone">
                {column.title}
              </h3>
              <ul className="mt-4 flex flex-col gap-1">
                {column.links.map((link) => (
                  <li key={link.href}>
                    <Link
                      href={link.href}
                      className="flex min-h-9 items-center text-sm transition-colors hover:text-quest-green"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-14 flex flex-col gap-3 border-t border-forest-line pt-8 text-xs sm:flex-row sm:items-center sm:justify-between">
          <p>© {new Date().getFullYear()} EcoTech B.V. · Amsterdam, Netherlands</p>
          <p>
            CO₂ figures are estimates from per-material averages, shown with their
            basis in the app.
          </p>
        </div>
      </div>
    </footer>
  );
}

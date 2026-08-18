import Image from "next/image";
import Link from "next/link";
import { Flower, PaperEdge } from "./brand";

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
    <footer className="relative bg-deep-forest text-bone-dim">
      {/* The bite is cut out of the footer itself and rises into whatever band
          sits above it, so this works on every page without knowing that band's
          colour. */}
      <PaperEdge className="pointer-events-none absolute inset-x-0 bottom-full -mb-px text-deep-forest" />

      <Flower
        className="animate-sway absolute right-[8%] top-16 size-16 opacity-70"
        petal="#1e3d2c"
        heart="#12291e"
      />
      <Flower
        className="animate-sway absolute left-[6%] top-40 size-10 opacity-70"
        petal="#1e3d2c"
        heart="#12291e"
      />

      <div className="relative mx-auto max-w-6xl px-6 pb-16 pt-16">
        <div className="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <Image
              src="/logo-bone.png"
              alt="EcoQuest"
              width={561}
              height={352}
              className="h-14 w-auto"
            />
            <p className="display mt-5 text-lg text-bone">
              Save the planet.
              <br />
              Beat your friends.
            </p>
          </div>

          {COLUMNS.map((column) => (
            <div key={column.title}>
              <h3 className="display text-sm tracking-[0.14em] uppercase text-quest-green">
                {column.title}
              </h3>
              <ul className="mt-4 flex flex-col gap-1">
                {column.links.map((link) => (
                  <li key={link.href}>
                    <Link
                      href={link.href}
                      className="inline-flex min-h-9 items-center text-sm font-bold transition-transform hover:translate-x-1 hover:text-quest-green"
                    >
                      {link.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <div className="mt-14 flex flex-col gap-3 border-t-2 border-forest-line pt-8 text-xs sm:flex-row sm:items-center sm:justify-between">
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

import type { Metadata } from "next";
import { Baloo_2, Nunito } from "next/font/google";
import "./globals.css";
import { SiteFooter } from "./_components/site-footer";
import { SiteHeader } from "./_components/site-header";

const nunito = Nunito({ variable: "--font-nunito", subsets: ["latin"] });
const baloo = Baloo_2({
  variable: "--font-baloo",
  subsets: ["latin"],
  weight: ["600", "700", "800"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://ecoquest.app"),
  title: {
    default: "EcoQuest — Save the planet. Beat your friends.",
    template: "%s · EcoQuest",
  },
  description:
    "EcoQuest turns real-world environmental action into a social game. Daily quests, AI-verified proof, city and school leagues, real rewards.",
  keywords: [
    "eco app",
    "gamified sustainability",
    "litter picking app",
    "school environmental challenge",
    "city litter data",
  ],
  openGraph: {
    type: "website",
    siteName: "EcoQuest",
    title: "EcoQuest — Save the planet. Beat your friends.",
    description:
      "Daily environmental quests, verified on your phone. Compete with friends, your school and your city.",
  },
  twitter: { card: "summary_large_image" },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${nunito.variable} ${baloo.variable} h-full`}
    >
      <body className="flex min-h-full flex-col">
        <SiteHeader />
        <main className="flex-1">{children}</main>
        <SiteFooter />
      </body>
    </html>
  );
}

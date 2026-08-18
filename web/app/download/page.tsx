import { createHash } from "node:crypto";
import { readFile, stat } from "node:fs/promises";
import { join } from "node:path";
import type { Metadata } from "next";
import { Card, CTA, Eyebrow, Flower, H2, Lead, Section } from "../_components/brand";

export const metadata: Metadata = {
  title: "Download for Android",
  description:
    "Install the EcoQuest Android app directly. One APK, no Play Store account, no ads.",
};

const APK = "ecoquest.apk";

/// What we can say truthfully about the build sitting in `public/`.
///
/// Read at build time rather than typed into the page, because a hand-written
/// size or checksum is wrong the first time somebody rebuilds the app and
/// forgets this file — and a checksum nobody can trust is worse than none.
async function release() {
  // A CDN or GitHub release wins when it is set: a 60 MB binary does not belong
  // in git, and this is the seam where the deploy decides where it really lives.
  const external = process.env.NEXT_PUBLIC_APK_URL;
  const path = join(process.cwd(), "public", APK);

  try {
    const [info, bytes] = await Promise.all([stat(path), readFile(path)]);
    return {
      href: external ?? `/${APK}`,
      megabytes: (info.size / 1e6).toFixed(1),
      sha256: createHash("sha256").update(bytes).digest("hex"),
      built: info.mtime,
    };
  } catch {
    // No APK in the tree. The page still builds and still tells the truth —
    // it just cannot offer a file it does not have.
    return external ? { href: external } : null;
  }
}

export default async function DownloadPage() {
  const build = await release();

  return (
    <>
      <section className="relative overflow-hidden bg-leaf">
        <Flower
          className="animate-float absolute -left-12 top-12 size-44 opacity-40"
          petal="#00A855"
          heart="#EAF7EC"
        />
        <Flower
          className="animate-float absolute -right-10 bottom-10 size-56 opacity-40"
          petal="#00A855"
          heart="#EAF7EC"
        />

        <div className="relative mx-auto max-w-3xl px-6 py-24 text-center sm:py-32">
          <Eyebrow>Android · early build</Eyebrow>
          <h1 className="display text-4xl text-ink sm:text-6xl">
            Put it on your phone.
            <br />
            <span className="scribble">Go outside.</span>
          </h1>

          {build?.href ? (
            <>
              <p className="mx-auto mt-6 max-w-xl text-lg font-semibold text-ink/80">
                One file, straight from us. No Play Store account, no ads in the
                loop, and the litter detection runs on your phone rather than in
                anyone&rsquo;s cloud.
              </p>

              <div className="mt-10 flex flex-col items-center gap-3">
                {/* A plain link, not a script: the browser's own downloader
                    handles resume, and Android hands the finished file to the
                    package installer without us doing anything clever. */}
                <a
                  href={build.href}
                  download
                  className="press inline-flex min-h-14 items-center justify-center gap-3 rounded-full border-[3px] border-ink bg-quest-green px-8 text-base font-extrabold text-ink shadow-[6px_6px_0_var(--color-ink)]"
                >
                  <svg viewBox="0 0 24 24" className="size-6" fill="none" aria-hidden="true">
                    <path
                      d="M12 3v12m0 0l-4.5-4.5M12 15l4.5-4.5M4 20h16"
                      stroke="currentColor"
                      strokeWidth="2.6"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                  Download the APK
                </a>
                <p className="text-xs font-bold text-ink/70">
                  {"megabytes" in build && build.megabytes
                    ? `${build.megabytes} MB · Android 7.0 and up`
                    : "Android 7.0 and up"}
                </p>
              </div>
            </>
          ) : (
            <p className="mx-auto mt-6 max-w-xl text-lg font-semibold text-ink/80">
              The Android build isn&rsquo;t published yet. It lands here the day
              it is ready — this page will hand you the file directly.
            </p>
          )}
        </div>
      </section>

      <Section className="bg-page">
        <Eyebrow tone="bg-sky">Three steps</Eyebrow>
        <H2>Installing it takes a minute.</H2>
        <Lead>
          Android asks before it lets any site install an app. That prompt is the
          system doing its job — here is exactly what it will say.
        </Lead>

        <ol className="mt-10 grid gap-6 md:grid-cols-3">
          {[
            {
              n: "1",
              title: "Tap download",
              body: "Your browser saves the .apk like any other file. On some phones it warns that this type of file can harm your device — that warning appears for every APK, ours included.",
              tilt: -1.2,
            },
            {
              n: "2",
              title: "Allow this source",
              body: "Open the file. Android asks whether your browser may install apps. Say yes for the browser, and you can turn it straight back off afterwards in Settings › Apps › Special access.",
              tilt: 0.8,
            },
            {
              n: "3",
              title: "Open and play",
              body: "Make an account, pick a face, and the first quest is waiting. Camera permission is asked for the first time you shoot, location only if you turn the map on.",
              tilt: -0.6,
            },
          ].map((step) => (
            <li key={step.n}>
              <Card tilt={step.tilt} className="h-full">
                <span className="display flex size-11 items-center justify-center rounded-full border-[3px] border-ink bg-gold text-lg text-ink shadow-[3px_3px_0_var(--color-ink)]">
                  {step.n}
                </span>
                <h3 className="display mt-5 text-2xl text-ink">{step.title}</h3>
                <p className="mt-3 text-ink-dim">{step.body}</p>
              </Card>
            </li>
          ))}
        </ol>
      </Section>

      <Section className="bg-page-subtle">
        <div className="grid gap-10 lg:grid-cols-[1.1fr_1fr]">
          <div>
            <Eyebrow tone="bg-streak-fire">Straight answers</Eyebrow>
            <H2>What you&rsquo;re installing.</H2>
            <dl className="mt-8 space-y-6">
              {[
                {
                  q: "Why not the Play Store?",
                  a: "It isn't there yet. Until it is, this is the only place we hand out the app — if you find EcoQuest anywhere else, it did not come from us.",
                },
                {
                  q: "Is it signed?",
                  a: "Yes, with our own release key, which is what lets your phone verify that an update came from the same place as the install. It is not a Google-issued certificate, so Android calls the source unknown rather than untrusted.",
                },
                {
                  q: "iPhone?",
                  a: "Not yet. iOS does not allow installing outside the App Store the way Android does, so the iPhone build has to go through review first.",
                },
                {
                  q: "What does it need?",
                  a: "Android 7.0 or newer. Camera when you photograph litter, and location only if you switch the map on — that one is off until you choose otherwise.",
                },
              ].map((item) => (
                <div key={item.q}>
                  <dt className="display text-xl text-ink">{item.q}</dt>
                  <dd className="mt-2 text-ink-dim">{item.a}</dd>
                </div>
              ))}
            </dl>
          </div>

          {build && "sha256" in build && build.sha256 && (
            <Card tilt={1} className="h-fit">
              <h3 className="display text-2xl text-ink">Check the file</h3>
              <p className="mt-3 text-sm text-ink-dim">
                Every copy we publish has this SHA-256. If the one you downloaded
                hashes to something else, it is not the file we built — delete it.
              </p>
              <code className="mt-5 block overflow-x-auto rounded-2xl border-[3px] border-ink bg-page p-4 text-[11px] leading-relaxed break-all text-ink">
                {build.sha256}
              </code>
              <p className="mt-4 text-xs font-bold text-ink-dim">
                Built {build.built?.toISOString().slice(0, 10)} · verify with{" "}
                <span className="font-mono">sha256sum {APK}</span>
              </p>
            </Card>
          )}
        </div>
      </Section>

      <Section className="bg-page">
        <div className="sticker bg-gold px-8 py-10 text-center">
          <H2>Rather wait for the store?</H2>
          <p className="mx-auto mt-4 max-w-lg font-semibold text-ink/80">
            Leave an email on the landing page and we&rsquo;ll write once, the day
            it is listed.
          </p>
          <div className="mt-7 flex flex-wrap justify-center gap-4">
            <CTA href="/#get-the-app" variant="ghost">
              Email me at launch
            </CTA>
            <CTA href="/#how-it-works" variant="ghost-dark">
              See how it works
            </CTA>
          </div>
        </div>
      </Section>
    </>
  );
}

# EcoQuest — Brand Guidelines

**Company:** EcoTech B.V. · **Product:** EcoQuest · **HQ:** Amsterdam, Netherlands

---

## 1. Brand core

| | |
|---|---|
| **Mission** | Turn real-world environmental action into a social game. |
| **One-sentence pitch** | EcoQuest is a social gaming platform that turns real-world environmental actions into challenges, competition and rewards. |
| **Primary tagline** | **Save the planet. Beat your friends.** |
| **Secondary tagline** | Don't just scroll. Make an impact. |
| **Audience** | 15–27, mobile-native, competitive, climate-aware but allergic to guilt-marketing. |
| **Category** | Social game × real-world impact platform. Not a recycling tracker. |

### Positioning

> BeReal proved people show up daily for social proof.
> Strava proved competition beats good intentions.
> EcoQuest points both at the planet.

**We are not:** an eco-education app, a carbon calculator, a guilt machine, "BeReal for recycling".

---

## 2. Voice & tone

**Personality:** confident teammate, not a preacher. Playful, quick, a bit competitive. Speaks like a game, delivers like a tool.

| Do | Don't |
|---|---|
| "You're #3 in Plzeň this week." | "You have contributed to sustainability." |
| "Alex just passed you. 🔥" | "Consider taking further action." |
| "12 bottles. Verified. +180 XP" | "Thank you for your eco-friendly behaviour!" |
| Short. Active. Present tense. | Corporate sustainability vocabulary. |

**Hard rules**
- Never shame. The app rewards what you did, never scolds what you didn't.
- Never inflate impact. `8.2 kg CO₂ saved` must be defensible or it's greenwashing.
- Numbers over adjectives. "47 items" beats "a great effort".
- Emoji: one per message max, as a signal (🔥 streak, ⚔️ duel, 🌍 global, ♻️ verified). Never decoration.

**Naming conventions** — always capitalised as one concept: `EcoQuest`, `EcoPoints`, `EcoScore`, `Quest`, `Streak`, `Season`, `EcoLeague`, `City Battle`, `World Eco Cup`.
XP is always uppercase. EcoPoints never abbreviate to "EP" in UI.

---

## 3. Colour

Dark-first. The app lives outdoors, on a phone, in sunlight — high contrast is a functional requirement, not a style choice.

### Core palette

| Token | Hex | Use |
|---|---|---|
| `quest-green` | `#00E676` | **Primary.** CTAs, XP, verified state, progress fill. |
| `quest-green-deep` | `#00A855` | Pressed states, gradient end, dark-on-light text accent. |
| `deep-forest` | `#0A1F16` | App background (dark). |
| `forest-surface` | `#12291E` | Cards, sheets, elevated surfaces. |
| `forest-line` | `#1E3D2C` | Borders, dividers, inactive tracks. |
| `bone` | `#F2F7F4` | Primary text on dark. |
| `bone-dim` | `#8FA69A` | Secondary text, labels, captions. |

### Accent palette (semantic — never decorative)

| Token | Hex | Meaning |
|---|---|---|
| `streak-fire` | `#FF6B35` | Streaks, urgency, expiring quests. |
| `duel-violet` | `#7C4DFF` | Friend duels, PvP, challenges from others. |
| `impact-cyan` | `#00D4FF` | Data, stats, CO₂, the Eco Map. |
| `gold` | `#FFC53D` | Rank #1, badges, seasonal rewards. |
| `alert-red` | `#FF4D5E` | Rejected verification, errors, lost streak. |

### Light mode (web marketing site)

| Token | Hex |
|---|---|
| `bg` | `#FFFFFF` |
| `bg-subtle` | `#F4F8F5` |
| `text` | `#0A1F16` |
| `text-dim` | `#4F6659` |
| `line` | `#DDE7E0` |

Primary stays `quest-green`, but on white use `quest-green-deep` (`#00A855`) for text and small elements — `#00E676` fails contrast on white.

### Signature gradient

```
linear-gradient(135deg, #00E676 0%, #00D4FF 100%)
```
Reserved for: hero headline accents, level-up moments, the app icon. Never behind body text.

### Contrast requirements
- Body text ≥ 4.5:1, large text and UI ≥ 3:1.
- `quest-green` on `deep-forest` = 9.8:1 ✓ · on white = 1.7:1 ✗ (use `quest-green-deep`).
- Never encode meaning in colour alone — pair with icon or label (colour-blind users, sunlight).

---

## 4. Typography

| Role | Face | Notes |
|---|---|---|
| **Display / numbers** | **Space Grotesk** — 700 | Headlines, XP counters, leaderboard ranks. Geometric, gamey, tabular-friendly. |
| **UI / body** | **Inter** — 400/500/600 | Everything else. Ships with variable weight. |
| **Mono** | **JetBrains Mono** | Only for data tables in the city dashboard. |

**Scale** (mobile / web)

| Token | Size | Weight | Tracking |
|---|---|---|---|
| `display` | 40 / 64 | 700 | -0.03em |
| `h1` | 28 / 40 | 700 | -0.02em |
| `h2` | 22 / 28 | 600 | -0.01em |
| `body` | 16 / 17 | 400 | 0 |
| `label` | 13 / 14 | 600 | 0.04em, uppercase |
| `caption` | 12 / 13 | 400 | 0 |

**Numbers are the brand.** All stats use `font-variant-numeric: tabular-nums` so counters don't jitter while animating. XP and EcoPoints always render with thin-space thousands separators: `14 820 XP`.

---

## 5. Logo & icon

**Wordmark:** `eco` in Inter 600 `bone` + `Quest` in Space Grotesk 700 `quest-green`. Set tight, -0.02em. Never two colours on the same word.

**Symbol:** a leaf whose outline doubles as a location pin — the two things the product actually is (nature + real place). Renders at 16px.

**App icon:** symbol in `bone` on the signature gradient, no text, no rounded-square border (the OS masks it).

**Never:** stretch, rotate, outline, add drop shadows, place on a busy photo without a scrim, or recolour the symbol outside `bone` / `quest-green` / `deep-forest`.

**Clear space:** the height of the `e` on all sides.

---

## 6. UI principles

1. **Camera in one tap.** The core loop is Quest → photo → verify → XP. Any screen that delays the shutter is a bug.
2. **Verification is visible.** Show what the AI saw — bounding boxes, counts, class names. A black-box "approved" invites distrust; a labelled box invites bragging.
3. **Reward instantly, sync later.** XP lands the moment on-device detection returns. Never block a reward on the network.
4. **One number per screen.** Every screen has one hero metric. If there are two, it's two screens.
5. **Offline is normal.** Litter is picked in parks with bad signal. Every action queues and reconciles.
6. **Motion earns its place.** Counter roll-ups, streak flames, level-up bursts — all ≤ 400ms, all respecting `reduce-motion`.
7. **Touch targets ≥ 48dp.** One-handed, walking, gloves in winter.

### Component language
- Radius: `12` cards, `999` pills/buttons, `20` bottom sheets.
- Elevation via surface colour, not shadow (shadows disappear on dark).
- Spacing: 4pt grid, `4 / 8 / 12 / 16 / 24 / 32 / 48`.
- Progress is always a filled bar with a numeric label beside it, never a bare bar.

---

## 7. Impact claims (legal + trust)

The single fastest way to kill this brand is an unbelievable number.

- Every CO₂ / weight figure shows its basis on tap: `8.2 kg CO₂ · based on EPA WARM factors for PET`.
- Use ranges when the estimate is weak: `~0.3–0.5 kg`.
- Unverified actions are labelled `self-reported` in a `bone-dim` chip and never counted in city or country totals.
- Never claim a user "saved" something they merely didn't consume.
- Sponsored quests carry a visible `Sponsored by X` label, always. No exceptions, no native-ad blurring.

---

## 8. Design tokens (source of truth)

```
--quest-green:       #00E676
--quest-green-deep:  #00A855
--deep-forest:       #0A1F16
--forest-surface:    #12291E
--forest-line:       #1E3D2C
--bone:              #F2F7F4
--bone-dim:          #8FA69A
--streak-fire:       #FF6B35
--duel-violet:       #7C4DFF
--impact-cyan:       #00D4FF
--gold:              #FFC53D
--alert-red:         #FF4D5E
```

Mirrored in code — change these two files, never a hardcoded hex:
- Flutter: [mobile/lib/theme/tokens.dart](mobile/lib/theme/tokens.dart)
- Web: [web/app/globals.css](web/app/globals.css)

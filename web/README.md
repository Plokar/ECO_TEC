# EcoTech — company site

```bash
npm install
npm run dev      # http://localhost:3000
npm run build
npm run lint
```

Next.js 16 (App Router, Turbopack) + Tailwind 4. Six fully static pages: landing,
`/schools`, `/cities`, `/partners`, `/pricing`, `/about`. No client-side data
fetching and no API routes — deploys to Vercel or any static host unchanged.

Brand tokens live in [app/globals.css](app/globals.css) under `@theme`, mirroring
[BRANDING.md](../BRANDING.md) §8 and `mobile/lib/theme/tokens.dart`. Change all
three together or none.

**Before going live:** the launch-email form on the landing page posts to a
`REPLACE_ME` Formspree endpoint, and the addresses on `/about` are placeholders
for the fictional company.

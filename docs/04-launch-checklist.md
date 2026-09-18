# Launch checklist

## Day 1 (do these before writing another line of code)

- [ ] Buy `goodwalk.app` at Cloudflare Registrar (not bought yet as of 18 Sep 2026). Then run
      the runbook in `docs/10-site-and-email-runbook.md` (or
      `CF_TOKEN=… GITHUB_TXT_VALUE=… bash scripts/cloudflare-setup.sh`).
- [ ] Create the App IDs `app.goodwalk.goodwalk` and `app.goodwalk.goodwalk.widgets` in the
      Apple Developer portal (matches `project.yml`). Enable **App Groups**
      (`group.app.goodwalk.goodwalk`) on both.
- [ ] App Store Connect (full walkthrough in `docs/09-app-store-connect.md`): create the app,
      three in-app purchases matching `GoodWalk/Resources/Products.storekit`
      (`goodwalk.yearly`, `goodwalk.monthly`, `goodwalk.lifetime`), one subscription group
      "Good Walk Pro", 7-day free trial intro offer on yearly.
- [ ] GitHub: push this repo, turn on Pages (Settings → Pages → Deploy from a branch →
      folder `/docs`), custom domain `goodwalk.app` (the `docs/CNAME` file already says so),
      tick "Enforce HTTPS" once the certificate appears.
- [ ] Cloudflare Email Routing: `support@goodwalk.app` and `hello@goodwalk.app` → your inbox.
      Gmail "Send mail as" for replies. Gmail filter → label "Good Walk support", skip inbox.
- [ ] Search "Good Walk" on the App Store on a phone. It wasn't in the dog-walk-tracker results
      in a web search on 18 Sep 2026; confirm before anything is printed on it.

No entitlement request. Good Walk uses no restricted frameworks: no location, no HealthKit.
That's the whole reason the timeline is two weeks instead of six.

## Build

```bash
brew install xcodegen
cd dogwalk
xcodegen generate
open GoodWalk.xcodeproj
```

- Select your team in Signing & Capabilities for the app and the widget extension.
- The simulator runs everything: onboarding, paywall (StoreKit config), logging, milestones,
  the widget. Two things need a physical device: notification *actions* (the simulator shows
  them but the timing is unreliable) and the pedometer (the simulator has no motion data, so
  live distance stays at 0).
- Use the `GoodWalk` scheme; StoreKit testing is wired to `Products.storekit` so purchases work
  locally without App Store Connect.
- Screenshots: launch with `-screenshot <name>` (hook, dog, size, breed, usual, reveal, plan,
  first, result, paywall, home, walking, log, milestone, settings, share). Captures land in
  `docs/screenshots/`. The seeded dog is Rex: medium adult mixed breed, 60 min target, 30-day
  streak, 47 miles.

## Before submission

- [ ] Replace or cite every placeholder number: the hook ("about 20 minutes a day"), the
      "typical dog this size gets" figures (17/19/22/24/21) and the size/breed/age factors in
      `GoodWalk/Models/WalkPlan.swift`. Sources to check: AKC, PDSA, kennel-club exercise
      guidance, published owner surveys. If a number can't be cited, soften the copy. See
      `docs/01-strategy.md` section 6.
- [ ] Check every screen that shows the target also shows "general guideline": reveal, plan,
      Settings footer ("Not veterinary advice; ask your vet, especially for puppies, seniors,
      flat-faced breeds and dogs with health conditions.").
- [ ] App Store screenshots: 1) 5:30pm notification with Walked ✓, 2) home with Rex in the
      ring and a 30-day streak, 3) reveal "60 min vs 22", 4) milestone card, 5) walk timer,
      6) widget. Same order as the onboarding beliefs. `docs/screenshots/` has the raw captures.
      **The seeded captures use an illustrated sample dog. Re-shoot the App Store set with a
      real dog photo** (yours, or one you have written permission to use).
- [ ] App Review notes: it's a habit tracker, not a veterinary app; why Motion & Fitness is
      requested (distance, on-device, optional); how to test.
- [ ] Age rating questionnaire: everything "None". Expect 4+.
- [ ] Privacy strings in `project.yml`: `NSMotionUsageDescription` says what it's for in plain
      words ("to measure how far you and your dog walk. It stays on your phone."). No location
      or photo-library strings should exist; the photo comes from the system picker.
- [ ] Analytics: create a free PostHog project, paste the `phc_…` key into
      `GoodWalk/App/Config.swift`. Build the funnel
      `onboarding_started → first_walk_logged → paywall_shown → trial_started → paid`
      and the retention chart on `walk_finished` + `walk_quick_logged`. That funnel is the business.
- [ ] Run onboarding on a real iPhone with a real dog. Wait for the 5:30pm notification. Tap
      Walked ✓ without opening the app. Confirm the ring and the streak moved, in the app and
      on the widget. This is the demo video; it has to work.
- [ ] Take one real walk with the timer running, phone in a pocket. Check the distance is
      believable against a known route.

## Day of launch

- [ ] Landing page: paste the App Store URL into `APP_STORE_URL` at the bottom of `docs/index.html`.
      The button switches to "Download on the App Store" by itself.
- [ ] Promo codes for creators generated in App Store Connect (Offer Codes).
- [ ] Post the first 10 videos already recorded.
- [ ] Read every review daily. One fix per day for the first two weeks.

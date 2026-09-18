# App Store Connect setup, step by step

Do these in order. Steps 1–2 are on developer.apple.com, the rest on appstoreconnect.apple.com.
Total time about 60 minutes if the Developer Program is already active.

## 1. Developer Program

- Enroll at developer.apple.com/programs ($99/yr). Individual is fine to start; you can
  transfer to a company later. Approval is usually same-day, sometimes 48 hours. If the
  account from the earlier apps is active, skip this.

## 2. Identifiers (developer.apple.com → Certificates, Identifiers & Profiles → Identifiers)

Create two App IDs, explicit (not wildcard):

| Bundle ID | Description | Capabilities to tick |
|---|---|---|
| `app.getgoodwalk.goodwalk` | Good Walk | App Groups |
| `app.getgoodwalk.goodwalk.widgets` | Good Walk Widgets | App Groups |

Then Identifiers → App Groups → register `group.app.getgoodwalk.goodwalk`, and assign it to both
App IDs (edit each App ID → App Groups → Configure). No special entitlements are needed:
CoreMotion's pedometer needs a usage string in Info.plist, not a capability. Do **not** tick
HealthKit or anything location-related; the app uses neither.

## 3. Create the app record (App Store Connect → My Apps → +)

- Platform: iOS. Name: **Good Walk: Dog Walk Streak** (the App Store name is the title; if
  it's taken, try "Good Walk – Dog Walk Streak", then "Good Walk: Daily Dog Walks").
  Primary language: English (U.S.).
- Bundle ID: `app.getgoodwalk.goodwalk`. SKU: `goodwalk-ios`. User access: Full.

## 4. Agreements, tax and banking (App Store Connect → Business)

- Accept the **Paid Apps Agreement**. Without it, in-app purchases won't load in TestFlight or
  production, and purchases fail with an unhelpful error (`store_load_failed` in analytics).
- Add a bank account and complete the US tax form (W-9 if US-based). Payouts start 45 days
  after the end of the month a sale happens.
- Under Business → Small Business Program, apply. Apple's cut drops from 30% to 15% while
  revenue is under $1M/yr. Takes a few days, worth doing now. Already enrolled from an earlier
  app? It covers the whole account.

## 5. In-app purchases (My Apps → Good Walk → Monetization → Subscriptions / In-App Purchases)

**Subscription group** "Good Walk Pro". Both subscriptions go in it.

| Reference name | Product ID | Type | Price (US) | Intro offer |
|---|---|---|---|---|
| Yearly | `goodwalk.yearly` | Auto-renewable, 1 year | $24.99 | Free trial, 7 days, all territories, new subscribers |
| Monthly | `goodwalk.monthly` | Auto-renewable, 1 month | $4.99 | none |
| Lifetime | `goodwalk.lifetime` | Non-consumable | $39.99 | n/a |

Product IDs must match `GoodWalk/Services/StoreManager.swift` and
`GoodWalk/Resources/Products.storekit` exactly.

For each product:
- Subscription level: Yearly = 1, Monthly = 2 (same group, yearly ranks higher so upgrades
  from monthly are treated as upgrades).
- Localization (en-US): display name "Good Walk Yearly" / "Good Walk Monthly" /
  "Good Walk Lifetime", description one line ("Full access, billed yearly." etc.).
- Review screenshot: any screenshot of the paywall from the simulator
  (`docs/screenshots/paywall.png`, from `-screenshot paywall`). Required before submission,
  ignored by users.
- Subscription group localization: name "Good Walk Pro", app name "Good Walk".

Price: choose the US price and let Apple's pricing equalize other territories.

## 6. App Privacy (App Store Connect → Good Walk → App Privacy)

Answer honestly for the analytics setup in `GoodWalk/App/Config.swift`:
- Data collected: **Product Interaction** and **Crash Data** (PostHog lifecycle + funnel events)
  → "Analytics" purpose, **not** linked to identity, **not** used for tracking.
- Location: **not collected.** The app never requests location. Distance comes from the
  pedometer.
- Fitness / Health: **not collected.** Pedometer distance is read on-device, stored on-device
  and never sent anywhere; it is not written to HealthKit. "Collected" in Apple's terms means
  transmitted off the device, and it isn't.
- Photos: **not collected.** The dog's photo is picked with the system picker and stays on
  the device.
- Privacy policy URL: https://getgoodwalk.app/privacy.html

If the PostHog key in `Config.swift` is left empty, no analytics are sent at all; the labels
above are still the right answer for a build with the key set.

## 7. App information

- Category: Health & Fitness (primary), Lifestyle (secondary).
- Age rating: questionnaire → everything "None". Expect 4+.
- Support URL: https://getgoodwalk.app/ Marketing URL: same.
- Copyright: 2026 <your name>.

## 8. Version 1.0 page

Paste from `docs/06-app-store-listing.md`: subtitle, promotional text, description, keywords.
Upload the six screenshots (6.9-inch required; Apple scales down for smaller phones). Use the
set re-shot with a real dog photo, not the illustrated sample dog from ScreenshotMode.
App Review Information: contact details, and the review notes from the listing doc. No
sign-in required.

## 9. TestFlight

- `xcodegen generate` first, then Xcode → scheme `GoodWalk` → Product → Archive → Distribute →
  App Store Connect → Upload. Xcode handles signing when "Automatically manage signing" is on
  for both targets (`GoodWalk`, `GoodWalkWidgets`).
- Add yourself and ten dog-owning friends as internal testers (no review needed). External
  testers need a one-time beta review, usually under 24 hours.
- Sandbox purchases: Users and Access → Sandbox → Testers → create a sandbox Apple ID. On the
  test phone, Settings → App Store → Sandbox Account → sign in with it. Trials and renewals
  run on an accelerated clock (a 1-year sub renews every hour) so you can test the flow.
- Device-only checks: notification actions ("Walked ✓" logs without opening the app) and live
  distance on the walk timer. Neither can be trusted in the simulator.

## 10. Offer codes for creators (after launch)

Monetization → Subscriptions → Good Walk Yearly → Offer Codes → create a one-time-use batch per
creator (e.g. 100 codes, 1 month free). Codes redeem at apps.apple.com/redeem and are the
cleanest way to attribute trials to a creator. Lifetime codes for rescues: use App Store promo
codes for the non-consumable (100 per product per six months).

## 11. Submit

- Build attached, all metadata complete, IAPs in "Ready to Submit" state and attached to the
  version (they review with the first build).
- Export compliance: "No" to encryption beyond HTTPS (set `ITSAppUsesNonExemptEncryption` to
  NO in `project.yml` so the question doesn't come up on every upload).
- Release: manual, so launch day is your choice, not Apple's. Target: submitted by Sep 25, live
  by Sep 30 for Walk Your Dog Week (1–7 Oct). If review slips, launch anyway the day it clears.

# Good Walk — Strategy

> One sentence: **Your dog needs a walk every day. Good Walk makes it a streak.**

## 1. Why this idea

Same filter as the earlier apps: a problem people already feel every day, already Google, already
pay to fix, where several competitors are already making real money. "Walk the dog more" passes
every check, and it has the one thing neither earlier app had: the user's favourite subject is
in every frame. People post their dog without being asked.

| Check | Evidence |
|---|---|
| Daily felt pain | The 5:30pm look from the dog. The guilt of "just round the block again". Every owner knows the number is too low; nobody knows what it should be. |
| Proven spend | Owners pay $100+/yr for collar subscriptions: Tractive ($79 tracker + $108/yr Basic, billed annually), Fi ($189/yr membership). Prices checked 18 Sep 2026; sources in `playbook/12-sources.md`. |
| Loud complaints | Tractive retired its separate Dog Walk app on 1 Jan 2025 and moved walk tracking into its GPS app, which is built around the tracker. Collar reviews repeat: subscription on top of hardware, battery, "I just wanted to log walks". Free trackers: map-first, account required, the dog is a profile field. |
| 7-second demo | 5:30pm notification "Has Rex had a walk today?" → tap "Walked ✓" → Rex's ring fills, streak goes 29 → 30, confetti. Nothing to explain. |
| Shareable result | "47 miles walked with Rex · 30-day streak" card with the dog's photo on it. Streak milestones at 1, 3, 7, 14, 30, 60, 100, 365. |
| No backend needed for v1 | Local notifications + StoreKit 2 + a widget + the phone's pedometer. Zero server cost, no account, no location, and no special entitlement to wait for. |

**Why this is low risk:** Good Walk needs nothing from Apple but App Review. No restricted
frameworks, no HealthKit, no location permission to justify. Build to submission is under two
weeks.

## 2. The "streak belongs to the dog" angle

Fitness apps track the human. Collars track the dog's location. Nobody tracks the promise the
owner made to the dog. That's the product.

- **The dog is on everything.** The dog's name is in the notification, the dog's photo is inside
  the ring, on the widget and on every share card. It's not "your streak", it's Rex's.
- **The target is the dog's, not the app's.** Size, breed type and age give a daily minutes
  guideline. "Rex needs about 60 min a day" is a number the owner has never been told.
- **One button, no hardware.** No collar, no map, no account. "Walked ✓" from the notification
  logs the usual walk without opening the app.
- **Guilt-free.** A missed day is just a missed day. The streak resets; the miles, hours and
  history don't. No sad-dog screens.

## 3. Launch windows

| Window | Date | What happens |
|---|---|---|
| **National Walk Your Dog Week** | 1–7 Oct 2026 (starts in 13 days) | Shelters, brands and dog accounts all post about it. Small window, low competition for the phrase. Our content runs a "7 walks in 7 days" framing. |
| **Walk Your Dog Month + New Year's resolutions** | January 2027 | "Walk more" and "get outside with the dog" are resolution staples. Good Walk needs to be live, reviewed and ranking by mid-December. |
| Year-round | | First warm weekend of spring, new-puppy season, "day in the life of my dog" content runs all year. |

Ship for October to learn. Optimise for January to earn.

## 4. Positioning against the category

Prices checked 18 Sep 2026 (`playbook/12-sources.md`). They move; check again on the day you quote one in public.

| Competitor | What they do well | What users hate | Good Walk's answer |
|---|---|---|---|
| Tractive ($79 + $108/yr) | GPS, escape alerts, activity minutes | Hardware plus subscription, battery; Dog Walk app shut down 1 Jan 2025 | No hardware. Under a fifth of the yearly price. A home for the people who only wanted to log walks. |
| Fi ($189/yr) | Nice collar, step goals, breed rankings | Price, collar required, US-centric | The phone already in your pocket counts the distance. |
| Walky (free) | Map, streak, free, no account | Map-first, generic, no personal target, no notification loop | Same honesty, plus the dog's own number, the tap-to-log reminder and the card. |
| TreatWalk, Amiko, Dog Walk Tracking & Playdates, onedog (free / small) | Simple, some social | Accounts, social features nobody asked for, small, no distribution | No account. We out-distribute on short-form; same simplicity. |
| Strava, Apple Fitness | Great trackers | They don't know the dog exists | The dog's name and face are the interface. |

**One-line differentiation:** Good Walk is the simplest way to walk your dog more. Tell it
about your dog once, then every day is one tap, and every milestone is a card with your dog's
face on it.

## 5. Product (v1 = onboarding + paywall + core loop, nothing else)

**Core loop**
1. 5:30pm (or whenever you chose) notification: "Has Rex had a walk today?" with **Walked ✓**
   and **Start a walk** buttons. Walked ✓ logs the usual walk length without opening the app.
2. Home: the dog's photo inside a progress ring ("25 of 60 min"), streak, a big "Start a walk"
   button, "Quick log" minutes, week bars, totals (miles, hours, walks).
3. Walk timer with live distance from the phone's pedometer. No map, no location.
4. Hit the day's target → confetti. Streak hits a milestone → card → share.
5. Missed a day → streak resets, totals and history stay. Nothing else happens.

Streak = consecutive days with at least one logged walk; today not yet walked doesn't break it.
"Goal days" = days the full target was hit. All stats are derived from the walk log, never
stored (`GoodWalk/Models/Stats.swift`).

Entry points besides the app: the notification actions, a Home Screen widget (dog photo,
today's ring, a "Start a walk" button), Siri ("Start a walk"), Shortcuts, the Action Button.

**Added 20 Sep 2026: walk Live Activity.** The running walk shows on the Lock Screen and Dynamic Island, and on
iPhone Duo in the outer display's status bar while the phone is folded in a pocket. Metric it moves:
`walk_finished / walk_started` (people forget a timer they can't see, then discard the walk), and it is the Duo
launch-week demo. No new permission, no backend.

**What is deliberately not in v1:** GPS maps, routes, multiple dogs, family sharing, social
feed, playdates, HealthKit, Apple Watch, Android, training content. Each is a v1.x candidate
only if reviews ask for it. (Multiple dogs will be the first ask; note it and wait.)

## 6. Where the numbers come from

The daily target is computed in `GoodWalk/Models/WalkPlan.swift`:

`base minutes (size) × breed-type factor × age factor`, rounded to the nearest 5, clamped 15–120.

| Size | Base min/day | What the Royal Kennel Club's Breeds A to Z says |
|---|---|---|
| Toy | 30 | 18 of 24 Toy-group breeds: "Up to 30 minutes per day" |
| Small | 40 | Small terrier, utility and hound breeds: "Up to 1 hour per day" |
| Medium | 60 | Most medium breeds: "Up to 1 hour per day" |
| Large | 90 | 56 of 79 large breeds: "More than 2 hours per day"; the other 23: "Up to 1 hour" |
| Giant | 60 | St. Bernard, Mastiff, Newfoundland: "Up to 1 hour"; Great Dane, Irish Wolfhound: "More than 2 hours" |

| Breed type | Factor | | Age | Factor |
|---|---|---|---|---|
| Flat-faced | 0.6 | | Puppy | 0.6 |
| Companion / Terrier / Hound / Mixed | 1.0 | | Adult | 1.0 |
| Working | 1.15 | | Senior | 0.7 |
| Sporting (retrievers, spaniels, pointers) | 1.35 | | | |
| Herding | 1.5 | | | |

Examples: medium adult mixed = 60. Large adult sporting (a Labrador) = 90 × 1.35 = 121 → 120,
the cap, where the Kennel Club says "More than 2 hours" and PDSA says "a minimum of two hours".
Medium adult herding (a Border Collie) = 90. Small senior flat-faced = 40 × 0.6 × 0.7 = 17 → 15.
Quick-logged walks estimate distance at 2.0 mph ("dog pace"); timed walks use the pedometer.

"The typical dog gets about 23 minutes a day" (hook and reveal) is 160 minutes a week ÷ 7: the
median among owners who walk their dog, across 29 studies (Christian et al., 2013). The same
review found only about 60% of owners walk their dog at all. No source splits the figure by dog
size, so the old per-size numbers (17/19/22/24/21) are gone.

**What is sourced and what is ours.** The bands are the Kennel Club's and PDSA's; turning three
bands into a number per dog is our interpolation, pinned to named breeds by
`testNamedBreedsSitInTheirPublishedBands`. The puppy and senior factors are our judgment: the
sources say "shorter" and give no ratio. The full list, with URLs, exact figures and the date
accessed, is `playbook/12-sources.md`. (Changed 18 Sep 2026: large 75 → 90, giant 45 → 60, companion
0.75 → 1.0, sporting 1.25 → 1.35, herding 1.35 → 1.5, because the old table put Labradors,
Shepherds and Great Danes well under both sources.) In the app the target is always presented as a general
guideline, not advice: "Not veterinary advice; ask your vet, especially for puppies, seniors,
flat-faced breeds and dogs with health conditions." The user can change the target on the plan
screen and in Settings.

## 7. Monetization

Subscription, hard paywall at the end of onboarding (after the user has logged their dog's
first walk and seen the first card with their dog on it).

| Plan | Price | Notes |
|---|---|---|
| Yearly | **$19.99** with 7-day free trial | Default. "$1.67/mo" framing. Under a fifth of the cheapest collar subscription ($108). Set by Nick on 20 Sep 2026 (was $24.99 / $4.99 / $39.99). |
| Monthly | $3.99 | Anchor to make yearly obvious. |
| Lifetime | $29.99 | For the subscription-haters (a loud group in collar reviews). |

Why these numbers: the paid reference points are collar subscriptions at $108–189/yr, so $19.99
reads as "the honest one" and still supports a business. The free trackers set the floor; the
personal target, the loop and the card are what the money is for.

**Unit-economics targets (month 3):**

| Metric | Target |
|---|---|
| Install → onboarding complete | 65% (no permission gate beyond notifications) |
| Onboarding complete → trial start | 25% |
| Trial → paid | 40% |
| Blended install → paid | ~6.5% |
| Yearly ARPU after Apple's cut (small-business 15%) | ~$17 |
| Break-even CPI at 6.5% install→paid | ~$1.10 |

At 10,000 installs/mo from organic short-form plus a January spike, that is ~650 paying
users/mo, ~$11k/mo run-rate by month 3, before January.

## 8. Distribution plan (starts before the app is approved)

See `playbook/03-distribution.md`. Short version:

1. **Week 0–1:** study 20 winning videos from dog-tok, Fi/Tractive ads and "day in the life of
   my dog" creators. Save hook, first frame, time-to-dog, time-to-product, CTA.
2. **Week 1–2:** post 3 videos/day across 2 accounts. Walk Your Dog Week countdown content from
   Sep 24. Track by the tier ladder.
3. **Oct 1–7:** "Day N of Walk Your Dog Week" daily series from the founder account. Seed 10
   small dog creators with the app.
4. **Nov–Dec:** put paid spend behind the 3–5 organic concepts that produced trials. Build the
   January content bank. Ask every October user for a review before Dec 15.

## 9. Metrics that matter (instrument from day 1)

Events are defined in `GoodWalk/Services/Analytics.swift`. Funnel to watch weekly:

`app_open → onboarding_step(n) → reminders_authorized → first_walk_logged → paywall_shown → trial_started → paid → walk_finished / walk_quick_logged (D1, D7, D30) → goal_hit → milestone_reached → share_tapped`

The ratio that decides everything: **first_walk_logged / onboarding_started.** People who log
their dog's first walk in onboarding convert. People who drop before it need a shorter
onboarding.

Second ratio: **walks logged D7 / trial_started.** If people stop logging in the trial they
cancel. The 5:30pm notification with tap-to-log exists to protect this number.

## 10. Risks and how we handle them

| Risk | Mitigation |
|---|---|
| App Review or a vet reads the target as veterinary advice | It's a general guideline, says so on the reveal, the plan screen and the Settings footer, and tells people to ask their vet. No health-outcome claims anywhere. The user can change the number. |
| The numbers get challenged in comments | Every one is in `playbook/12-sources.md` with a link: Kennel Club bands, PDSA breed pages, Christian et al. for the 23. Reply with the source, never with a health claim. |
| Free competitors (Walky has streaks) | We don't compete on tracking. We compete on the dog's own number, the tap-to-log loop, the photo card and distribution. Price says the rest. |
| Users stop logging | Notification action logs without opening the app; widget starts a walk in one tap; quick log backfills today. A missed day never punishes. |
| Distance without GPS is approximate | Pedometer distance is good enough for "47 miles with Rex". Say "about" in copy. Motion permission is optional; without it, distance is estimated at 2.0 mph. |
| 13 days to Walk Your Dog Week | October is for learning, not earning. If review slips past Oct 7, nothing is lost; January is the window that matters. |
| "It's just a timer" | So is every winning app in the category. Ours has the tightest loop and the best card. |

## 11. 30-day plan

| Days | Deliverable |
|---|---|
| 1 | App Store Connect record, products, small-business program. Domain, Pages, email (runbook in `playbook/10-site-and-email-runbook.md`). |
| 1–4 | Run onboarding on a real phone with a real dog. Fix the screen you stop wanting to continue on. TestFlight to 10 dog-owning friends. |
| 4–7 | Record the first 10 videos (`playbook/07-launch-videos.md`). Start posting the Walk Your Dog Week countdown. |
| 7 | Submit for review. |
| 10–13 | Live before Oct 1. Daily posts. |
| Oct 1–7 | "Day N of Walk Your Dog Week" series. Seed creators. Read every review, one fix a day. |
| Oct 8–18 | Keep the daily streak series going from the founder account. First read on the funnel; start the A/B list in `playbook/02-onboarding-and-paywall.md`. |

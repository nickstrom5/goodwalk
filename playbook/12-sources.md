# Good Walk — sources

Every factual claim about dogs, owners, competitors and dates: where it appears, where it comes
from, the exact figure in the source, and what was done about it. All sources accessed
**18 Sep 2026**. "Opened" means the page or full text was read; anything that was only seen in a
search snippet, or could not be opened, says so.

Rule from here on: a new number about dogs, owners or competitors gets a row here before it goes
in copy. No health outcomes, ever; targets stay "a general guideline, not veterinary advice".

## 1. The daily target (`WalkPlan.recommendedMinutes`)

Primary source: **Royal Kennel Club, Breeds A to Z**, https://www.royalkennelclub.com/search/breeds-a-to-z/
(opened; all 227 breed cards parsed). Each breed carries one of four exercise labels: "Up to 30
minutes per day", "Up to 1 hour per day", "Between 1-2 hours per day" (one breed), "More than 2
hours per day". Second source: **PDSA breed pages** under
https://www.pdsa.org.uk/pet-help-and-advice/looking-after-your-pet/puppies-dogs/ (opened, quotes below).

| Claim | Where | Exact figure in the source | Action |
|---|---|---|---|
| Toy base 30 min | `GoodWalk/Models/WalkPlan.swift:21`, `playbook/01-strategy.md` §6, `README.md:76` | KC: 18 of 24 Toy-group breeds "Up to 30 minutes per day" (Chihuahua, Yorkshire Terrier, Pekingese), 6 "Up to 1 hour". PDSA Chihuahua: "a minimum of half an hour exercise every day" | Kept + cited |
| Small base 40 | `WalkPlan.swift:22` | KC: 47 of 49 small breeds outside the Toy group "Up to 1 hour per day". PDSA Pug and French Bulldog: "up to an hour"; Jack Russell and Cocker Spaniel: "a minimum of an hour" | Kept + cited (40 sits inside "up to 1 hour"; PDSA's terrier minimum is higher, the user can raise it) |
| Medium base 60 | `WalkPlan.swift:23` | KC: 37 of 55 medium breeds "Up to 1 hour per day", 17 "More than 2 hours", 1 "Between 1-2 hours" | Kept + cited |
| Large base | `WalkPlan.swift:24` | KC: 56 of 79 large breeds "More than 2 hours per day", 23 "Up to 1 hour". PDSA Golden Retriever, German Shepherd: "a minimum of two hours" | **Corrected 75 → 90** |
| Giant base | `WalkPlan.swift:25` | KC: St. Bernard, Mastiff, Newfoundland, Bernese Mountain Dog "Up to 1 hour"; Great Dane, Irish Wolfhound, Leonberger "More than 2 hours". PDSA Great Dane: "a minimum of two hours" | **Corrected 45 → 60** (45 was under every source). Still below KC/PDSA for Great Danes; the plan screen lets the owner raise it |
| Flat-faced × 0.6 | `WalkPlan.swift:31` | KC: Pug, French Bulldog, Bulldog, Boston Terrier "Up to 1 hour"; Pekingese "Up to 30 minutes". PDSA Pug, French Bulldog: "up to an hour" | Kept + cited. Results (25 small, 35 medium) sit inside the band on the cautious side |
| Companion factor | `WalkPlan.swift:32` | KC Toy and small Utility breeds sit in the same band their size already gives (above). 0.75 put a Chihuahua at 25, under PDSA's "minimum of half an hour" | **Corrected 0.75 → 1.0** |
| Terrier / Hound / Mixed × 1.0 | `WalkPlan.swift:32` | KC: all 27 terrier breeds "Up to 1 hour"; small and medium hounds mostly "Up to 1 hour" (large hounds: 14 of 17 "More than 2 hours", covered by the large base) | Kept + cited |
| Working × 1.15 | `WalkPlan.swift:33` | KC large Working breeds: 10 "More than 2 hours", 9 "Up to 1 hour" | Kept + cited (large working = 105, between the bands) |
| Sporting factor | `WalkPlan.swift:34` | KC Gundog group: 21 of 24 large breeds "More than 2 hours"; medium 6 "More than 2 hours", 5 "Up to 1 hour". PDSA Golden Retriever: "a minimum of two hours" | **Corrected 1.25 → 1.35** so a large adult reaches the 120 cap |
| Herding factor | `WalkPlan.swift:35` | KC Border Collie, German Shepherd: "More than 2 hours per day". PDSA Border Collie: "a minimum of two hours exercise every day"; German Shepherd: "a minimum of two hours" | **Corrected 1.35 → 1.5** (medium 90, large 120) |
| 15–120 clamp | `WalkPlan.swift:9-10` | KC's top band is "More than 2 hours", lowest "Up to 30 minutes" | Kept; design choice, consistent with the bands |
| Puppy × 0.6, senior × 0.7 | `WalkPlan.swift:43-45` | PDSA puppies: "keep sessions short"; PDSA also says of the 5-minutes-per-month rule "there's no scientific evidence behind this rule". KC walking tips give that rule as "a good rule of thumb". PDSA seniors: "shorter, flatter walking routes". RSPCA seniors: "They may need shorter walks though – little and often" | **FLAG, unresolved.** Direction is sourced, the ratios are not: no source gives one. Kept as our judgment, said so in code and `playbook/01-strategy.md`; the footnote tells owners of puppies and seniors to ask their vet |
| Named breeds land in their band | `GoodWalkTests/WalkPlanTests.swift` `testNamedBreedsSitInTheirPublishedBands` | The KC / PDSA figures above | New test |

URLs opened for the PDSA quotes: `.../medium-dogs/border-collie`, `.../small-dogs/pug`,
`.../small-dogs/jack-russell-terrier`, `.../large-dogs/great-dane`, `.../small-dogs/chihuahua`,
`.../small-dogs/french-bulldog`, `.../medium-dogs/beagle` ("at least an hour and a half"),
`.../large-dogs/german-shepherd`, `.../medium-dogs/cocker-spaniel`, `.../large-dogs/golden-retriever`,
`.../exercising-your-puppy`, `.../exercising-your-senior-dog`, and the overview
`.../how-much-exercise-does-your-dog-need` ("Most dogs need at least 1-2 walks per day").
RSPCA: https://www.rspca.org.uk/adviceandwelfare/pets/dogs/health/seniordogs.
KC walking tips: https://www.thekennelclub.org.uk/dog-training/getting-started-in-dog-training/dog-training-and-games/puppy-and-dog-walking-tips/.
The PDSA Labrador page returned no exercise sentence to the scraper, so Labradors rest on the KC
label and PDSA's Golden Retriever page. AKC was not used: its breed pages give energy levels,
not minutes.

**What is ours, not theirs:** the sources give three bands per breed. Turning bands into one
number per size × type × age is our interpolation. The KC's sizes (Small / Medium / Large) are not
the app's weight classes, and its "exercise" includes play, not only walks. The app says "general
guideline", the owner can change the number, and no source is presented as endorsing the app.

## 2. "The typical dog gets about 23 minutes a day"

| Claim | Where | Source and exact figure | Action |
|---|---|---|---|
| Hook "Most dogs get about 20 minutes a day. Most need a lot more." | `GoodWalk/Views/Onboarding/OnboardingScreens.swift:13-33` | Christian HE, Westgarth C, Bauman A, et al. "Dog ownership and physical activity: a review of the evidence." *J Phys Act Health* 2013;10(5):750-9, PMID 23006510. Abstract (opened via Europe PMC): "Approximately 60% of DO walked their dog, with a median duration and frequency of 160 minutes/week and 4 walks/week" (29 studies, 1990–2010, mostly Australia and the US) | **Corrected and softened:** "The typical dog gets about 23 minutes a day. Many are built for more." 160 ÷ 7 = 22.9. Source line on screen. "Many are built for more" rests on §1: 85 of 227 KC breeds are "More than 2 hours per day", 122 "Up to 1 hour", 19 "Up to 30 minutes" |
| Reveal "Most medium dogs get 22 min" (per-size 17 / 19 / 22 / 24 / 21) | was `WalkPlan.typicalMinutes(for:)`; now `WalkPlan.swift:54-62`, `OnboardingScreens.swift:305-312` | No source splits walking minutes by dog size. Westgarth 2015 (below) only finds medium dogs more likely to be walked daily than small ones | **Removed.** One cited figure for every size: `typicalMinutesPerWeek = 160` → 23. Test updated |
| Same line in docs, site and brand image | `README.md:10,80`, `playbook/01-strategy.md` §6, `playbook/02-onboarding-and-paywall.md:13,18,53`, `playbook/03-distribution.md:26,37`, `playbook/04-launch-checklist.md:60`, `playbook/06-app-store-listing.md:79`, `playbook/11-social-kit.md:30`, `docs/index.html` (#target section), `scripts/make-brand.swift` (first post image) → `docs/brand/post-reveal.png` | as above | Updated everywhere to 23 / "the typical dog" |
| Usual screen: "Right around what most dogs get" / "Better than most" / "Plenty of dogs live here" | `OnboardingScreens.swift:259-262` | 23 min median among walkers; about 40% of owners in the same review did not walk their dog | First line reworded to "Right around the typical dog"; the other two kept, supported |
| Usual screen: "Most people guess high." | `OnboardingScreens.swift:231` | No source found | **Removed** ("No judgement." instead) |
| Reddit template: "what the log said (22 minutes)", "a third of what I thought" | `playbook/11-social-kit.md:114-115` | It is meant to be the founder's own log | Replaced with "your real number; don't borrow one" |

Supporting context, not used in copy (so nobody is surprised in the comments):

- Westgarth C, Christley RM, Jewell C, et al. *Sci Rep* 2019;9:5704, PMC6473089 (full text opened):
  in 191 dog-owning adults in West Cheshire, UK, "Dog owners walked with their dogs a median 7.0
  times per week … and for a median 220.0 mins per week"; 9.6% reported 0 minutes. That is 31 min
  a day: UK owners in this sample walk more than the international median. If the app localises
  for the UK, use 31.
- Westgarth C, Christian HE, Christley RM. *BMC Vet Res* 2015;11:116, PMC4435921 (full text
  opened): of 276 dogs in Cheshire, "61 (22.1 %) were reported to be walked less than once a day";
  usual walk length 16–30 min for 40.6% and 31–60 min for 41.9%.
- PDSA press release, 26 Sep 2018, on the 2018 PAW Report (opened):
  https://www.pdsa.org.uk/press-office/latest-news/buying-pets-on-a-whim-with-no-research-could-be-causing-mental-and-physical-misery-for-millions-of-companion-animals-warns-pdsa
  — 16% of UK dogs "are walked less than once a day" and 1% (89,000) "aren't walked at all". The
  page prints the 16% as "4 million dogs", which cannot be right next to 89,000 = 1%; quote the
  percentages only. The PAW Report 2024 dogs page (opened) has no walking statistic. A "42% of dogs
  walked 30 minutes or less" figure attributed to PAW 2020 appeared in a search snippet only; the
  PDF was not opened, so it is **not** used.

## 3. Competitors and prices

| Claim | Where | Source and exact figure | Action |
|---|---|---|---|
| Tractive "~$49 device + ~$96/yr" | `playbook/01-strategy.md:15,55`, §7 | https://tractive.com/en/pd/gps-tracker-dog (opened): tracker "$79"; Basic "$9 / month", "$108 billed annually"; Premium "$120 billed annually"; 2-year Basic "$144" | **Corrected to $79 + $108/yr** |
| Fi "~$129/yr" | `playbook/01-strategy.md:15,56`, §7 | Fi's own pages (fitracking.com, shop.fitracking.com) opened but show no prices without JavaScript. Third-party: https://lifewithkleekai.com/how-much-does-fi-series-3-dog-collar-cost/ (opened, updated 13 Sep 2026): 6 months "$99", 12 months "$189", 24 months "$339", "$20 activation fee" | **Corrected to $189/yr. FLAG:** second-hand; confirm on Fi's store before quoting |
| "A GPS collar is $100 a year" | `playbook/03-distribution.md:44`, `playbook/07-launch-videos.md:67`, `playbook/11-social-kit.md:86` | Cheapest yearly plan found: Tractive Basic $108 | **Softened to "$100+ a year"** |
| "$19.99 … under a fifth of a collar subscription" | `playbook/01-strategy.md` §4, §7 | 19.99 ÷ 108 = 19% | Kept, reworded to "under a fifth of the cheapest" after the 20 Sep price change |
| Tractive "discontinued its separate Dog Walk app on 1 Jan 2025 and left those users without a home" | `playbook/01-strategy.md:16,55`, `playbook/03-distribution.md:54` | Tractive Help Center, "Tractive Dog Walk App", https://help.tractive.com/hc/en-us/articles/115005779525 — page returned 403; the search snippet reads: as of January 1st, 2025 the app "has been deprecated and is no longer supported", Walk tracking "is now part of" the Tractive GPS app | Date kept. **Softened**: walk tracking moved into the GPS app, it didn't vanish. **FLAG:** snippet only; open the page in a browser before video #18 |
| Walky: free, streaks | `playbook/01-strategy.md:57`, `playbook/05-naming.md:33` | App Store listing https://apps.apple.com/us/app/walky-dog-walk-tracker/id6759896890 (opened): Free; "No account. No ads. No subscription."; "Every day you walk, your streak grows. Miss a day, it resets." | Kept + cited; added "no account" to their strengths, since our "no account" is not a difference against Walky |
| TreatWalk, Amiko, Dog Walk Tracking & Playdates, onedog: "free / small", "accounts, social features" | `playbook/01-strategy.md:58` | TreatWalk and Amiko listings exist on the App Store (seen in search results); none of the four listings was opened | **FLAG, unresolved.** Internal positioning only; do not repeat in public copy |
| Fi "breed rankings, US-centric"; collar-review complaints ("subscription on top of hardware, battery") | `playbook/01-strategy.md:16,55-56` | Not checked | **FLAG, unresolved.** Internal only |
| "Pet spending is the category that doesn't get cut" | was `playbook/01-strategy.md:15` | No source looked for; APPA figures are behind a paywall | **Removed** |

No market-size figures (TAM, owner counts, APPA numbers) appear anywhere in the folder; none were added.

## 4. Dates

| Claim | Where | Source | Action |
|---|---|---|---|
| National Walk Your Dog Week, 1–7 October | `README.md:11`, `playbook/01-strategy.md:43`, `playbook/06-app-store-listing.md:18`, `playbook/09-app-store-connect.md:127`, `docs/index.html` (hero note) | https://nationaltoday.com/national-walk-your-dog-week/ (opened): October 1–7 annually, founded by Colleen Paige in 2010 | Kept + cited. It is an unofficial observance; don't call it anything grander |
| Walk Your Dog Month is January | `README.md:11`, `playbook/01-strategy.md:44` | Search results only (American Humane, Rover, Dogster, nationaltoday.com/walk-dog-month/ all titled "January"); no page opened | Kept. Low risk, widely repeated; flag lifted once one page is opened |

## 4b. The public site (added 18 Sep 2026, SEO pass)

The site repeats numbers from the sections above and adds none. Where each one sits:

| Page | Numbers used | Section above |
|---|---|---|
| `docs/index.html` | 60 / 23 / 243 (Rex), 160 min a week, 29 studies, "$100 or more a year" collar subscription, 1–7 October, prices from `Products.storekit` | §1, §2, §3, §4, §5 |
| `docs/how-much-exercise-does-my-dog-need.html` | KC label counts (19 / 122 / 1 / 85 of 227), per-size splits (18 of 24, 47 of 49, 37 and 17 of 55, 56 and 23 of 79), named giant breeds, PDSA breed figures (paraphrased), the `WalkPlan` bases, factors and 15–120 clamp (the calculator is the same formula in JavaScript), 160 min a week → 23, "about 60%" of owners walk their dog | §1, §2 |
| `docs/how-long-should-i-walk-my-dog.html` | 85 and 122 of 227, 160 → 23, PDSA "1-2 walks per day", the 5-minutes-per-month rule with both the KC and PDSA positions, puppy 0.6 / senior 0.7 stated as our judgment, flat-faced 25 / 35 | §1, §2 |
| `docs/dog-walking-log.html` | No figures about dogs or owners. 2 mph quick-log estimate, milestone days, prices | §5, `Products.storekit` |

Change a number in `WalkPlan.swift` and the calculator's `<option value>`s, its table and the
flat-faced 25 / 35 line must change with it. The site names no competitor and quotes no competitor price.

## 5. App-internal assumptions (not claims about the world)

| Item | Where | Status |
|---|---|---|
| Quick-log distance at 2.0 mph "dog pace" | `WalkPlan.swift:16` | No source; it is an estimate and the UI labels it "est.". Kept |
| Unit-economics targets (65% / 25% / 40%, $1.35 CPI, 10,000 installs) | `playbook/01-strategy.md` §7 | Targets, not facts. Labelled as targets. Kept |
| "243 hours a year" | reveal, site, listing | Arithmetic: (60 − 20) × 365 ÷ 60. Tested |

## 6. The breed list (`GoodWalk/Models/DogBreed.swift`, added 21 Sep 2026)

70 common breeds the owner can search for instead of deciding what "medium" means. **The list
adds no new number to the app.** Choosing a breed sets `size` and `breedType`; the minutes still
come from `WalkPlan`, whose bases and factors are sourced in §1. Both chips stay editable after a
breed is chosen, and the screens that show a breed's minutes also show `GuidelineFootnote`.

| Field | How it was set |
|---|---|
| `size` | The app's own weight bands (`DogProfile.Size.detail`: toy <10 lb, small 10–25, medium 25–55, large 55–90, giant >90) applied to the breed's standard adult weight |
| `type` | The nearest of our eight types to the breed's kennel-club group: Gundog → sporting, Pastoral → herding, Terrier → terrier, Hound → hound, Toy/Utility → companion, Working → working, brachycephalic breeds → flat-faced |
| Breeds straddling a band | Filed in the band whose `WalkPlan` result lands nearest the Royal Kennel Club exercise label for that breed. A Pembroke Welsh Corgi (~28 lb) is filed small, not medium, because the Kennel Club says "up to 1 hour" and small reaches 60 min where medium would reach 90 |

`GoodWalkTests/BreedTests.swift` pins the catalogue to the breeds already sourced in §1: Labrador
and Golden Retriever 120, German Shepherd 120, Border Collie ≥90, Chihuahua 30, Pug and Dachshund
≤60. If a factor in `WalkPlan` moves, those tests fail rather than the list quietly drifting.

**Not verified breed by breed, and this matters.** The Royal Kennel Club's Breeds A to Z and the
PDSA breed pages are both blocked by the network egress proxy in the environment this list was
written in, so individual cards could not be opened the way §1's tables were in the 18 Sep pass.
The groups and weight ranges used are stable published facts, and the pinned breeds match §1, but
the remaining rows are classification by knowledge, not by citation. One pass with the RKC cards
open would settle it. Until then the list is a convenience that fills in two editable chips, which
is the reason it was built that way.

## 7. Tips and facts on waiting screens (`GoodWalk/Models/DogTip.swift`, added 22 Sep 2026)

Short cards shown under the walk timer and on the paywall while plans load. **They add no new
number to the app.** Every figure below is one §1 or §2 already sources, opened on 18 Sep; this
section only records where each one now also appears. Kennel Club and PDSA lines carry "a general
guideline, not veterinary advice" on the card itself, the same caveat `GuidelineFootnote` gives.

| Card (`id`) | Figure or position | Source, as already recorded |
|---|---|---|
| `fact.kc-top-band` | 85 of 227 breeds "More than 2 hours per day" | §2 row 1 (RKC label counts from §1's parse) |
| `fact.pdsa-walks` | "Most dogs need at least 1-2 walks per day" | §1, PDSA overview `.../how-much-exercise-does-your-dog-need` |
| `fact.typical-week` | median 4 walks and 160 min a week among owners who walked; 160 ÷ 7 = 23 | §2, Christian et al. 2013 |
| `fact.owners-who-walk` | "Approximately 60% of DO walked their dog" | §2, Christian et al. 2013 |
| `fact.toy-band` | 18 of 24 Toy breeds "Up to 30 minutes per day" | §1, toy row |
| `fact.small-band` | 47 of 49 small breeds outside Toy "Up to 1 hour per day" | §1, small row |
| `fact.medium-band` | 37 of 55 medium "Up to 1 hour", 17 "More than 2 hours" | §1, medium row |
| `fact.large-band` | 56 of 79 large "More than 2 hours per day" | §1, large row |
| `fact.giant-band` | St Bernard, Mastiff, Newfoundland "Up to 1 hour"; Great Dane "More than 2 hours" | §1, giant row |
| `fact.terrier-band` | all 27 terrier breeds "Up to 1 hour" | §1, terrier row |
| `fact.hound-band` | small and medium hounds mostly "Up to 1 hour"; large hounds 14 of 17 "More than 2 hours" | §1, terrier / hound row |
| `fact.gundog-band` | 21 of 24 large Gundog breeds "More than 2 hours" | §1, sporting row |
| `fact.herding-pdsa` | PDSA Border Collie "a minimum of two hours exercise every day"; German Shepherd "a minimum of two hours" | §1, herding row |
| `fact.flat-faced-band` | Pug, French Bulldog, Bulldog "Up to 1 hour" | §1, flat-faced row |
| `fact.puppy-short` | PDSA puppies: "keep sessions short" | §1, puppy / senior row |
| `fact.puppy-rule` | KC: 5 minutes per month is "a good rule of thumb"; PDSA: "there's no scientific evidence behind this rule" | §1, puppy / senior row. Both positions are given, and the card ends on "your vet can tell you" |
| `fact.senior-routes` | PDSA "shorter, flatter walking routes"; RSPCA "little and often" | §1, puppy / senior row |

**Tips** (`kind: .tip`) carry no figure and no source, and a test fails the build if one gains a
digit. They are of two kinds. *About the app:* each describes behaviour that exists today (the
reminder's Walked ✓ action, walks summing into the ring, one walk counting for every dog on it,
the walk photo on the calendar, the editable target, step-counter distance, the widget, the Siri
phrase "Start a walk in Good Walk"). *Practical:* sniffing still fills the ring, water and bags,
a light after dark, cooler hours on hot days, the leash near roads and livestock, the tag's phone
number, a new route, a paw wipe. None states a health effect.

What the tips deliberately do not say: anything about weight, lifespan, joints, behaviour or
anxiety, and anything telling an owner what their dog "needs". `GoodWalkTests/DogTipTests.swift`
checks the whole list against those words. Heat-and-flat-faced-breed advice, the hot-pavement
hand test and tick checks were left out: all widely given, but each is a claim about a dog's
health that would need its own row here, and the welfare charities' pages are blocked by the
egress proxy in the environment this was written in.

## Still open

1. Puppy 0.6 / senior 0.7: our judgment; no published ratio exists in the sources checked.
2. Fi $189/yr: from a third-party review; Fi's store would not render.
3. Tractive Dog Walk deprecation wording: help page returned 403; snippet only.
4. The four small free competitors and the Fi / collar-review characterisations: unchecked, internal only.
5. Walk Your Dog Month: search results only.
6. The 70 breed rows in §6: size band and type per breed are unverified against the RKC cards
   (proxy-blocked). Re-check with the cards open; the pinned breeds in §1 are already covered.

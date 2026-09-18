# Onboarding + Paywall — screen by screen, with the reason each screen exists

Onboarding moves the user through a belief sequence:

> I have this problem → this app understands my dog → this might actually help us → I want the result → (pay)

Every screen below maps to one of those beliefs. If a screen doesn't move a belief, it gets cut.
This is hypothesis #1, not the final flow. The step enum lives in
`GoodWalk/Views/Onboarding/OnboardingFlow.swift` so reordering is a one-line change.

| # | Step | Belief it moves | What it does | Why |
|---|---|---|---|---|
| 1 | **hook** | "I have this problem" | Full-bleed: "The typical dog gets about 23 minutes a day. Many are built for more." Source line underneath (160 min a week, median of 29 studies, Christian et al. 2013). One button: "What does my dog need?" | Every owner suspects this already. The CTA is a question they actually want answered. No welcome, no feature list. |
| 2 | **dog** | "This app understands my dog" | Name + optional photo (system photo picker, no library permission). | From here on every screen says "Rex", not "your dog". The photo is what makes the ring, the widget and the card theirs. |
| 3 | **size** | "This app understands my dog" | Toy / small / medium / large / giant. | First input to the target. One tap. |
| 4 | **breed** | "This app understands my dog" | Breed-type chips: companion, terrier, hound, sporting, herding, working, flat-faced, mixed. Plus age: puppy / adult / senior. | Types, not 300 breeds: nobody scrolls a list, and mixed-breed owners aren't excluded. Age and flat-faced pull the target *down*, which is what makes it credible. |
| 5 | **usual** | "I have this problem" | "How long is a normal day's walking right now?" 10 / 20 / 30 / 45 / 60. | Making them *state* the number is a small commitment and the input for the reveal. It also becomes the default for "Walked ✓". |
| 6 | **reveal** | "This might help" | Animated count-ups: "Rex needs about 60 min a day." → "The typical dog gets about 23." → "You said 20. That's 243 hours a year Rex is missing." General-guideline footnote. | The aha. Three numbers, screenshot-able. If the owner already meets the target the gap is 0, so the third block turns into praise ("Rex is already there. The hard part now is every day.") instead of "0 hours". |
| 7 | **plan** | "This might help" | Confirm or adjust the daily target. Set the reminder time (default 5:30 PM). CTA requests notification permission. | The commitment and the mechanism on one screen. Permission is asked with the reason on screen. Adjustable target keeps us out of advice territory. |
| 8 | **first** | "I want the result" | "Has Rex walked today?" Minute chips log today's first walk. Escape hatch: "Not yet. We'll start with the next walk." | The product is used *before* the paywall. This is the screen that sells. |
| 9 | **result** | "I want the result" | Ring fills around Rex's photo. "Day 1 with Rex." First share card with the photo. | Immediate win + the first shareable artifact, with their dog's face on it. |
| 10 | **paywall** | (pay) | Hard paywall. Yearly w/ 7-day trial preselected, monthly + lifetime as alternates. | See below. |

The reveal math (60 vs 20 → 40 min × 365 ÷ 60 = 243 hours) and the target formula are documented
in `playbook/01-strategy.md` section 6 and live in `GoodWalk/Models/WalkPlan.swift`.

## Paywall design decisions

- **Hard paywall, not soft.** The user has already logged a real walk and seen a real card with
  their dog on it. Soft paywalls in this category train people that free is enough (see: every
  free tracker's retention).
- **Trial-first framing.** Headline is "Try Good Walk free for 7 days", not "Subscribe".
  Timeline graphic: Today (full access) → Day 5 (reminder) → Day 7 (charged). The reminder toggle
  is on by default and actually schedules a local notification. Surprise charges are the most
  common one-star review on any subscription app; the toggle is the answer to that fear.
- **Yearly preselected**, shown as "$2.08/mo, billed $24.99/yr". Monthly at $4.99 exists to make
  yearly obvious. Lifetime at $39.99 catches subscription-haters.
- **Personal line above the plans:** "Rex's plan: 60 min a day. Reminder at 5:30 PM." with the
  photo. The thing being bought is already built and has their dog's name on it.
- **Close button** appears after 2 seconds, top-left, low contrast. Apple requires dismissal;
  the delay is standard.
- **Restore + Terms + Privacy** in the footer (App Review requires all three).

## Copy rules for every screen

- The dog's name, never "your dog", once we have it.
- "About", "guideline", "the typical dog". A number about dogs or owners needs a row in `playbook/12-sources.md`. Never "should", "must", "vet-recommended" or any health
  outcome ("lives longer", "loses weight", "less anxious").
- No guilt imagery. The reveal is the only screen that stings, and it stings with a number.

## What to A/B test first (in order)

1. Hook copy ("The typical dog gets about 23 minutes a day" vs. "Your dog can't ask for a longer walk" vs. "How much walking does your dog actually need?").
2. Reveal order (the dog's target first vs. "hours a year missing" first).
3. First-walk screen: default to logging vs. asking.
4. Paywall: trial reminder toggle on vs. off by default.
5. Price: $24.99 vs. $29.99 yearly.

Everything else waits until these five have a read.

# App Store listing

Everything below is written to the same belief sequence as onboarding. The listing is the
first onboarding screen.

## Title (30 chars max)

`Good Walk: Dog Walk Streak`

"Dog walk" is what people type; "streak" is what makes us different from the trackers. 26 chars.

## Subtitle (30 chars max)

`Daily walk goal for your dog`

## Promotional text (170 chars, editable without review)

`Walk Your Dog Week is 1–7 October. One tap a day, your dog's face in the ring, and a streak that belongs to them. No collar. No account. No map.`

Swap in December: `New year, same dog, longer walks. …`

## Keywords (100 chars, comma-separated, no spaces, don't repeat title words)

`puppy,tracker,pet,walking,exercise,reminder,habit,leash,steps,walkies,pedometer,routine,timer,log`

97 chars. Don't add competitor brand names (Tractive, Fi); Apple rejects them.

## Description

The first three lines show before "more". They have to carry everything.

```
Your dog needs a walk every day. Good Walk makes it a streak.

Tell Good Walk about your dog once. It suggests a daily walk target, reminds you at the time
you pick, and counts every walk, mile and day in a row. Your dog's photo is on all of it.

WHY GOOD WALK
• One tap. A reminder asks "Has Rex had a walk today?" Tap Walked, or start a walk. Done.
• A target for your dog. Size, breed type and age give a daily minutes guideline. Adjust it
  any time.
• The streak belongs to the dog. Their name and photo are on the home screen, the widget and
  every card.
• A missed day is just a missed day. Your streak resets. Your miles, hours and history don't.
• Cards worth posting. 1, 3, 7, 14, 30, 60, 100 and 365 days each get one, with your dog on it.
• No collar, no map, no account. Distance comes from your phone's step sensor. Nothing leaves
  your phone.

HOW IT WORKS
1. Add your dog: name, photo, size, breed type, age.
2. See their daily walk target and pick a reminder time.
3. Tap once a day, or run the walk timer. Watch the ring fill and the streak grow.

AN EXAMPLE
Rex is a medium adult mixed breed. His guideline is about 60 minutes a day. At 20 minutes a
day, that's 243 hours a year he's missing. Good Walk shows your dog's numbers, not ours.

Say "Start a walk" to Siri, tap the Home Screen widget, or put it on your Action Button.

Good Walk is a habit tracker. Walk targets are general guidelines, not veterinary advice. Ask
your vet what's right for your dog, especially for puppies, seniors, flat-faced breeds and
dogs with health conditions.

PRICING
Good Walk is free to try for 7 days, then $24.99/year, $4.99/month, or $39.99 once for life.
Subscriptions renew automatically unless cancelled at least 24 hours before the end of the
current period. Manage or cancel in Settings > Apple ID > Subscriptions.

Privacy policy: https://goodwalk.app/privacy.html
Terms of use: https://goodwalk.app/terms.html
```

## Screenshots (6.9-inch, in this order)

| # | Screen | Caption (top of image, 5 words max) |
|---|---|---|
| 1 | Lock screen notification "Has Rex had a walk today?" with the Walked ✓ button | One tap. That's it. |
| 2 | Home: Rex in the ring, "60 of 60 min", 30-day streak, week bars | Your dog's streak. |
| 3 | Reveal: "Rex needs about 60 min" vs "22" | See what your dog needs. |
| 4 | Milestone card: "47 miles walked with Rex · 30-day streak" | A card every milestone. |
| 5 | Walk timer with live distance | No collar. No map. |
| 6 | Widget on a Home Screen | Start a walk from anywhere. |

Raw captures for 2–5 come from ScreenshotMode (`-screenshot home`, `reveal`, `milestone`,
`walking`) and land in `docs/screenshots/`. Screenshot 1 needs a device recording of the
notification; screenshot 6 is the widget on a real Home Screen.

**The seeded captures use an illustrated sample dog. Re-shoot the App Store set with a real
dog photo.** A real dog's face in the ring is the whole pitch; an illustration undersells it.
Use your own dog or one you have written permission to use.

## App preview video (15–30s)

Screen recording of the demo in `docs/07-launch-videos.md` video #1, no voiceover, captions on.

## App Review notes

```
Good Walk is a personal habit tracker for dog owners. It is not a veterinary or medical app:
it does not diagnose, treat or make health claims. The daily walk target is a general
guideline computed on-device from the dog's size, breed type and age; the app labels it as a
guideline, tells users to ask their vet, and lets them change it.

No account, no server, no data leaves the device. The dog's photo is chosen with the system
photo picker and stored locally. The app does not use location. Motion & Fitness permission
is optional and used only to measure walk distance from the pedometer (CoreMotion), on-device;
if denied, distance is estimated from walk duration. Local notifications only, scheduled at a
time the user picks, with two actions (log the usual walk / start a walk).

To test: enter any dog in onboarding, log a first walk on step 8, see the result card.
Purchases can be tested with the yearly plan; the 7-day trial is configured in App Store
Connect. The widget extension (app.goodwalk.goodwalk.widgets) shows the dog's photo, today's
progress and a button that opens the app and starts a walk.
```

## Category

Primary: Health & Fitness. Secondary: Lifestyle.

## Age rating

Everything "None". Expect 4+.

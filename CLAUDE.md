# Good Walk — notes for Claude Code sessions

iOS app (SwiftUI, iOS 17+). Read `README.md` and `playbook/01-strategy.md` first.
(Repo folder is `dogwalk/`, the working slug. The brand is Good Walk; see `playbook/05-naming.md`.)

## Build
- The Xcode project is **generated**: `xcodegen generate` (brew install xcodegen). Never commit `GoodWalk.xcodeproj`.
- Any change to targets, files outside existing folders, entitlements or Info.plist keys goes in `project.yml`, then regenerate.
- Build: `xcodebuild build -project GoodWalk.xcodeproj -scheme GoodWalk -destination 'platform=iOS Simulator,name=<an iPhone>' CODE_SIGNING_ALLOWED=NO`
- Tests: same with `test -only-testing:GoodWalkTests`.
- CI (`.github/workflows/build.yml`) does exactly this on `macos-26`. Keep it green.
- Screens: launch with `-screenshot <hook|dog|size|breed|usual|reveal|plan|first|result|paywall|home|dogs|walking|log|milestone|stats|walkcard|day|settings|share>`
  to open one screen with seeded data (`GoodWalk/App/ScreenshotMode.swift`). `scripts/capture-screenshots.sh` and the
  `Screenshots` workflow capture all of them and write PNGs to `docs/screenshots/`. Look there before and after UI changes.
- Brand images: `swift scripts/make-brand.swift` regenerates the app icon, the illustrated sample dog
  (`SampleDog`, used only by screenshot mode), `docs/brand/`, and the site's `docs/og.png`, `favicon-32.png`,
  `apple-touch-icon.png`, `icon-192.png` and `icon-512.png`.

## Public vs private
- `docs/` is the **public** website: GitHub Pages serves every file in it at getgoodwalk.app. Only site files go
  there (HTML, `robots.txt`, `sitemap.xml`, `site.webmanifest`, images, `CNAME`, `.nojekyll`). Never put notes in it.
- Internal notes (strategy, launch, outreach, sources: the numbered `NN-*.md` files) live in `playbook/`, which is
  not served. Links from a note to a site asset are `../docs/...`.
- The site's "See your dog in it" section (`#your-dog` in `docs/index.html`) previews a visitor's own photo inside the
  ring. It is pure client-side: a blob URL in an SVG `<image>`, revoked on removal and on `pagehide`. Nothing is uploaded
  and no script is fetched, which is what lets the copy keep saying nothing leaves your phone.
- The site is static HTML with inline CSS: no build step, no frameworks, no third-party scripts, no tracking. Every
  page has its own title, description, canonical, Open Graph tags and JSON-LD; the FAQ JSON-LD must mirror the
  visible FAQ text exactly. New page → add it to `docs/sitemap.xml` and the footer nav on every page.
- Every number on the site must match `playbook/12-sources.md` (§4b lists where each sits) and prices must match
  `Products.storekit`. The calculator on `docs/how-much-exercise-does-my-dog-need.html` is `WalkPlan` in JavaScript;
  change one and change the other.

## Runtime notes
- No restricted entitlements. Only App Groups (`group.app.getgoodwalk.goodwalk`) for the widget.
- The daily nudge is a repeating `UNCalendarNotificationTrigger` with two actions (`ReminderManager`).
  "Walked ✓" logs the user's usual walk length without opening the app via the delegate → `AppState.quickLog`.
  "Start a walk" opens the app on the timer.
- The walk timer is a stored start `Date` (`AppState.activeWalkStart`), not a running clock, so it survives the app
  being killed. Walks under 30 seconds are dropped as mis-taps.
- Distance sits behind `DistanceTracker` (`GoodWalk/Services/DistanceTracker.swift`): `PedometerDistanceTracker`
  (CoreMotion, no location permission) on a phone, `MockDistanceTracker` (seeded, deterministic) in the simulator and
  tests. Quick logs and denied Motion permission fall back to a 2 mph estimate and are labelled "est.".
- The dog photo is two JPEGs in the App Group container (`Shared/DogPhotoStore.swift`): full size for the app and
  share card, 300 px for the widget. Picked with `PhotosPicker`, so no photo-library permission.
- The App Intent (`StartWalkIntent`, in both targets) sets `pendingStartWalk` in the App Group and opens the app;
  `HomeView` consumes it and starts the timer (behind the paywall like any other start).
- The walk Live Activity (`Shared/WalkActivityAttributes.swift`, `WalkActivityController`, `GoodWalkWidgets/WalkLiveActivity.swift`)
  starts in `AppState.startWalk` and ends in `finishWalk` / `cancelWalk`. It is best-effort and skipped in unit tests and
  screenshot mode. The timer text is rendered by the system from the start date, so it never needs updates.
- iPhone Duo: the inner display is a regular width class; `RootView` caps content at `Theme.regularWidthMax`. The Live
  Activity is what shows on the outer display while folded. No fold API is used anywhere.
- The end-of-walk card is `WalkResultView` (presented when `lastWalk` is a `.timer` walk) plus
  `ShareCardView.walk(...)`. The photo comes from `CameraPicker` (camera) or `PhotosPicker` (library).
  It is **kept with that walk** by `WalkPhotoStore` (`walk-<uuid>.jpg` plus a 300 px thumb in the App
  Group container), so the day can be opened again months later; `Walk.hasPhoto` mirrors it so the month
  grid never stats 31 files. Deleting the walk, or the last dog on it, deletes the photo. It is still
  never uploaded, and that is the line the privacy copy makes: on the phone, yes; off it, only when the
  user shares a card. `NSCameraUsageDescription` is in `project.yml`; the camera is unavailable in the
  simulator, so the picker falls back to the library there.
- The same `WalkResultView` is the walk's detail screen. `StatsView`'s month grid marks days that have a
  photo, and tapping any day with walks opens `DayDetailView`, which lists that day's walks and opens one.
  If you change what a photo promises, change `docs/privacy.html` in the same commit: it is a published
  policy with an effective date, not just copy.
- StoreKit uses `GoodWalk/Resources/Products.storekit`; product IDs `goodwalk.yearly`, `goodwalk.monthly`, `goodwalk.lifetime`.
  `SIMCTL_CHILD_GOODWALK_FORCE_PRO=1` unlocks Pro in debug builds.
- **More than one dog.** `AppState.dogs` is the roster and `AppState.dog` is the one on screen;
  every walk carries `dogIDs`, the dogs it counted for. One leash walk with both dogs is *one*
  walk on both rings, so miles are never double counted; an empty `dogIDs` means "everyone",
  which is what seeded and single-dog walks are. Each dog keeps their own `dailyGoal`.
  The home-screen streak is `Stats.Household`: a day counts when every dog who had already
  arrived (`DogProfile.addedOn`) walked that day, so adding a dog can't wipe an existing streak.
  Milestones fire on the household streak, the one actually on screen. A second dog is added in
  Settings, never in onboarding: the funnel before the paywall stays exactly 10 steps.
- One notification however many dogs: its text is fixed when scheduled, so it names the whole
  household, and "Walked ✓" logs the usual walk for whoever hasn't been out at tap time
  (`AppState.logUsualWalkForDogsNotWalkedToday`). Reschedule it whenever a dog is added,
  removed or renamed.
- The widget shows the dog currently on screen plus the household streak, so it needs no idea how
  many dogs there are. `DogPhotoStore` keeps one full JPEG per dog (`dog-<uuid>.jpg`) and mirrors
  a 300 px copy of the shown dog to `dog-widget.jpg`.
- All stats are derived (`Stats.compute`) from the walk log + the target. Never store a streak; recompute it.
- `DogBreed` is a searchable list of 70 common breeds. Picking one only fills in `size` and
  `breedType` (and stores `breedName` as a label); the minutes still come from `WalkPlan`, and both
  chips stay editable afterwards. It adds no new number to the app, which is why it could ship
  without a new sourced figure: see `playbook/12-sources.md` §6, including the note that the rows
  are not verified card by card against the Kennel Club. `GoodWalkTests/BreedTests.swift` pins the
  breeds that §1 already sources, so a factor change fails there instead of drifting.
- The recommendation math is `WalkPlan` and nothing else. Its tables are mirrored in `playbook/01-strategy.md`
  and sourced in `playbook/12-sources.md`. A new number about dogs, owners or competitors needs a row there first.

- iPhone Duo: `scripts/duo-screenshots.sh` builds, tests and captures every screen on the iPhone Duo simulator
  (Xcode 27.1+, iOS 27.1 runtime). Xcode 27 replaced Simulator.app with **Device Hub**, which also owns the fold
  (pose) control; there is no simctl API for posture, so `--pose closed` waits for you to fold it by hand. With
  Device Hub closed the device reports the outer display; a screenshot that comes back near-black means the app
  had not drawn yet, which is why the script retries.

## Conventions
- One core loop, no feature creep: onboarding → paywall → daily walk → milestone card. New features need a line in
  `playbook/01-strategy.md` explaining which funnel metric they move.
- Every funnel step logs an `AnalyticsEvent`. Add events there, never ad-hoc strings. PostHog is the sink
  when `Config.postHogKey` is set; keep it anonymous (no `identify`, no replay).
- Copy lives in the views. Short, direct, warm, never guilt-tripping. A missed day is a missed day, not a bad owner.
  The dog's name goes in the sentence wherever it fits; the streak is theirs.
- **No veterinary claims.** Targets are "a general guideline", never "your dog needs" as medical fact, never health
  outcomes (weight, lifespan, behaviour fixes). Wherever a guideline number is shown, `GuidelineFootnote` or the
  settings footer is on screen.
- One theme (warm, light only), tokens in `GoodWalk/Design/Theme.swift`. The widget mirrors them in `WidgetPalette`.

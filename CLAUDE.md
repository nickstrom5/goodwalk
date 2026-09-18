# Good Walk — notes for Claude Code sessions

iOS app (SwiftUI, iOS 17+). Read `README.md` and `docs/01-strategy.md` first.
(Repo folder is `dogwalk/`, the working slug. The brand is Good Walk; see `docs/05-naming.md`.)

## Build
- The Xcode project is **generated**: `xcodegen generate` (brew install xcodegen). Never commit `GoodWalk.xcodeproj`.
- Any change to targets, files outside existing folders, entitlements or Info.plist keys goes in `project.yml`, then regenerate.
- Build: `xcodebuild build -project GoodWalk.xcodeproj -scheme GoodWalk -destination 'platform=iOS Simulator,name=<an iPhone>' CODE_SIGNING_ALLOWED=NO`
- Tests: same with `test -only-testing:GoodWalkTests`.
- CI (`.github/workflows/build.yml`) does exactly this on `macos-26`. Keep it green.
- Screens: launch with `-screenshot <hook|dog|size|breed|usual|reveal|plan|first|result|paywall|home|walking|log|milestone|settings|share>`
  to open one screen with seeded data (`GoodWalk/App/ScreenshotMode.swift`). `scripts/capture-screenshots.sh` and the
  `Screenshots` workflow capture all of them and write PNGs to `docs/screenshots/`. Look there before and after UI changes.
- Brand images: `swift scripts/make-brand.swift` regenerates the app icon, the illustrated sample dog
  (`SampleDog`, used only by screenshot mode) and `docs/brand/`.

## Runtime notes
- No restricted entitlements. Only App Groups (`group.app.goodwalk.goodwalk`) for the widget.
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
- StoreKit uses `GoodWalk/Resources/Products.storekit`; product IDs `goodwalk.yearly`, `goodwalk.monthly`, `goodwalk.lifetime`.
  `SIMCTL_CHILD_GOODWALK_FORCE_PRO=1` unlocks Pro in debug builds.
- All stats are derived (`Stats.compute`) from the walk log + the target. Never store a streak; recompute it.
- The recommendation math is `WalkPlan` and nothing else. Its tables are mirrored in `docs/01-strategy.md`.

## Conventions
- One core loop, no feature creep: onboarding → paywall → daily walk → milestone card. New features need a line in
  `docs/01-strategy.md` explaining which funnel metric they move.
- Every funnel step logs an `AnalyticsEvent`. Add events there, never ad-hoc strings. PostHog is the sink
  when `Config.postHogKey` is set; keep it anonymous (no `identify`, no replay).
- Copy lives in the views. Short, direct, warm, never guilt-tripping. A missed day is a missed day, not a bad owner.
  The dog's name goes in the sentence wherever it fits; the streak is theirs.
- **No veterinary claims.** Targets are "a general guideline", never "your dog needs" as medical fact, never health
  outcomes (weight, lifespan, behaviour fixes). Wherever a guideline number is shown, `GuidelineFootnote` or the
  settings footer is on screen.
- One theme (warm, light only), tokens in `GoodWalk/Design/Theme.swift`. The widget mirrors them in `WidgetPalette`.

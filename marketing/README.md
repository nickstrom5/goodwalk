# Marketing screenshots

Not served by the website. GitHub Pages only publishes `docs/`, so anything here is internal.

## Stats screen

| File | Device | What it shows |
|---|---|---|
| `screenshots/stats-compact.png` | iPhone 17 Pro, iOS 26.5 | The single-column layout. This is what an iPhone shows, and what iPhone Duo shows **folded** on its outer display. |
| `screenshots/stats-wide.png` | iPad Pro 11-inch, iOS 26.5 | The two-pane layout: the three numbers in a column beside the month grid. This is what iPhone Duo shows **unfolded** on its inner display. |

Both were captured with a clean status bar:

```bash
xcrun simctl status_bar <device> override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
```

### Why these are not literal iPhone Duo captures

`StatsView` picks its layout from the width it is actually given, not from the device, so any
screen at least 620pt wide gets the two-pane version. The iPad and the Duo's inner display are
both regular-width, so the layout in `stats-wide.png` is the same one the Duo renders.

Real Duo captures need the iOS 27.1 simulator runtime. On 20 Sep 2026 that runtime lost its
mount point: `simctl runtime list` reports it Ready, but its volume under
`/Library/Developer/CoreSimulator/Volumes/` is missing and `simctl` will not remount it, so the
Duo device shows as "runtime profile not found". A Mac restart normally restores cryptex mounts.
Once it boots again, `scripts/duo-screenshots.sh` captures the real thing, and the folded pose
still has to be set by hand with the pose control in Device Hub (Xcode 27 removed Simulator.app
and there is no simctl API for posture).

## iPhone Duo poses

Captured on the iPhone Duo simulator (iOS 27.1) at `marketing/screenshots/duo/`, prefixed by pose.

| Pose | Active display | What the app does |
|---|---|---|
| `folded-*` | outer, 466x678pt portrait | Single column, like any iPhone. Short enough that the paywall collapses its trial timeline. |
| `open-*` | inner, 669x951pt | Single column capped at 560pt and centred; the stats screen splits into two panes. |
| `half-*` | inner, 951x669pt landscape | Same as open but short. Full screen, no letterboxing and nothing lost to the crease. |

There is no simctl API for the hinge: the pose is set by hand with the pose control in Device
Hub, and `simctl io <device> screenshot` follows whichever display is active. Identify it by
capturing both class-0 displays and taking the one that is not near-black. The display UUIDs
change on every boot, so read them from `simctl io <device> enumerate` rather than hard-coding.

Not yet verified: the Home Screen widget in the tent pose (StandBy). Placing a widget needs a
drag on the Home Screen, and the simulator's HID input is unavailable under Xcode 27.

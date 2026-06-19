# App Store kit — Baby Light

Everything needed to submit Baby Light to the App Store.

## Contents
| File / folder | What it is |
|---|---|
| **`METADATA.md`** | Copy‑paste‑ready listing: name, subtitle, keywords, promo text, full description, "What's New", review notes, **keyword research**, the **red‑light science**, category/privacy guidance, devices/targets, and the **Apple Watch app** notes. Start here. |
| **`screenshots/`** | iPhone set — 6 screenshots, **1320 × 2868** (iPhone 6.9″). |
| **`screenshots/ipad/`** | iPad set — 5 screenshots, **2064 × 2752** (iPad 13″). |
| **`screenshots/watch/`** | Apple Watch set — 3 screenshots, **422 × 514** (Watch Ultra 3 / 49 mm). |
| **`raw/`** | Un‑captioned **real** captures from the simulator — iPhone (`01_controls_red`, `02_fullscreen_red`) and Apple Watch (`watch_red`). |
| **`make_screenshots.py`** | The generator that builds all three sets. Re‑run to tweak copy, colors, or order. |

## Screenshot order (matches `METADATA.md` §5)
1. `01_hero_red` — A red night light made for babies
2. `02_science` — Light that won't fight melatonin
3. `03_colors` — Four sleep‑friendly colors
4. `04_timer` — Set it and let it fade (auto‑off)
5. `05_brightness` — Swipe to dim. Closes to black.
6. `06_closing` — No ads. No sign‑up. No noise.

## Regenerate the screenshots
```bash
cd AppStore
python3 make_screenshots.py          # needs Pillow (pip install pillow)
```
Edit the `s1()`…`s6()` builders or the palette/font constants at the top of the script
to change copy or styling. The controls‑panel mock (`render_controls_screen`) is a 1:1
recreation of the SwiftUI `ControlsOverlay`, cross‑checked against `raw/01_controls_red.png`.

## App icon
`../Baby Light/Assets.xcassets/AppIcon.appiconset/AppIcon.png` is **1024 × 1024, RGB,
no alpha** — fully App Store compliant. No change required to ship. (See `METADATA.md`
for an optional note on the dark/tinted icon variants.)

## Before you hit submit — checklist
- [x] Branding unified to **"Baby Light"** (Home screen + in‑app title).
- [x] iPhone + iPad + Apple Watch screenshot sets generated.
- [x] Standalone Apple Watch app added and builds (embedded in the iPhone app); top‑corner clock hidden.
- [x] **Every App Store Connect field specified** in METADATA §1 (categories, age rating answers, pricing, export compliance, App Review contact, privacy label).
- [ ] **Host the Privacy Policy** (text ready in METADATA §8) and set the Privacy Policy URL — *required, common rejection if missing*.
- [ ] Confirm the **Support URL** resolves; add your **App Review phone number**.
- [ ] Paste Name / Subtitle / Keywords / Promo / Description / What's New into App Store Connect.
- [ ] Upload **all three** screenshot sets: `screenshots/` (iPhone), `screenshots/ipad/`, `screenshots/watch/`.
- [ ] Set App Privacy to **"Data Not Collected"**, price **Free**, age **4+**.
- [ ] Paste the **App Review notes** (double‑tap reveals controls — prevents a rejection).
- [ ] If "Baby Light" isn't a Dogo product, swap the `dogo.app` URLs/email for your own.
- [ ] (Optional) Rename the Xcode target/scheme from "Baby Night Light" → "Baby Light" (cosmetic).

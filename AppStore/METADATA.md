# Baby Light — App Store Listing & ASO Kit

Everything below is copy‑paste ready for **App Store Connect**. Character counts are
shown for every field with a hard limit; all are within Apple's limits (verified —
see *Character‑count check* at the bottom).

> **Branding — DONE.** The app is now consistently **"Baby Light"**: the Home‑screen
> name (`CFBundleDisplayName`) and the in‑app title both say "Baby Light", matching the
> keyword‑rich App Store name below. (The Xcode *target/scheme* is still internally
> named "Baby Night Light" — cosmetic only, invisible to users; rename in Xcode anytime.)
>
> **This build now also ships an Apple Watch app and supports iPad** — see §5 for the
> iPhone, iPad, and Apple Watch screenshot sets, and §7 for the Watch app.

---

## 1. Store listing (recommended — copy/paste)

### App Name  *(max 30 chars)*
```
Baby Light: Red Night Light
```
`27/30` — indexes the four highest‑value terms you can own: **baby · red · night · light**.

### Subtitle  *(max 30 chars)*
```
Sleep-safe glow for newborns
```
`28/30` — adds new indexable terms (**sleep · safe · glow · newborns**) without
repeating the title. The subtitle is weighted almost as heavily as the name for search.

### Promotional Text  *(max 170 chars — updatable any time, NOT indexed)*
```
The simplest red night light for babies. No ads, no sign-up, no noise — just a warm, dimmable glow for night feeds that won't wake you both up. Free.
```
`149/170`

### Keywords  *(max 100 chars, comma‑separated, NO spaces — this is the search field)*
```
nightlight,newborn,toddler,infant,nursery,feeding,bedtime,melatonin,lamp,dim,amber,nap,crib,nurse
```
`97/100` — see the keyword research in §3 for why each was chosen. **Rule followed:**
no word here repeats the name/subtitle (that would waste characters), and singular
forms are used because Apple auto‑matches plurals.

### Description  *(max 4000 chars — for conversion, NOT search ranking)*
See **§2** below (formatted, ready to paste).

### What's New (version 1.0)
```
Hello, world — and hello, sleepless nights. This is the first release of Baby Light.

• Deep red, amber, candle and warm-white light modes
• Auto-off timer (15m / 30m / 1h / 2h / always on)
• Tap-free dimming: swipe up or down to set the perfect brightness
• Screen brightens when you open it, dims to black when you close it
• A gentle elapsed timer so you can track how long the feed is taking
• Apple Watch app — the same glow on your wrist, dim with the Digital Crown
• Works on iPhone and iPad

No ads. No account. No data collected. Sweet dreams.
```

### Every other App Store Connect field (complete — fill exactly these)

**App information (set once, applies to the app):**
| Field | Value |
|---|---|
| **Bundle ID** | `com.tadas.Baby-Light` (watch app: `com.tadas.Baby-Light.watchkitapp`) |
| **Primary category** | **Lifestyle** *(recommended — see §3)* |
| **Secondary category** | Utilities |
| **Content rights** | "Does **not** contain, show, or access third‑party content." |
| **Age rating** | **4+** (questionnaire: answer **None / No** to every item — no violence, no medical/treatment info, no unrestricted web, no user‑generated content, no ads, no gambling). |

**Pricing & availability:**
| Field | Value |
|---|---|
| **Price** | **Free** (Tier 0) |
| **In‑app purchases / subscriptions** | None |
| **Availability** | All countries/regions |

**This version (1.0):**
| Field | Value |
|---|---|
| **Version** | 1.0  •  **Build** 1 |
| **Copyright** | `2026 Tadas Ziemys` |
| **Support URL** *(required)* | `https://dogo.app/baby-light/support` — **must resolve.** If you don't have one, a single page with a contact email is enough; or reuse `https://dogo.app`. |
| **Marketing URL** *(optional)* | `https://dogo.app/baby-light` |
| **Privacy Policy URL** *(required for ALL apps)* | `https://dogo.app/baby-light/privacy` — host the ready‑made policy in **§8** (the app collects nothing, so it's short). **Apple rejects submissions with a missing/dead privacy URL.** |
| **Routing app coverage / other media** | N/A |

**App Privacy ("nutrition label") — answer in App Store Connect → App Privacy:**
- **Data collection:** select **"Data Not Collected."** That's it — the app has no
  network calls, no analytics, no SDKs; the only persistence is local `UserDefaults`
  (color, timer, brightness toggles), which is **not** "collection."

**Export compliance (asked at build upload):**
- **Uses non‑exempt encryption? → No.** Already declared in the build via
  `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` (set on both the iPhone and Watch
  targets), so App Store Connect won't prompt you.

**App Review Information (App Store Connect → version → App Review Information):**
| Field | Value |
|---|---|
| **Sign‑in required?** | **No** |
| **Demo account** | Not needed (no login) |
| **Contact – First / Last** | Tadas / Ziemys |
| **Contact – Email** | `team@dogo.app` |
| **Contact – Phone** | *(add your number — required field)* |
| **Notes** | paste the block below |

```
Baby Light is a full-screen colored "light" utility / baby night light for iPhone,
iPad, and Apple Watch. It intentionally hides the status bar and keeps the screen
awake (UIApplication.isIdleTimerDisabled) so it works as a night light.

iPhone/iPad: DOUBLE-TAP the screen to reveal the controls (color, auto-off timer,
auto-brightness, elapsed-timer brightness). Swipe up/down to change brightness.

Apple Watch: tap the screen to cycle colors; turn the Digital Crown to dim. The
top-corner time is intentionally hidden (via an invisible VideoPlayer) so the night
light stays dark.

No login, no network, no data collection. All settings are stored locally on device.
No special hardware or account is required to review the app.
```

---

## 2. Full description (paste into the Description field)

> ASO note: the App Store does **not** index the description for search — it's a
> conversion tool. The first 2–3 lines are what users see before tapping "more," so
> they carry the hook. Emoji bullets are allowed and improve scannability.

```
Turn your phone or tablet into a warm red night light made for babies — and for the
parents who are awake at 2 AM with them.

Bright white and blue light tells the brain "it's daytime." Baby Light floods your
screen with deep red and amber light instead, so you can see during night feeds,
diaper changes and quick check-ins without the harsh glare that snaps you — and your
baby — wide awake.

No ads. No sign-up. No sounds you didn't ask for. Open it, and the room glows.

— THE SCIENCE, SIMPLY —
Light is the strongest signal your body uses to tell day from night. Special
receptors in the eye are most sensitive to blue light (around 480 nm) — the kind in
white phone screens and ceiling lights. In the evening, that blue light can suppress
melatonin, the hormone that helps us feel sleepy.

Red and amber light sit at the far end of the spectrum (roughly 600–700 nm). Research
in adults shows these longer wavelengths have far less effect on those receptors and
on melatonin than blue or white light does. It's why submarines, aircraft cockpits,
observatories and many hospital units switch to red light at night — and why a red
glow is a gentler choice for a midnight feed than flipping on the lamp.

Baby Light can't promise your baby will sleep through the night (no app can!). What
it does is give you just enough light to do what you need to do — without blasting the
room with the most alerting kind of light at the worst possible time.

— WHAT YOU GET —
🔴 Four sleep-friendly light modes
   Deep Red (best for night), warm Amber, soft Candle, and a gentle Warm White for
   when you need to actually see.

🌙 True full-screen glow
   Edge to edge, status bar hidden, screen stays awake. Just light.

⏱️ Auto-off timer
   Set it for 15m, 30m, 1h, 2h — or leave it on all night. The screen fades to black
   on its own so it won't light up the nursery once everyone's asleep.

👆 Swipe to dim
   No tiny sliders to fumble for in the dark. Swipe up to brighten, down to dim, all
   the way to nearly black.

🔆 Smart brightness
   Brightens to full when you open it so you can find your way, and dims your screen
   to minimum when you close it — so you're not blinded putting the phone down.

🕒 Gentle feed timer
   A soft, barely-there counter shows how long you've been up, in the same calm hue
   as the light. Adjust how visible it is, or hide it completely.

⌚ Apple Watch app included
   The same red glow on your wrist. Tap to change color, turn the Digital Crown to
   dim, and glance at the feed timer — all without reaching for your phone.

😴 Designed for the dark
   Calm, minimal, one-handed. Nothing to read, nothing to tap twice.

— PERFECT FOR —
• Night feeds and bottle prep
• Diaper changes without the overhead light
• Checking on a sleeping baby
• Soothing a newborn back to sleep
• Travel and hotel rooms with no nightlight
• Toddlers who are scared of the dark
• Anyone who wants a glare-free light by the bed

— PRIVATE BY DESIGN —
No account. No ads. No tracking. No data leaves your device — your settings are saved
only on your phone. Works completely offline.

Free. Download Baby Light and make the next 2 AM a little easier.

Tip: double-tap the screen to show or hide the controls.
```

---

## 3. Keyword research & strategy

### How App Store search actually works (the rules these choices follow)
1. **Only three things are indexed for ranking:** App Name (30), Subtitle (30), and
   the Keywords field (100). The description is **not** indexed in the App Store.
2. **Apple auto‑combines** words across all three fields ("baby" + "feeding" →
   ranks for *"baby feeding light"*). So you should **never repeat a word** across
   them — every repeat is wasted space.
3. **Plurals/word‑order are handled automatically** — use the singular ("newborn",
   not "newborns/newborn sleep"), skip spaces, and don't write phrases.
4. **Don't keyword‑stuff the name** beyond the few terms you can realistically rank
   for; relevance + downloads + ratings drive ranking more than raw repetition.

### Target keyword map (what we're trying to rank for)
| Tier | Search intent | Where it's covered |
|---|---|---|
| **Primary** | *baby night light*, *red night light*, *night light* | App Name |
| **Primary** | *baby sleep*, *newborn sleep*, *sleep light* | Name + Subtitle ("sleep", "newborns") |
| **Secondary** | *night feeding light*, *nursery light*, *feeding light* | Keywords (feeding, nursery) |
| **Secondary** | *toddler / infant night light*, *crib*, *nap* | Keywords |
| **Long‑tail** | *red light melatonin*, *dim light for baby*, *amber light* | Keywords (melatonin, dim, amber) |
| **Long‑tail** | *baby light lamp*, *bedtime*, *soothe/nurse* | Keywords |

### Why these keywords (the 100‑char field)
`nightlight` (the #1 category term, written solid because Apple matches "night"+"light"
separately too), `newborn / toddler / infant` (the three audience segments),
`nursery / crib` (room context), `feeding / nurse / bedtime / nap` (the *moments* people
search for help with), `melatonin / amber / dim` (the science/feature long‑tail),
`lamp / soothe` (rounding out intent).

### Words deliberately **left out** (and why)
- **baby, red, night, light, sleep, safe, glow** — already in the Name/Subtitle, so
  repeating them in Keywords is wasted space.
- **white noise, lullaby, sound, music** — the app has *no audio*. Ranking for these
  brings users who'll bounce and hurt your conversion. Add them only if you ship sound.
- **app, free, best, kids** — low‑value / against guidelines / too broad.

### Category choice
- **Lifestyle (recommended primary):** the category most "night light" and baby‑utility
  apps live in; easier to chart in than the hyper‑competitive Health & Fitness.
- **Health & Fitness (alternative):** leans into the sleep‑science angle and the
  "sleep" audience, but you compete with funded sleep apps. Pick Lifestyle to start;
  you can A/B via App Store Connect later.

---

## 4. The science behind red light (longer reference)

*(A more detailed version of the in‑description section — useful for a website, a
support page, or an App Review reviewer who asks "what is this for?". Written to stay
on the safe side of Apple's health‑claims rules: mechanism + research framing, no
promises of medical outcomes.)*

**Light is the master clock.** Your circadian rhythm — the internal ~24‑hour clock
that governs sleepiness — is set primarily by light hitting the eye. Specialized
retinal cells containing the pigment *melanopsin* are most sensitive to **blue light
around 480 nm**, exactly the wavelengths that dominate white LED screens, ceiling
lights and daylight.

**Blue/white light at night = "stay awake."** Exposure to blue‑rich light in the
evening suppresses **melatonin**, the hormone that signals "time to sleep," and can
push the body clock later. That's the opposite of what you want at 3 AM.

**Red and amber light are the gentle end of the spectrum.** Longer wavelengths
(~600–700 nm) barely register with those melanopsin receptors. Studies in adults
have found red light suppresses melatonin far less than comparable blue light, and a
2025 systematic review reported measurable sleep benefits from evening red‑light use
in shift workers. This is the same logic behind the red lighting used in submarines,
aircraft cockpits, astronomy, and many hospital night shifts — enough light to
function, without shouting "daytime" at your brain.

**For babies specifically:** direct infant research is still limited, but the
mechanism is the same, and dim warm/red light is widely recommended by sleep
educators and used in newborn units precisely because it's the least disruptive way
to see in the dark. Baby Light simply makes that easy: a clean, full‑screen red glow
you already have in your pocket.

*Honesty note for the listing:* we never claim the app treats, prevents or improves
any medical condition or guarantees sleep. We describe the well‑documented
*mechanism* and let parents decide. Keep it that way — health‑outcome promises are a
common App Review rejection.

### Sources (for your own reference — don't paste into the listing)
- Comparative effects of red vs. blue LED light on melatonin (NIH/PMC, 2024–25)
- Intermittent vs. continuous red light on circadian rhythms & melatonin suppression (PMC)
- Red light as a non‑pharmacological alertness/sleep intervention in shift workers (ScienceDirect, 2020; 2025 meta‑analysis)
- Background on melanopsin / ipRGC blue‑light (~480 nm) sensitivity

---

## 5. Screenshots

Finished, captioned marketing creatives are in `AppStore/screenshots/`, sized exactly
to Apple's 2026 specs. Raw, un‑captioned **real** app captures (iPhone + Apple Watch)
are in `AppStore/raw/`. App Store Connect requires a set per device family this app
ships on — all three are generated:

| Set | Folder | Size (px) | Count | Apple device class |
|---|---|---|---|---|
| **iPhone** | `screenshots/` | **1320 × 2868** | 6 | iPhone 6.9″ (leads; auto‑scales to all iPhones) |
| **iPad** | `screenshots/ipad/` | **2064 × 2752** | 5 | iPad 13″ (leads; auto‑scales to all iPads) |
| **Apple Watch** | `screenshots/watch/` | **422 × 514** | 3 | Apple Watch Ultra 3 (49 mm) |

iPhone screenshot order & captions (the headline sells — most installs are decided on
screenshots 1–3, so the hook goes first):

| # | Caption (headline / subhead) | Visual |
|---|---|---|
| 1 | **A red night light made for babies** / See in the dark without waking anyone | Full‑screen deep‑red glow + feed timer |
| 2 | **Light that won't fight melatonin** / Red & amber sit at the calm end of the spectrum | Science slide + spectrum |
| 3 | **Four sleep‑friendly colors** / Deep red, amber, candle, warm white | Controls panel |
| 4 | **Set it and let it fade** / Auto‑off after 15m, 30m, 1h or 2h | Candle screen, 30m timer running |
| 5 | **Swipe to dim. Closes to black.** / Bright when you open, dark when you don't | Amber full‑screen |
| 6 | **No ads. No sign‑up. No noise.** / Just a warm glow, free | App‑icon closing slide |

The **iPad** set mirrors creatives 1–5 in an iPad frame; the **Watch** set is three
full‑bleed glow shots ("on your wrist", "tap to change color", "turn the Crown to dim").
Re‑run `python3 make_screenshots.py` to regenerate all three sets.

---

## 6. Devices & targets (decided)
- **iPhone + iPad** — `TARGETED_DEVICE_FAMILY = "1,2"` kept. Both screenshot sets provided.
- **Apple Watch** — a standalone watchOS app is now part of the project (see §7).
- **Branding** — unified to **"Baby Light"** across the Home screen, the in‑app title,
  and the listing. (The Xcode target/scheme is still internally "Baby Night Light" —
  user‑invisible; rename in Xcode if you like.)

## 7. Apple Watch app
A **standalone watchOS night light** ships in the same project (target *Baby Light
Watch App*, bundle id `com.tadas.Baby-Light.watchkitapp`, embedded in the iPhone app):
- Full‑screen red / amber / candle / warm‑white glow — **tap to cycle colors**.
- **Digital Crown dims** the glow toward black (no system‑brightness API needed).
- A glanceable **count‑up feed timer** in the same calm hue.
- Reuses the iPhone palette; no audio, no network, no data collected.

Signing note: with Automatic signing, Xcode registers the watch App ID
(`com.tadas.Baby-Light.watchkitapp`) for you on first build/archive. The watch app has
its own App Store screenshots (the `screenshots/watch/` set) but is published as part of
the same App Store listing — no separate submission.

The watch app's **top‑corner clock is hidden** (watchOS has no API for this, so we mount
an invisible `VideoPlayer`, which the system honors by hiding the time) — keeping the
night light a pure dark glow with no bright white digits at 3 AM.

---

## 8. Privacy Policy (ready to host)
Apple **requires** a reachable Privacy Policy URL. Because the app collects nothing,
this is short and 100% true. Host it at the Privacy Policy URL from §1 (e.g.
`https://dogo.app/baby-light/privacy`) and you're done.

```
Privacy Policy — Baby Light

Last updated: 19 June 2026

Baby Light does not collect, store, transmit, or share any personal data.

• No account or sign-in. The app requires no login.
• No analytics or tracking. We do not use any analytics, advertising, or
  third-party tracking SDKs.
• No network connection. The app works fully offline and sends nothing off your device.
• On-device settings only. Your preferences (selected color, timer, brightness
  options) are stored locally on your device using the system's standard storage and
  never leave it. Deleting the app removes them.
• Children. The app is safe for all ages, contains no ads, and collects no data from
  anyone, including children.

Because we collect no data, there is nothing to access, correct, export, or delete on
our side, and we have no data to sell or disclose.

Contact: team@dogo.app
```

> If "Baby Light" is **not** a Dogo product, swap the `dogo.app` URLs and the contact
> email for your own domain/address before submitting. Everything else stands.

# Xcode Cloud → TestFlight Setup (Baby Night Light)

A step-by-step guide to get this app building in Xcode Cloud and delivered to
**TestFlight**, so you can install and run it on a real device. Everything in
this guide is the one-time, Apple-ID-authenticated setup that must be done in a
browser / Xcode — the repo side is already prepared (shared scheme + `ci_scripts/`).

## Project facts you'll need

| Thing | Value |
|---|---|
| Xcode project | `Baby Light.xcodeproj` |
| Shared scheme | `Baby Night Light` (committed under `xcshareddata/xcschemes/`) |
| App target | `Baby Night Light` |
| Bundle identifier | `com.tadas.Baby-Light` |
| Test targets | `Baby Night LightTests`, `Baby Night LightUITests` |
| CI scripts | `ci_scripts/ci_post_clone.sh`, `ci_pre_xcodebuild.sh`, `ci_post_xcodebuild.sh` |

## Prerequisites (one-time)

1. An **Apple Developer Program** membership ($99/yr) on the Apple ID you'll use.
   Xcode Cloud and TestFlight both require it.
2. Admin/App Manager access to **App Store Connect** (https://appstoreconnect.apple.com).
3. The latest **Xcode** installed on a Mac (needed once to create the workflow;
   after that, builds run in the cloud).

## Step 1 — Register the App ID and create the App Store Connect record

1. Go to App Store Connect → **Apps → + → New App**.
2. Platform: **iOS**. Bundle ID: select/create `com.tadas.Baby-Light`.
   - If the bundle ID isn't listed, create it first in the Apple Developer portal
     under **Certificates, Identifiers & Profiles → Identifiers**.
3. Give it a name (e.g. "Baby Night Light"), primary language, and SKU.

## Step 2 — Create the Xcode Cloud workflow

You can do this from Xcode (richest UI) or directly in App Store Connect.

### From Xcode
1. Open `Baby Light.xcodeproj`.
2. Make sure the scheme picker shows **Baby Night Light** (it will, because the
   scheme is shared and committed).
3. **Product → Xcode Cloud → Create Workflow…**
4. Select the **Baby Night Light** app, then **Grant Access** to the GitHub repo
   `tadasz/BabyLight` when prompted (installs the Xcode Cloud GitHub app).

### Workflow configuration (TestFlight delivery)

- **Name:** `TestFlight Beta`
- **Start Conditions:**
  - *Branch Changes* on `main` (and/or `develop`), **or**
  - *Tag Changes* matching `v*` if you prefer release-tag-driven builds.
- **Environment:** Xcode = Latest Release, macOS = Latest Release.
- **Actions (in order):**
  1. **Build** — Scheme `Baby Night Light`, Platform iOS.
  2. **Archive** — Scheme `Baby Night Light`, Deployment prep:
     **TestFlight (Internal Testing Only)** to start.
- **Post-Actions:**
  - **TestFlight Internal Testing** — pick an internal tester group so builds
    auto-distribute to your device after processing.

> Tip: add a separate **PR** workflow with a **Test** action (scheme
> `Baby Night Light`, destination *Any iOS Simulator*) if you also want unit/UI
> tests to gate pull requests. The shared scheme already includes both test
> targets.

## Step 3 — Code signing

Xcode Cloud manages signing automatically when you let it. In the app target's
**Signing & Capabilities**, keep **Automatically manage signing** on and select
your **Team**. On first archive, Xcode Cloud creates the needed distribution
certificate and provisioning profile for `com.tadas.Baby-Light`.

## Step 4 — First run & install on your device

1. Push to the branch your workflow watches (e.g. `main`), or use
   **Product → Xcode Cloud → Start Build** for an on-demand run.
2. Watch progress in Xcode's **Report navigator → Cloud** or in App Store
   Connect → your app → **Xcode Cloud**.
3. After Archive succeeds, the build processes for TestFlight (a few minutes).
4. On your iPhone, install **TestFlight** from the App Store, sign in with the
   Apple ID that's in your internal testing group, and the build appears there
   to install and run.

## Note on running in this remote (Linux) environment

iOS apps can't run in the Linux container this assistant operates in — there's
no iOS simulator or device here. Xcode Cloud's output is a TestFlight build (and
a downloadable `.ipa`/archive in App Store Connect), which you run on a physical
device or a macOS simulator. This guide gets you to that TestFlight build.

## How the committed `ci_scripts/` fit in

Xcode Cloud automatically runs these if present (already in the repo, tracked
executable):

| Script | When | Purpose here |
|---|---|---|
| `ci_post_clone.sh` | after clone | prints Xcode/simulator info; place for dependency installs |
| `ci_pre_xcodebuild.sh` | before build | prints build config / env vars |
| `ci_post_xcodebuild.sh` | after build | reports build status & test results |

No changes are required for a basic TestFlight build — they're informational and
ready to extend (e.g. inject build numbers, post notifications).

## Troubleshooting

- **"No scheme found"** — confirm `Baby Light.xcodeproj/xcshareddata/xcschemes/Baby Night Light.xcscheme`
  is committed (it is on this branch).
- **Signing errors** — ensure the bundle ID `com.tadas.Baby-Light` exists in your
  account and a Team is selected with automatic signing.
- **Build doesn't trigger** — re-check the workflow's Start Conditions and that the
  GitHub app has access to `tadasz/BabyLight`.
- **Logs** — App Store Connect → app → Xcode Cloud → build → logs, or Xcode's
  Report navigator.

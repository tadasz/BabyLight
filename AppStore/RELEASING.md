# Releasing Baby Light

End-to-end runbook for shipping a new App Store version. Read this first.
Related: [`ADD_A_LANGUAGE.md`](ADD_A_LANGUAGE.md), [`LOCALIZATION.md`](LOCALIZATION.md),
[`README.md`](README.md).

## TL;DR

```bash
# 0. one-time per machine: create the Python venv (see Prerequisites)
# 1. make your app/metadata changes on a branch, open a PR, merge to main
# 2. merging to main auto-triggers the Xcode Cloud "AppStore" build (a new build number)
# 3. once that build is VALID in App Store Connect:
cd AppStore
.venv/bin/python asc/stage_v11.py            # stage: create version, push listings + screenshots, attach build
# 4. review the listings in App Store Connect, then:
.venv/bin/python asc/stage_v11.py --submit   # submit for review
```

> Use `.venv/bin/python`, **not** `make stage`. The Makefile calls bare `python3`
> (Xcode's 3.9), which lacks the dependencies and will fail. The scripts'
> subprocesses inherit the venv automatically via `sys.executable`.

## Prerequisites

- **ASC API key** at `~/.appstoreconnect/private_keys/AuthKey_DX75UNTZ4U.p8`
  (key id `DX75UNTZ4U`, issuer `c6b880a6-2c8f-4304-ab18-8e05935d0cfe`). Never in the repo.
- **Python venv** (gitignored, create once):
  ```bash
  cd AppStore
  python3 -m venv .venv
  .venv/bin/pip install PyJWT requests cryptography Pillow arabic_reshaper python-bidi
  ```

## App facts

- App id `6758722102`, account "Dogo App GmbH", bundle `com.tadas.Baby-Light`.
- Xcode scheme **"Baby Night Light"**; deployment target iOS 26.2 (sim must be ≥ 26.2).
- Build = **Xcode Cloud**, Apple cloud-signing (no local certs). A push to `main`
  builds via the **AppStore** workflow (`8c13de8a-…`). Xcode Cloud stamps
  `CFBundleVersion` = the build-run number, so build numbers just increment.
- 16 in-app languages (English + 15). Adding a language: see `ADD_A_LANGUAGE.md`.

## App Review contact  (used by `stage_v11.py` → review detail)

- **Name:** Tadas Ziemys
- **Email:** tadas@dogo.app   *(note: differs from the ASC account email team@dogo.app)*
- **Phone:** +37065668005

## What `stage_v11.py` does (idempotent — safe to re-run)

1. Creates the next App Store version (`VERSION` constant — bump it per release).
2. Pushes localized metadata for every locale (`push_metadata.py`): name + subtitle
   (app-info level) and description/keywords/promo/whatsNew (version level).
3. Uploads the localized screenshot sets for all three device families
   (`upload_screenshots.py`): iPhone 6.5" `APP_IPHONE_65` (6), iPad 12.9"
   `APP_IPAD_PRO_3GEN_129` (5), Apple Watch Ultra `APP_WATCH_ULTRA` (3), reading
   `screenshots/loc/<asc>/`, `…/ipad/`, `…/watch/`. Idempotent: skips a device set
   that already has its full count. To refresh changed shots, re-run with
   `--replace` (deletes + re-uploads the set first); narrow with
   `--only <locales>` and/or `--device <DISPLAY_TYPE,…>`.
4. Attaches the highest VALID build on the version's train.
5. Sets the App Review contact + notes.
6. Leaves the version in **"Prepare for Submission"** (add `--submit` to submit).

## App Store Connect API gotchas (already handled in the scripts — don't re-introduce)

1. **Two appInfos once a version is live.** The `READY_FOR_SALE` one is locked
   (name/subtitle can't be edited); use the editable `PREPARE_FOR_SUBMISSION` one.
2. **Localizations auto-mirror.** Adding an `appInfoLocalization` for a language makes
   ASC auto-create the matching `appStoreVersionLocalization` (and vice-versa).
   Re-fetch the maps each iteration or POSTs 409 as duplicates.
3. **Build filters are rejected.** The app→builds and app→preReleaseVersions
   relationships reject `filter[preReleaseVersion.version]` / `filter[version]` /
   `filter[platform]` with 400. List `preReleaseVersions` unfiltered and match the
   train (`version`/`platform`) client-side. (Top-level `/v1/builds?filter[app]=…`
   does accept `sort`/`include`.)
4. **Review-detail field names** are `contactFirstName` / `contactLastName` /
   `contactEmail` / `contactPhone` — NOT first/last/email/phone.
5. **No emoji in store metadata.** ASC rejects emoji in description/etc. Keep the
   source + translations emoji-free (em-dashes and `•` bullets are fine).
6. **Privacy policy URL is per-locale and required for review.** Every
   `appInfoLocalization` must carry `privacyPolicyUrl` or the review submission is
   rejected with a `STATE_ERROR` on the version. `push_metadata.py` sets it
   (`PRIVACY_POLICY_URL`); don't drop it when adding locales.

## TestFlight (testing a build before submitting)

Xcode Cloud's **AppStore** workflow uploads App-Store-eligible builds to ASC, but
does **not** auto-add them to a TestFlight tester group — so a freshly built
number shows as "Ready to Submit" yet testers still see the last build that *was*
added. To put the latest build in front of internal testers, add it to the
internal group **"Baby Light Testers"** (`bfcd3d94-…`):

```bash
# find the latest build id, then link it to the group
.venv/bin/python asc/asc.py POST '/v1/betaGroups/bfcd3d94-4715-49d3-bce8-496c4ac11f03/relationships/builds' \
  @<(echo '{"data":[{"type":"builds","id":"<BUILD_ID>"}]}')
```

(Internal testing needs no Beta App Review.)

## Release history

- **1.0 (build 13)** — first release, **English only**. `READY_FOR_SALE` (live).
- **1.1 (build 18)** — first localized release: 16 languages + a much larger
  on-screen feed timer. Staged 2026-06-25; submit when ready. Builds 18 & 19 are
  interchangeable here (19 adds a per-language translation-QA polish pass:
  "Digital Crown" wording in Watch captions + minor grammar fixes).

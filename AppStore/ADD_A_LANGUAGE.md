# Adding a language to Baby Light

Everything localization-related is driven by **one registry**
(`i18n/locales.json`) plus the English source (`i18n/source.json`) and one
translation file per language (`i18n/translations/<asc>.json`). Add a language in
four steps; no script code changes are needed unless the language uses a writing
system we don't already render.

## 1. Scaffold it

```bash
cd AppStore
make add-locale ASC=sv XCODE=sv SCRIPT=latin NAME=Swedish
```

- `ASC` — the App Store Connect locale code (e.g. `sv`, `da`, `th`, `vi`, `id`,
  `hi`, `el`, `cs`, `uk`, `ro`, `hu`, `fi`, `he`, `ms`, `ca`, `pt-PT`, `fr-CA`,
  `en-GB`). This is also what the App Store listing uses.
- `XCODE` — the `.lproj` code baked into the app binary (usually the language
  without region: `sv`, `da`, `th`…). For region variants keep the region
  (`pt-BR`, `es-MX`, `zh-Hans`, `zh-Hant`).
- `SCRIPT` — picks screenshot fonts. Reuse an existing one when you can:
  `latin`, `cyrillic`, `cjk_sc`, `cjk_tc`, `ja`, `ko`, `ar`. A brand-new writing
  system (e.g. Thai, Hindi, Greek) needs a new `FONT_SETS[...]` entry in
  `i18n/screenshots.py` (font file + TTC face indices + `cjk`/`rtl` flags) — the
  scaffolder warns you when this is required.

This appends the locale to the registry and creates
`i18n/translations/<asc>.json` filled with **English placeholders**.

## 2. Translate

Edit `i18n/translations/<asc>.json`. Translate every value under `store`,
`captions`, and `ui`, following these rules (the same ones the App Store enforces):

| field | limit | notes |
|---|---|---|
| `store.name` | ≤ 30 | keep the brand **"Baby Light"**; localize the descriptor; no emoji |
| `store.subtitle` | ≤ 30 | adds value, doesn't repeat the name; no emoji |
| `store.promotionalText` | ≤ 170 | updatable any time |
| `store.keywords` | ≤ 100 | comma-separated, **no spaces**, singular, no words already in name/subtitle |
| `store.description` | ≤ 4000 | keep the emoji section markers + `•` bullets; no medical claims |
| `store.whatsNew` | ≤ 4000 | keep the `•` bullets |
| `captions[6]` | short | screenshot headline/subhead pairs |
| `ui.*` | short | in-app strings; keep `%@` in `ax_light_bg` and `•` in `hint*` |

> Tip: this is a great job for Claude — "translate `i18n/source.json` into `<asc>`
> following `ADD_A_LANGUAGE.md`'s limits, write `i18n/translations/<asc>.json`."

## 3. Build the assets

```bash
make all        # validate (char limits) + regenerate String Catalogs + render screenshots
```

`make validate` fails loudly if any field is over the limit or a key is missing.
The new language now ships **in the app binary** (String Catalog) and has a
localized screenshot set under `screenshots/loc/<asc>/`.

## 4. Ship it

- Build via Xcode Cloud: `make build` (App Store) — see `LOCALIZATION.md`.
- Push the listing + screenshots to App Store Connect: `make stage`
  (it creates the next version, pushes every locale that has a translation, and
  attaches the latest build). Add `make submit` to also submit for review.

That's it — adding the language touched **one registry line + one translation
file**; every generator and the ASC push picked it up automatically.

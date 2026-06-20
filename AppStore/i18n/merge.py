#!/usr/bin/env python3
"""Merge the 3 translation agent outputs (+ English source) into one canonical
translations.json keyed by App Store Connect locale code, and validate Apple's
character limits. Prints a report and exits non-zero if any HARD limit is broken.
"""
import json, os, sys

HERE = os.path.dirname(__file__)

# App Store Connect locale -> Xcode (.lproj) locale
ASC_TO_XCODE = {
    "zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant", "ja": "ja", "ko": "ko", "ru": "ru",
    "de-DE": "de", "fr-FR": "fr", "es-ES": "es", "es-MX": "es-MX", "it": "it",
    "pt-BR": "pt-BR", "nl-NL": "nl", "tr": "tr", "pl": "pl", "ar-SA": "ar",
}
TARGET_LOCALES = list(ASC_TO_XCODE.keys())

LIMITS = {"name": 30, "subtitle": 30, "promotionalText": 170, "keywords": 100,
          "description": 4000, "whatsNew": 4000}


def load(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def main():
    en = load(os.path.join(HERE, "en_source.json"))
    merged = {"en-US": {"store": dict(en["store"]), "captions": en["captions"], "ui": en["ui"]}}
    # English store needs description etc. already present; name/subtitle from store.
    for part in ("tr_A.json", "tr_B.json", "tr_C.json"):
        path = os.path.join("/tmp", part)
        if not os.path.exists(path):
            print(f"!! missing {path}", file=sys.stderr)
            continue
        d = load(path)
        for loc, payload in d.items():
            merged[loc] = payload

    problems = []
    print(f"{'locale':9} {'name':>4} {'sub':>4} {'promo':>5} {'kw':>4} {'desc':>5} {'new':>5}")
    for loc in ["en-US"] + TARGET_LOCALES:
        if loc not in merged:
            problems.append(f"{loc}: MISSING ENTIRELY")
            continue
        s = merged[loc]["store"]
        row = []
        for field in ("name", "subtitle", "promotionalText", "keywords", "description", "whatsNew"):
            v = s.get(field, "")
            n = len(v)
            row.append(n)
            if n > LIMITS[field]:
                problems.append(f"{loc}.{field}: {n} > {LIMITS[field]}")
            if field == "keywords" and ", " in v:
                problems.append(f"{loc}.keywords: contains a space after comma")
        # captions / ui completeness
        if len(merged[loc].get("captions", [])) != 6:
            problems.append(f"{loc}: captions != 6")
        missing_ui = [k for k in en["ui"] if k not in merged[loc].get("ui", {})]
        if missing_ui:
            problems.append(f"{loc}: missing ui keys {missing_ui}")
        if "%@" not in merged[loc].get("ui", {}).get("ax_light_bg", ""):
            problems.append(f"{loc}: ax_light_bg lost %@ placeholder")
        print(f"{loc:9} " + " ".join(f"{x:>4}" if i == 0 else f"{x:>5}" for i, x in
              [(0, row[0]), (0, row[1]), (1, row[2]), (0, row[3]), (1, row[4]), (1, row[5])]))

    out = os.path.join(HERE, "translations.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)
    print(f"\nwrote {out} with {len(merged)} locales")
    if problems:
        print("\nPROBLEMS:")
        for p in problems:
            print("  -", p)
        sys.exit(1)
    print("\nAll within Apple limits.")


if __name__ == "__main__":
    main()

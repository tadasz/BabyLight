#!/usr/bin/env python3
"""Scaffold a new language: add it to the registry and create a translation stub.

    python3 scaffold_locale.py <asc> <xcode> <script> "<Display Name>"
    e.g. python3 scaffold_locale.py sv sv latin "Swedish"
         python3 scaffold_locale.py th th thai "Thai"

- Appends the locale to locales.json (if absent).
- Creates translations/<asc>.json as a copy of source.json (English placeholders)
  so the pipeline runs immediately; translate that file next.
- Warns if 'script' is new (you must add a FONT_SETS entry in screenshots.py).

ASC locale codes: https://developer.apple.com/help (App Store localizations).
Xcode code is the .lproj name (often the language without region, e.g. de/fr/es).
"""
import json
import os
import sys

import lib

KNOWN_SCRIPTS = {"latin", "cyrillic", "cjk_sc", "cjk_tc", "ja", "ko", "ar"}


def main():
    if len(sys.argv) != 5:
        print(__doc__); sys.exit(1)
    asc, xcode, script, name = sys.argv[1:5]

    reg = lib.load_registry()
    if any(l["asc"] == asc for l in reg["locales"]) or reg["base"]["asc"] == asc:
        print(f"{asc} already in registry.")
    else:
        reg["locales"].append({"asc": asc, "xcode": xcode, "script": script, "name": name})
        with open(lib.REGISTRY_PATH, "w", encoding="utf-8") as f:
            json.dump(reg, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"added {asc} ({name}) to locales.json")

    if not lib.has_translation(asc):
        src = lib.load_source()
        stub = {"store": dict(src["store"]), "captions": src["captions"], "ui": dict(src["ui"])}
        os.makedirs(lib.TRANSLATIONS_DIR, exist_ok=True)
        with open(lib.translation_path(asc), "w", encoding="utf-8") as f:
            json.dump(stub, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"created translations/{asc}.json (English placeholders — TRANSLATE IT NEXT)")
    else:
        print(f"translations/{asc}.json already exists")

    if script not in KNOWN_SCRIPTS:
        print(f"\n⚠️  '{script}' is a NEW script — add a FONT_SETS['{script}'] entry in "
              f"i18n/screenshots.py (font file + face indices + cjk/rtl flags).")
    print("\nNext: translate translations/%s.json, then `make -C .. all`." % asc)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Shared localization library for Baby Light.

ONE source of truth: i18n/locales.json (the registry) + i18n/source.json (English)
+ i18n/translations/<asc>.json (one file per locale). Every other script — catalog
generation, screenshots, and the App Store Connect push — reads through here, so
adding a language is: edit locales.json, add translations/<asc>.json, re-run.

Importable from sibling dirs (e.g. AppStore/asc/) via:
    import sys, os; sys.path.insert(0, "<...>/AppStore/i18n"); import lib
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
REGISTRY_PATH = os.path.join(HERE, "locales.json")
SOURCE_PATH = os.path.join(HERE, "source.json")
TRANSLATIONS_DIR = os.path.join(HERE, "translations")

# Apple App Store Connect hard limits (characters).
LIMITS = {"name": 30, "subtitle": 30, "promotionalText": 170,
          "keywords": 100, "description": 4000, "whatsNew": 4000}


def load_registry():
    with open(REGISTRY_PATH, encoding="utf-8") as f:
        return json.load(f)


def base_entry():
    return load_registry()["base"]


def entries(include_base=False):
    """Registry entries (dicts with asc/xcode/script/name)."""
    reg = load_registry()
    out = [reg["base"]] if include_base else []
    return out + list(reg["locales"])


def target_locales():
    """ASC locale codes for the translated languages (excludes base)."""
    return [e["asc"] for e in entries()]


def all_locales():
    """ASC locale codes including the base language."""
    return [e["asc"] for e in entries(include_base=True)]


def _by_asc():
    return {e["asc"]: e for e in entries(include_base=True)}


def entry(asc):
    return _by_asc()[asc]


def asc_to_xcode(asc):
    return entry(asc)["xcode"]


def script_for(asc):
    return entry(asc)["script"]


def load_source():
    with open(SOURCE_PATH, encoding="utf-8") as f:
        return json.load(f)


def translation_path(asc):
    return os.path.join(TRANSLATIONS_DIR, f"{asc}.json")


def load_translation(asc):
    with open(translation_path(asc), encoding="utf-8") as f:
        return json.load(f)


def has_translation(asc):
    return os.path.exists(translation_path(asc))


def load_all(include_base=True):
    """{asc: payload} for every registry locale that has a translation file."""
    out = {}
    for asc in (all_locales() if include_base else target_locales()):
        if has_translation(asc):
            out[asc] = load_translation(asc)
    return out


def missing_translations():
    """Registry locales (incl. base) that have no translations/<asc>.json yet."""
    return [a for a in all_locales() if not has_translation(a)]


def validate():
    """Return (ok, problems[]). Checks completeness + Apple char limits."""
    src = load_source()
    problems = []
    miss = missing_translations()
    for a in miss:
        problems.append(f"{a}: no translations/{a}.json")
    src_ui = set(src["ui"].keys())
    for asc in all_locales():
        if not has_translation(asc):
            continue
        t = load_translation(asc)
        store = t.get("store", {})
        for field, limit in LIMITS.items():
            v = store.get(field, "")
            if not v:
                problems.append(f"{asc}.store.{field}: empty")
            elif len(v) > limit:
                problems.append(f"{asc}.store.{field}: {len(v)} > {limit}")
        if ", " in store.get("keywords", ""):
            problems.append(f"{asc}.keywords: space after comma")
        if len(t.get("captions", [])) != 6:
            problems.append(f"{asc}: captions != 6")
        missing_ui = src_ui - set(t.get("ui", {}).keys())
        if missing_ui:
            problems.append(f"{asc}: missing ui keys {sorted(missing_ui)}")
        if "%@" not in t.get("ui", {}).get("ax_light_bg", ""):
            problems.append(f"{asc}: ax_light_bg lost %@ placeholder")
    return (len(problems) == 0, problems)


if __name__ == "__main__":
    ok, probs = validate()
    reg = load_registry()
    print(f"registry: base {reg['base']['asc']} + {len(reg['locales'])} locales")
    print(f"translations present: {len(load_all())}/{len(all_locales())}")
    if probs:
        print("\nPROBLEMS:")
        for p in probs:
            print("  -", p)
    print("\nOK" if ok else "\nFAILED")

#!/usr/bin/env python3
"""Generate the iOS and watchOS String Catalogs (.xcstrings) from the registry.

Reads i18n/locales.json + i18n/translations/<asc>.json (via lib) and writes:
  Baby Light/Localizable.xcstrings            (full UI)
  Baby Light Watch App/Localizable.xcstrings  (the 4 color names)

The .xcstrings keys are the exact English source strings used in the Swift code,
so SwiftUI's LocalizedStringKey lookups resolve them at runtime.
"""
import json
import os
import lib

# English source string (the key in code)  ->  ui-dict key
IOS_KEYS = {
    "LIGHT COLOR": "light_color",
    "AUTO-OFF TIMER": "auto_off_timer",
    "AUTO BRIGHTNESS": "auto_brightness",
    "Max brightness when opened": "max_bright_open",
    "Dim to minimum when closed": "dim_close",
    "ELAPSED TIMER": "elapsed_timer",
    "Brightness": "brightness",
    "Double-tap to hide • Swipe to adjust brightness": "hint",
    "Hide the controls": "tip_hide_title",
    "Double-tap anywhere to hide these controls and dim the screen to a calm night light.": "tip_hide_msg",
    "Tap to show controls": "tip_show_title",
    "Double-tap anywhere to show the controls again. Swipe up or down to adjust the brightness.": "tip_show_msg",
    "Deep Red": "color_deep_red",
    "Amber": "color_amber",
    "Candle": "color_candle",
    "Warm White": "color_warm_white",
    "Best for sleep": "desc_best_sleep",
    "Warm & soothing": "desc_warm_soothing",
    "Soft orange": "desc_soft_orange",
    "If you need more light": "desc_more_light",
    "Elapsed time": "ax_elapsed_time",
    "Light background color: %@": "ax_light_bg",
    "Elapsed timer brightness": "ax_timer_brightness",
    "DEEP SLEEP TIP": "deep_sleep_tip",
    "Glow when baby may be deeply asleep": "sleep_tip_toggle",
    "Baby's birthday": "birthday",
    "Glow earlier or later": "glow_offset",
    "A gentle glow suggests a good moment to try the put-down.": "sleep_tip_hint",
    "Glows about %lld min after you open the app — the typical time to reach deep sleep at this age.": "sleep_tip_window",
    "Tap the glow to dismiss • Hold the light to restart timing": "sleep_tip_gestures",
}
WATCH_KEYS = {
    "Deep Red": "color_deep_red",
    "Amber": "color_amber",
    "Candle": "color_candle",
    "Warm White": "color_warm_white",
}


def entry(value_by_xcode):
    locs = {xc: {"stringUnit": {"state": "translated", "value": v}}
            for xc, v in value_by_xcode.items() if v}
    return {"extractionState": "manual", "localizations": locs}


def catalog(key_map):
    translations = lib.load_all(include_base=False)
    strings = {}
    for en_key, ui_key in key_map.items():
        vals = {}
        for asc, payload in translations.items():
            vals[lib.asc_to_xcode(asc)] = payload.get("ui", {}).get(ui_key, "")
        strings[en_key] = entry(vals)
    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}


def write(path, obj):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("wrote", os.path.relpath(path, lib.REPO))


if __name__ == "__main__":
    write(os.path.join(lib.REPO, "Baby Light", "Localizable.xcstrings"), catalog(IOS_KEYS))
    write(os.path.join(lib.REPO, "Baby Light Watch App", "Localizable.xcstrings"), catalog(WATCH_KEYS))
    print("done")

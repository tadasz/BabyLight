#!/usr/bin/env python3
"""Generate the iOS and watchOS String Catalogs (.xcstrings) from translations.json.

Writes:
  Baby Light/Localizable.xcstrings            (full UI)
  Baby Light Watch App/Localizable.xcstrings  (the 4 color names)

The .xcstrings keys are the exact English source strings used in the Swift code,
so SwiftUI's LocalizedStringKey lookups resolve them at runtime.
"""
import json, os

HERE = os.path.dirname(__file__)
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
TR = json.load(open(os.path.join(HERE, "translations.json"), encoding="utf-8"))

ASC_TO_XCODE = {
    "zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant", "ja": "ja", "ko": "ko", "ru": "ru",
    "de-DE": "de", "fr-FR": "fr", "es-ES": "es", "es-MX": "es-MX", "it": "it",
    "pt-BR": "pt-BR", "nl-NL": "nl", "tr": "tr", "pl": "pl", "ar-SA": "ar",
}

# English source key  ->  ui-dict key
KEY_MAP = {
    "LIGHT COLOR": "light_color",
    "AUTO-OFF TIMER": "auto_off_timer",
    "AUTO BRIGHTNESS": "auto_brightness",
    "Max brightness when opened": "max_bright_open",
    "Dim to minimum when closed": "dim_close",
    "ELAPSED TIMER": "elapsed_timer",
    "Brightness": "brightness",
    "Double-tap to hide • Swipe to adjust brightness": "hint",
    "Deep Red": "color_deep_red",
    "Amber": "color_amber",
    "Candle": "color_candle",
    "Wheat": "color_wheat",
    "Best for sleep": "desc_best_sleep",
    "Warm & soothing": "desc_warm_soothing",
    "Soft orange": "desc_soft_orange",
    "If you need more light": "desc_more_light",
    "Elapsed time": "ax_elapsed_time",
    "Light background color: %@": "ax_light_bg",
    "Elapsed timer brightness": "ax_timer_brightness",
}

# "Warm White" only appears on the watch; translate the 4th color name directly.
WARM_WHITE = {
    "de": "Warmweiß", "fr": "Blanc chaud", "es": "Blanco cálido", "es-MX": "Blanco cálido",
    "it": "Bianco caldo", "ja": "暖かい白", "ko": "따뜻한 화이트", "ru": "Тёплый белый",
    "nl": "Warm wit", "pl": "Ciepła biel", "tr": "Sıcak beyaz", "pt-BR": "Branco quente",
    "ar": "أبيض دافئ", "zh-Hans": "暖白", "zh-Hant": "暖白",
}


def entry(value_by_xcode):
    locs = {}
    for xc, val in value_by_xcode.items():
        if val:
            locs[xc] = {"stringUnit": {"state": "translated", "value": val}}
    return {"extractionState": "manual", "localizations": locs}


def build_ios():
    strings = {}
    for en_key, ui_key in KEY_MAP.items():
        vals = {}
        for asc, payload in TR.items():
            if asc == "en-US":
                continue
            xc = ASC_TO_XCODE[asc]
            vals[xc] = payload.get("ui", {}).get(ui_key, "")
        strings[en_key] = entry(vals)
    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}


def build_watch():
    name_keys = {"Deep Red": "color_deep_red", "Amber": "color_amber", "Candle": "color_candle"}
    strings = {}
    for en_key, ui_key in name_keys.items():
        vals = {ASC_TO_XCODE[a]: TR[a]["ui"].get(ui_key, "") for a in TR if a != "en-US"}
        strings[en_key] = entry(vals)
    strings["Warm White"] = entry(dict(WARM_WHITE))
    return {"sourceLanguage": "en", "strings": strings, "version": "1.0"}


def write(path, obj):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("wrote", path)


write(os.path.join(REPO, "Baby Light", "Localizable.xcstrings"), build_ios())
write(os.path.join(REPO, "Baby Light Watch App", "Localizable.xcstrings"), build_watch())
print("done")

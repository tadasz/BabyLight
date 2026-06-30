#!/usr/bin/env python3
"""Upload localized iPhone 6.5" screenshots to App Store Connect (registry-driven).

For each target locale (i18n/locales.json) it creates an APP_IPHONE_65 screenshot
set (if absent) and uploads the 6 PNGs from AppStore/screenshots/loc/<asc>/, then
commits each asset and sets the display order.

Usage:
  python3 upload_screenshots.py --version-id <id> [--only de-DE,fr-FR] [--replace]
"""
import argparse
import hashlib
import os
import sys

import requests

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "i18n"))
import lib  # noqa: E402
from asc import ASC  # noqa: E402

SHOTS = os.path.join(lib.REPO, "AppStore", "screenshots", "loc")

# Each device set: ASC display type, the subdir under screenshots/loc/<asc>/, and
# the ordered filenames. iPhone lives at the locale root; iPad/Watch in subdirs.
DEVICES = [
    {"type": "APP_IPHONE_65", "subdir": "",
     "order": ["01_hero_red.png", "02_science.png", "03_colors.png",
               "04_timer.png", "05_brightness.png", "06_closing.png"]},
    {"type": "APP_IPAD_PRO_3GEN_129", "subdir": "ipad",
     "order": ["01_hero_red.png", "02_colors.png", "03_timer.png",
               "04_brightness.png", "05_closing.png"]},
    {"type": "APP_WATCH_ULTRA", "subdir": "watch",
     "order": ["01_red.png", "02_amber.png", "03_candle.png"]},
]


def upload_one(c, set_id, path):
    data = open(path, "rb").read()
    r = c.post("/v1/appScreenshots",
               {"data": {"type": "appScreenshots",
                         "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
                         "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})
    sid = r["data"]["id"]
    for op in r["data"]["attributes"]["uploadOperations"]:
        headers = {h["name"]: h["value"] for h in (op.get("requestHeaders") or [])}
        chunk = data[op["offset"]:op["offset"] + op["length"]]
        requests.request(op["method"], op["url"], headers=headers, data=chunk, timeout=120).raise_for_status()
    c.patch(f"/v1/appScreenshots/{sid}",
            {"data": {"type": "appScreenshots", "id": sid,
                      "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    return sid


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--version-id", required=True)
    ap.add_argument("--only", default="")
    ap.add_argument("--device", default="", help="comma list of display types to limit to (default: all)")
    ap.add_argument("--replace", action="store_true", help="delete existing set first")
    args = ap.parse_args()
    c = ASC()
    only = set(x for x in args.only.split(",") if x)
    devs = set(x for x in args.device.split(",") if x)
    locales = [l for l in lib.store_locales(include_base=False) if (not only or l in only)]

    ver_locs = {x["attributes"]["locale"]: x["id"] for x in
                c.get_all(f"/v1/appStoreVersions/{args.version_id}/appStoreVersionLocalizations")}

    for loc in locales:
        if loc not in ver_locs:
            print(f"  !! {loc}: no version localization yet (run push_metadata first)"); continue
        locdir = os.path.join(SHOTS, loc)
        if not os.path.isdir(locdir):
            print(f"  !! {loc}: no screenshots dir"); continue
        vl = ver_locs[loc]
        sets = c.get_all(f"/v1/appStoreVersionLocalizations/{vl}/appScreenshotSets")
        for dev in DEVICES:
            if devs and dev["type"] not in devs:
                continue
            srcdir = os.path.join(locdir, dev["subdir"]) if dev["subdir"] else locdir
            order = dev["order"]
            if not all(os.path.isfile(os.path.join(srcdir, fn)) for fn in order):
                print(f"  !! {loc}/{dev['type']}: missing images, skipping"); continue
            existing = [s for s in sets if s["attributes"]["screenshotDisplayType"] == dev["type"]]
            if existing and args.replace:
                for s in existing:
                    c.delete(f"/v1/appScreenshotSets/{s['id']}")
                existing = []
            if existing:
                sc = c.get_all(f"/v1/appScreenshotSets/{existing[0]['id']}/appScreenshots")
                if len(sc) >= len(order):
                    print(f"  -- {loc}/{dev['type']}: already has {len(sc)}, skipping"); continue
                set_id = existing[0]["id"]
            else:
                r = c.post("/v1/appScreenshotSets",
                           {"data": {"type": "appScreenshotSets",
                                     "attributes": {"screenshotDisplayType": dev["type"]},
                                     "relationships": {"appStoreVersionLocalization":
                                         {"data": {"type": "appStoreVersionLocalizations", "id": vl}}}}})
                set_id = r["data"]["id"]
            ids = [upload_one(c, set_id, os.path.join(srcdir, fn)) for fn in order]
            c.patch(f"/v1/appScreenshotSets/{set_id}/relationships/appScreenshots",
                    {"data": [{"type": "appScreenshots", "id": i} for i in ids]})
            print(f"  == {loc}/{dev['type']}: {len(ids)} uploaded + ordered")
    print("\nDone.")


if __name__ == "__main__":
    main()

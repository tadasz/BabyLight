#!/usr/bin/env python3
"""Push localized metadata to App Store Connect (registry-driven).

Creates/updates, for every locale in i18n/locales.json that has a translation:
  - appInfoLocalizations          (name, subtitle)
  - appStoreVersionLocalizations  (description, keywords, promotionalText,
                                   whatsNew, marketingUrl, supportUrl)

Usage:
  python3 push_metadata.py --version-id <id> --appinfo-id <id> \
                           [--skip-whatsnew] [--only de-DE,fr-FR]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "i18n"))
import lib  # noqa: E402
from asc import ASC  # noqa: E402

MARKETING_URL = "https://dogo.app"
SUPPORT_URL = "https://dogo.app"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--version-id", required=True)
    ap.add_argument("--appinfo-id", required=True)
    ap.add_argument("--skip-whatsnew", action="store_true")
    ap.add_argument("--only", default="")
    args = ap.parse_args()
    c = ASC()

    only = set(x for x in args.only.split(",") if x)
    locales = [l for l in lib.all_locales() if lib.has_translation(l) and (not only or l in only)]

    for loc in locales:
        store = lib.load_translation(loc)["store"]
        # Re-fetch the localization maps each iteration: adding an
        # appInfoLocalization for a new language makes ASC auto-create the
        # matching appStoreVersionLocalization (and vice-versa), so a map
        # cached once at the start goes stale and POSTs would 409 as duplicates.
        info_locs = {x["attributes"]["locale"]: x["id"] for x in
                     c.get_all(f"/v1/appInfos/{args.appinfo_id}/appInfoLocalizations")}
        info_attrs = {"name": store["name"], "subtitle": store["subtitle"]}
        if loc in info_locs:
            c.patch(f"/v1/appInfoLocalizations/{info_locs[loc]}",
                    {"data": {"type": "appInfoLocalizations", "id": info_locs[loc], "attributes": info_attrs}})
            print(f"  [info ] PATCH {loc}")
        else:
            r = c.post("/v1/appInfoLocalizations",
                       {"data": {"type": "appInfoLocalizations", "attributes": {"locale": loc, **info_attrs},
                                 "relationships": {"appInfo": {"data": {"type": "appInfos", "id": args.appinfo_id}}}}})
            info_locs[loc] = r["data"]["id"]
            print(f"  [info ] POST  {loc}")

        # Fetch version localizations *after* the appInfo upsert above: adding
        # an appInfoLocalization makes ASC auto-create the matching version
        # localization, so this must be read fresh here to PATCH (not POST) it.
        ver_locs = {x["attributes"]["locale"]: x["id"] for x in
                    c.get_all(f"/v1/appStoreVersions/{args.version_id}/appStoreVersionLocalizations")}
        ver_attrs = {"description": store["description"], "keywords": store["keywords"],
                     "promotionalText": store["promotionalText"],
                     "marketingUrl": MARKETING_URL, "supportUrl": SUPPORT_URL}
        if not args.skip_whatsnew:
            ver_attrs["whatsNew"] = store["whatsNew"]
        if loc in ver_locs:
            c.patch(f"/v1/appStoreVersionLocalizations/{ver_locs[loc]}",
                    {"data": {"type": "appStoreVersionLocalizations", "id": ver_locs[loc], "attributes": ver_attrs}})
            print(f"  [ver  ] PATCH {loc}")
        else:
            r = c.post("/v1/appStoreVersionLocalizations",
                       {"data": {"type": "appStoreVersionLocalizations", "attributes": {"locale": loc, **ver_attrs},
                                 "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": args.version_id}}}}})
            ver_locs[loc] = r["data"]["id"]
            print(f"  [ver  ] POST  {loc}")

    print(f"\nDone: {len(locales)} locales.")


if __name__ == "__main__":
    main()

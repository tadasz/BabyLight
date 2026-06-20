#!/usr/bin/env python3
"""Push localized metadata to App Store Connect.

Creates/updates:
  - appInfoLocalizations          (name, subtitle)           under the appInfo
  - appStoreVersionLocalizations  (description, keywords,
                                   promotionalText, whatsNew,
                                   marketingUrl, supportUrl)  under the version

Usage:
  python3 push_metadata.py --version-id <appStoreVersionId> --appinfo-id <appInfoId> \
                           [--skip-whatsnew] [--only de-DE,fr-FR]
"""
import argparse, json, os, sys
from asc import ASC

HERE = os.path.dirname(__file__)
TR = json.load(open(os.path.join(HERE, "..", "i18n", "translations.json"), encoding="utf-8"))
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
    locales = [l for l in TR.keys() if (not only or l in only)]

    # existing localizations
    info_locs = {x["attributes"]["locale"]: x["id"] for x in
                 c.get_all(f"/v1/appInfos/{args.appinfo_id}/appInfoLocalizations")}
    ver_locs = {x["attributes"]["locale"]: x["id"] for x in
                c.get_all(f"/v1/appStoreVersions/{args.version_id}/appStoreVersionLocalizations")}

    for loc in locales:
        store = TR[loc]["store"]
        # ---- appInfoLocalization (name, subtitle) ----
        info_attrs = {"name": store["name"], "subtitle": store["subtitle"]}
        if loc in info_locs:
            c.patch(f"/v1/appInfoLocalizations/{info_locs[loc]}",
                    {"data": {"type": "appInfoLocalizations", "id": info_locs[loc],
                              "attributes": info_attrs}})
            print(f"  [info ] PATCH {loc}")
        else:
            body = {"data": {"type": "appInfoLocalizations",
                             "attributes": {"locale": loc, **info_attrs},
                             "relationships": {"appInfo": {"data": {"type": "appInfos", "id": args.appinfo_id}}}}}
            r = c.post("/v1/appInfoLocalizations", body)
            info_locs[loc] = r["data"]["id"]
            print(f"  [info ] POST  {loc}")

        # ---- appStoreVersionLocalization (description, keywords, ...) ----
        ver_attrs = {
            "description": store["description"],
            "keywords": store["keywords"],
            "promotionalText": store["promotionalText"],
            "marketingUrl": MARKETING_URL,
            "supportUrl": SUPPORT_URL,
        }
        if not args.skip_whatsnew:
            ver_attrs["whatsNew"] = store["whatsNew"]
        if loc in ver_locs:
            c.patch(f"/v1/appStoreVersionLocalizations/{ver_locs[loc]}",
                    {"data": {"type": "appStoreVersionLocalizations", "id": ver_locs[loc],
                              "attributes": ver_attrs}})
            print(f"  [ver  ] PATCH {loc}")
        else:
            body = {"data": {"type": "appStoreVersionLocalizations",
                             "attributes": {"locale": loc, **ver_attrs},
                             "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": args.version_id}}}}}
            r = c.post("/v1/appStoreVersionLocalizations", body)
            ver_locs[loc] = r["data"]["id"]
            print(f"  [ver  ] POST  {loc}")

    print(f"\nDone: {len(locales)} locales.")


if __name__ == "__main__":
    main()

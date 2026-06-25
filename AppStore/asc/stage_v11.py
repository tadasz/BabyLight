#!/usr/bin/env python3
"""One-shot: stage App Store version 1.1 fully localized.

Run this AFTER version 1.0 has been approved/released (Apple blocks creating a
new version while the first one is unreleased). It:
  1. creates appStoreVersion 1.1 (IOS)             [idempotent: reuses if present]
  2. pushes metadata for every registered locale  (push_metadata.py)
  3. uploads localized screenshots (upload_screenshots.py)
  4. attaches the processed 1.1 build
  5. sets App Review contact + notes
It does NOT submit for review — it leaves 1.1 in "Prepare for Submission" so you
can review the 16 listings and click Submit (or pass --submit).

Usage:
  python3 stage_v11.py [--submit]
"""
import argparse, subprocess, sys, os
from asc import ASC

HERE = os.path.dirname(os.path.abspath(__file__))
APP_ID = "6758722102"
VERSION = "1.1"
REVIEW_CONTACT = {"contactFirstName": "Tadas", "contactLastName": "Ziemys",
                  "contactEmail": "team@dogo.app", "contactPhone": "+37065668005"}
REVIEW_NOTES = ("Baby Light is a full-screen colored night-light utility for iPhone, iPad and "
                "Apple Watch. DOUBLE-TAP the screen to reveal controls (color, auto-off timer, "
                "auto-brightness). Swipe up/down to change brightness. Apple Watch: tap to cycle "
                "colors, turn the Digital Crown to dim. No login, no network, no data collection.")


def run(script, *args):
    cmd = [sys.executable, os.path.join(HERE, script), *args]
    print("  $", " ".join(cmd))
    r = subprocess.run(cmd, cwd=HERE)
    if r.returncode != 0:
        raise SystemExit(f"step failed: {script}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--submit", action="store_true")
    args = ap.parse_args()
    c = ASC()

    # 1. version 1.1
    vers = c.get_all(f"/v1/apps/{APP_ID}/appStoreVersions",
                     {"filter[versionString]": VERSION, "filter[platform]": "IOS"})
    if vers:
        vid = vers[0]["id"]
        print(f"version {VERSION} already exists: {vid}")
    else:
        try:
            r = c.post("/v1/appStoreVersions",
                       {"data": {"type": "appStoreVersions",
                                 "attributes": {"platform": "IOS", "versionString": VERSION},
                                 "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}})
            vid = r["data"]["id"]
            print(f"created version {VERSION}: {vid}")
        except RuntimeError as e:
            print("\nCANNOT CREATE 1.1 YET — version 1.0 is probably still unreleased.")
            print("Re-run this once 1.0 shows 'Ready for Sale' / approved.\n")
            print(e)
            raise SystemExit(2)

    # appInfo (editable). Once a version is live there are two appInfo records:
    # the READY_FOR_SALE one is locked (name/subtitle can't be edited), and a
    # separate PREPARE_FOR_SUBMISSION one is editable. Pick the editable one.
    infos = c.get_all(f"/v1/apps/{APP_ID}/appInfos")
    editable = [i for i in infos
                if i["attributes"].get("appStoreState") not in ("READY_FOR_SALE", "REPLACED_WITH_NEW_INFO")]
    appinfo = (editable or infos)[0]["id"]
    print(f"using appInfo {appinfo} (editable)" if editable else f"using appInfo {appinfo} (no editable found)")

    # 2. metadata + 3. screenshots
    print("\n== metadata ==");    run("push_metadata.py", "--version-id", vid, "--appinfo-id", appinfo)
    print("\n== screenshots =="); run("upload_screenshots.py", "--version-id", vid)

    # 4. attach the highest-numbered VALID build on the 1.1 train (the Xcode Cloud
    #    build, e.g. 1.1(15), over the earlier local stopgap 1.1(14)).
    # The app->builds relationship rejects filter[preReleaseVersion.version], and
    # the app->preReleaseVersions relationship rejects filter[version]/[platform];
    # so list the build trains unfiltered and match the 1.1/IOS one client-side.
    prv = [p for p in c.get_all(f"/v1/apps/{APP_ID}/preReleaseVersions")
           if p["attributes"].get("version") == VERSION
           and p["attributes"].get("platform") == "IOS"]
    builds = []
    if prv:
        builds = [b for b in c.get_all(f"/v1/preReleaseVersions/{prv[0]['id']}/builds")
                  if b["attributes"]["processingState"] == "VALID"]

    def buildnum(b):
        try:
            return int(b["attributes"].get("version") or 0)
        except ValueError:
            return 0

    if builds:
        best = max(builds, key=buildnum)
        c.patch(f"/v1/appStoreVersions/{vid}/relationships/build",
                {"data": {"type": "builds", "id": best["id"]}})
        print(f"\nattached build {VERSION}({best['attributes'].get('version')}) ({best['id']})")
    else:
        print(f"\n!! no VALID {VERSION} build yet — Xcode Cloud run pending; attach later.")

    # 5. review detail
    try:
        existing = c.get(f"/v1/appStoreVersions/{vid}/appStoreReviewDetail")
        rid = existing.get("data", {}).get("id")
    except Exception:
        rid = None
    attrs = {**REVIEW_CONTACT, "notes": REVIEW_NOTES}
    if rid:
        c.patch(f"/v1/appStoreReviewDetails/{rid}",
                {"data": {"type": "appStoreReviewDetails", "id": rid, "attributes": attrs}})
    else:
        c.post("/v1/appStoreReviewDetails",
               {"data": {"type": "appStoreReviewDetails", "attributes": attrs,
                         "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
    print("set App Review contact + notes")

    if args.submit:
        sub = c.post("/v1/reviewSubmissions",
                     {"data": {"type": "reviewSubmissions",
                               "attributes": {"platform": "IOS"},
                               "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}})
        subid = sub["data"]["id"]
        c.post("/v1/reviewSubmissionItems",
               {"data": {"type": "reviewSubmissionItems",
                         "relationships": {
                             "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": subid}},
                             "appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
        c.patch(f"/v1/reviewSubmissions/{subid}",
                {"data": {"type": "reviewSubmissions", "id": subid, "attributes": {"submitted": True}}})
        print("SUBMITTED v1.1 for review.")
    else:
        print("\nv1.1 staged in 'Prepare for Submission'. Review the 16 listings, then submit\n"
              "in App Store Connect, or re-run:  python3 stage_v11.py --submit")


if __name__ == "__main__":
    main()

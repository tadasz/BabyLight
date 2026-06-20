#!/usr/bin/env python3
"""Create (or reuse) IOS_APP_STORE provisioning profiles for the Baby Light app
and watch app via the ASC API, and install them locally so xcodebuild can use
manual App Store signing. Prints the profile names to use in ExportOptions.
"""
import base64, os, sys
from asc import ASC

APP_BUNDLE = ("N69RFNN8ZW", "com.tadas.Baby-Light", "BabyLight AppStore")
WATCH_BUNDLE = ("NRFM26WL4J", "com.tadas.Baby-Light.watchkitapp", "BabyLight Watch AppStore")
CERTS = ["QMVC2B9H76", "WF4CTZK6V8"]
PROFILE_DIR = os.path.expanduser("~/Library/MobileDevice/Provisioning Profiles")


def ensure(c, bundle_id, identifier, name):
    # reuse an existing active profile with our name if present
    existing = c.get_all("/v1/profiles",
                         {"filter[profileType]": "IOS_APP_STORE", "limit": 200})
    for p in existing:
        if p["attributes"]["name"] == name and p["attributes"]["profileState"] == "ACTIVE":
            full = c.get(f"/v1/profiles/{p['id']}",
                         {"fields[profiles]": "name,uuid,profileContent"})
            return install(full["data"])
    body = {"data": {"type": "profiles",
                     "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
                     "relationships": {
                         "bundleId": {"data": {"type": "bundleIds", "id": bundle_id}},
                         "certificates": {"data": [{"type": "certificates", "id": cid} for cid in CERTS]},
                     }}}
    r = c.post("/v1/profiles", body)
    return install(r["data"])


def install(data):
    name = data["attributes"]["name"]
    uuid = data["attributes"]["uuid"]
    content = data["attributes"]["profileContent"]
    os.makedirs(PROFILE_DIR, exist_ok=True)
    path = os.path.join(PROFILE_DIR, f"{uuid}.mobileprovision")
    with open(path, "wb") as f:
        f.write(base64.b64decode(content))
    print(f"  installed '{name}'  uuid={uuid}")
    return name


def main():
    c = ASC()
    app_name = ensure(c, *APP_BUNDLE)
    watch_name = ensure(c, *WATCH_BUNDLE)
    print("\nPROFILE_APP=" + app_name)
    print("PROFILE_WATCH=" + watch_name)


if __name__ == "__main__":
    main()

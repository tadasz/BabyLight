#!/usr/bin/env python3
"""Minimal App Store Connect API client for the Baby Light app.

Credentials are read from env with sane defaults:
  ASC_KEY_ID    (default DX75UNTZ4U)
  ASC_ISSUER_ID (default c6b880a6-2c8f-4304-ab18-8e05935d0cfe)
  ASC_KEY_PATH  (default ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8)

The .p8 private key is NEVER copied into the repo.

Usage as a library:
    from asc import ASC
    c = ASC()
    apps = c.get("/v1/apps")

Usage as a CLI (for quick inspection / scripted calls):
    python3 asc.py GET /v1/apps 'filter[bundleId]=com.tadas.Baby-Light'
    python3 asc.py GET /v1/apps/<id>/appStoreVersions
    python3 asc.py POST /v1/appStoreVersionLocalizations @body.json
    python3 asc.py PATCH /v1/appStoreVersionLocalizations/<id> @body.json
    python3 asc.py DELETE /v1/appScreenshots/<id>
"""
import json
import os
import sys
import time
import urllib.parse

import jwt
import requests

KEY_ID = os.environ.get("ASC_KEY_ID", "DX75UNTZ4U")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "c6b880a6-2c8f-4304-ab18-8e05935d0cfe")
KEY_PATH = os.environ.get(
    "ASC_KEY_PATH",
    os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8"),
)
BASE = "https://api.appstoreconnect.apple.com"


class ASC:
    def __init__(self):
        with open(KEY_PATH) as f:
            self._key = f.read()
        self._token = None
        self._token_exp = 0

    def token(self):
        now = time.time()
        if self._token and now < self._token_exp - 60:
            return self._token
        exp = now + 19 * 60
        self._token = jwt.encode(
            {"iss": ISSUER_ID, "exp": exp, "aud": "appstoreconnect-v1"},
            self._key,
            algorithm="ES256",
            headers={"kid": KEY_ID, "typ": "JWT"},
        )
        self._token_exp = exp
        return self._token

    def _headers(self, content_type="application/json"):
        h = {"Authorization": f"Bearer {self.token()}"}
        if content_type:
            h["Content-Type"] = content_type
        return h

    def request(self, method, path, params=None, body=None, raw=False):
        url = path if path.startswith("http") else BASE + path
        r = requests.request(
            method,
            url,
            headers=self._headers(),
            params=params,
            data=json.dumps(body) if body is not None else None,
            timeout=120,
        )
        if not r.ok:
            raise RuntimeError(
                f"{method} {path} -> {r.status_code}\n{r.text}"
            )
        if raw:
            return r
        if r.status_code == 204 or not r.text:
            return {}
        return r.json()

    def get(self, path, params=None):
        return self.request("GET", path, params=params)

    def get_all(self, path, params=None):
        """Follow pagination, returning the concatenated `data` list."""
        out = []
        params = dict(params or {})
        params.setdefault("limit", 200)
        url = path
        nxt_params = params
        while url:
            j = self.request("GET", url, params=nxt_params)
            out.extend(j.get("data", []))
            url = j.get("links", {}).get("next")
            nxt_params = None  # next link already encodes params
        return out

    def post(self, path, body):
        return self.request("POST", path, body=body)

    def patch(self, path, body):
        return self.request("PATCH", path, body=body)

    def delete(self, path):
        return self.request("DELETE", path, raw=True)


def _cli():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    method = sys.argv[1].upper()
    path = sys.argv[2]
    params = None
    body = None
    for arg in sys.argv[3:]:
        if arg.startswith("@"):
            with open(arg[1:]) as f:
                body = json.load(f)
        elif "=" in arg and not arg.startswith("{"):
            params = params or {}
            k, v = arg.split("=", 1)
            params[k] = v
        else:
            body = json.loads(arg)
    c = ASC()
    if method == "GETALL":
        print(json.dumps(c.get_all(path, params), indent=2, ensure_ascii=False))
        return
    r = c.request(method, path, params=params, body=body, raw=True)
    print(f"# {r.status_code}", file=sys.stderr)
    if r.text:
        try:
            print(json.dumps(r.json(), indent=2, ensure_ascii=False))
        except Exception:
            print(r.text)


if __name__ == "__main__":
    _cli()

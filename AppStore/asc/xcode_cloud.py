#!/usr/bin/env python3
"""Drive Xcode Cloud for Baby Light via the App Store Connect API.

Builds are produced by Xcode Cloud (Apple-managed cloud signing — no local certs).
The "AppStore" workflow (APP_STORE_ELIGIBLE archive) is pinned to branch `main`, so
to build any OTHER branch on demand this temporarily adds that branch to the
workflow's start condition, starts a manual run, then restores the condition.

Usage:
  python3 xcode_cloud.py trigger <branch> [--testflight]   # start a run, prints run id
  python3 xcode_cloud.py poll <runId>                       # watch a run to completion
  python3 xcode_cloud.py build-for <branch> [--testflight]  # trigger + poll + show build
"""
import argparse, json, sys, time
from asc import ASC

REPO = "ed14a636-e4e0-4cbe-9f7c-935b865fe8aa"
WF_APPSTORE = "8c13de8a-4820-498e-9368-b51b2f6b4b7c"   # APP_STORE_ELIGIBLE archive
WF_TESTFLIGHT = "5E27DB20-0BB8-4302-A64D-DC1640A97FC2"  # INTERNAL_ONLY archive
APP = "6758722102"


def gitref_for(c, branch, tries=20):
    for _ in range(tries):
        refs = c.get_all(f"/v1/scmRepositories/{REPO}/gitReferences", {"limit": 200})
        m = {r["attributes"].get("name"): r["id"] for r in refs}
        if branch in m:
            return m[branch]
        time.sleep(6)
    raise SystemExit(f"branch '{branch}' not synced from GitHub — did you push it?")


def trigger(c, branch, workflow=WF_APPSTORE, clean=True):
    ref = gitref_for(c, branch)
    cond = c.get(f"/v1/ciWorkflows/{workflow}")["data"]["attributes"]["branchStartCondition"]
    patterns = cond["source"]["patterns"]
    have = any(p["pattern"] == branch and not p["isPrefix"] for p in patterns)
    runid = None
    try:
        if not have:
            modified = json.loads(json.dumps(cond))
            modified["source"]["patterns"].append({"pattern": branch, "isPrefix": False})
            c.patch(f"/v1/ciWorkflows/{workflow}",
                    {"data": {"type": "ciWorkflows", "id": workflow,
                              "attributes": {"branchStartCondition": modified}}})
        body = {"data": {"type": "ciBuildRuns", "attributes": {"clean": clean},
                         "relationships": {
                             "workflow": {"data": {"type": "ciWorkflows", "id": workflow}},
                             "sourceBranchOrTag": {"data": {"type": "scmGitReferences", "id": ref}}}}}
        r = c.post("/v1/ciBuildRuns", body)
        runid = r["data"]["id"]
        print(f"started run {r['data']['attributes'].get('number')} id={runid} "
              f"progress={r['data']['attributes'].get('executionProgress')}")
    finally:
        if not have:
            c.patch(f"/v1/ciWorkflows/{workflow}",
                    {"data": {"type": "ciWorkflows", "id": workflow,
                              "attributes": {"branchStartCondition": cond}}})
            print("restored workflow start condition")
    return runid


def poll(c, runid, minutes=45):
    last = None
    for _ in range(minutes * 60 // 40):
        a = c.get(f"/v1/ciBuildRuns/{runid}")["data"]["attributes"]
        key = (a.get("executionProgress"), a.get("completionStatus"))
        if key != last:
            print(time.strftime("%H:%M:%S"), key, flush=True); last = key
        if a.get("executionProgress") == "COMPLETE":
            return a.get("completionStatus")
        time.sleep(40)
    return "TIMEOUT"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("cmd", choices=["trigger", "poll", "build-for"])
    ap.add_argument("arg")
    ap.add_argument("--testflight", action="store_true")
    args = ap.parse_args()
    c = ASC()
    wf = WF_TESTFLIGHT if args.testflight else WF_APPSTORE
    if args.cmd == "poll":
        print("completion:", poll(c, args.arg))
    elif args.cmd == "trigger":
        trigger(c, args.arg, wf)
    else:
        rid = trigger(c, args.arg, wf)
        if rid:
            print("completion:", poll(c, rid))
            bs = c.get_all("/v1/builds", {"filter[app]": APP, "sort": "-uploadedDate", "limit": 4})
            for b in bs[:4]:
                x = b["attributes"]; print(" build", x.get("version"), x.get("processingState"))


if __name__ == "__main__":
    main()

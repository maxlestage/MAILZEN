"""Prepares the Apple side of MailZen with the App Store Connect API, before signing:

- registers the bundle IDs of the app and of its share extension, if they do not exist;
- enables the App Groups capability on both (the app and the extension share the
  senders and corrections the user teaches MailZen);
- checks that the app exists in App Store Connect (Apple does not let the API create it:
  App Store Connect → Apps → + → New app, once).

Environment: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8 (the content of the .p8 key), and
optionally APPLE_TEAM_ID: without it, the team is read from Apple (the App ID prefix of
the bundle IDs).
Writes `app_exists=true|false` and `team_id=…` to $GITHUB_OUTPUT.
"""
import json, os, sys, time, urllib.error, urllib.parse, urllib.request

import jwt

API = "https://api.appstoreconnect.apple.com/v1"
BUNDLES = [("com.maxlestage.mailzen", "MailZen"), ("com.maxlestage.mailzen.share", "MailZen Share")]


def token():
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
                      os.environ["ASC_KEY_P8"], algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})


def call(method, path, body=None, query=None):
    url = API + path + ("?" + urllib.parse.urlencode(query) if query else "")
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={"Authorization": "Bearer " + token(), "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        raise SystemExit(f"::error::App Store Connect {method} {path}: HTTP {e.code} {detail}")


def ensure_bundle(identifier, name):
    found = [b for b in call("GET", "/bundleIds", query={"filter[identifier]": identifier, "limit": 200})["data"]
             if b["attributes"]["identifier"] == identifier]
    if found:
        bundle = found[0]
        print(f"Bundle ID {identifier}: already registered")
    else:
        bundle = call("POST", "/bundleIds", {"data": {"type": "bundleIds", "attributes": {
            "identifier": identifier, "name": name, "platform": "IOS"}}})["data"]
        print(f"Bundle ID {identifier}: registered")
    seed = bundle["attributes"].get("seedId") or ""
    caps = call("GET", f"/bundleIds/{bundle['id']}/bundleIdCapabilities")["data"]
    if any(c["attributes"]["capabilityType"] == "APP_GROUPS" for c in caps):
        print(f"  App Groups: already enabled")
    else:
        call("POST", "/bundleIdCapabilities", {"data": {"type": "bundleIdCapabilities",
             "attributes": {"capabilityType": "APP_GROUPS"},
             "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle["id"]}}}}})
        print(f"  App Groups: enabled")
    return seed


def main():
    seeds = [ensure_bundle(identifier, name) for identifier, name in BUNDLES]
    team = os.environ.get("APPLE_TEAM_ID", "").strip() or next((s for s in seeds if s), "")
    if not team:
        raise SystemExit("::error::No team ID: add the secret APPLE_TEAM_ID (developer.apple.com → Membership).")
    print(f"Team: {team}" + ("" if os.environ.get("APPLE_TEAM_ID", "").strip() else " (read from Apple)"))
    apps = call("GET", "/apps", query={"filter[bundleId]": BUNDLES[0][0]})["data"]
    exists = bool(apps)
    if exists:
        print(f"App Store Connect app: {apps[0]['attributes']['name']} ({apps[0]['id']})")
    else:
        print("::warning::The app does not exist in App Store Connect yet, so TestFlight cannot receive it. "
              "Create it once (Apple does not allow it through the API): App Store Connect → Apps → + → New app, "
              "platform iOS, bundle ID com.maxlestage.mailzen, any SKU. The signed .ipa is kept as an artifact meanwhile.")
    with open(os.environ.get("GITHUB_OUTPUT", os.devnull), "a") as out:
        out.write(f"app_exists={'true' if exists else 'false'}\n")
        out.write(f"team_id={team}\n")


if __name__ == "__main__":
    sys.exit(main())

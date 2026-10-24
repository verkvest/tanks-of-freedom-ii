#!/usr/bin/env python3
"""Register the iOS bundle id with App Store Connect if it does not exist yet.

Uses the API key already installed for Xcode cloud signing:
  KEYFILE, APPSTORE_API_KEY_ID, APPSTORE_API_ISSUER_ID, BUNDLE_ID, APP_NAME
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt


def main() -> int:
    bundle_id = os.environ.get("BUNDLE_ID", "es.verkvest.ashgrid")
    app_name = os.environ.get("APP_NAME", "Ashgrid")
    key = open(os.environ["KEYFILE"], "r", encoding="utf-8").read()
    now = int(time.time())
    token = jwt.encode(
        {
            "iss": os.environ["APPSTORE_API_ISSUER_ID"],
            "iat": now,
            "exp": now + 600,
            "aud": "appstoreconnect-v1",
        },
        key,
        algorithm="ES256",
        headers={"kid": os.environ["APPSTORE_API_KEY_ID"], "typ": "JWT"},
    )
    if isinstance(token, bytes):
        token = token.decode("utf-8")

    def call(method: str, url: str, body=None):
        data = None if body is None else json.dumps(body).encode("utf-8")
        request = urllib.request.Request(url, data=data, method=method)
        request.add_header("Authorization", "Bearer " + token)
        request.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(request) as response:
                return response.status, response.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            return error.code, error.read().decode("utf-8", errors="replace")

    status, payload = call(
        "GET",
        "https://api.appstoreconnect.apple.com/v1/bundleIds?filter[identifier]=" + bundle_id,
    )
    print(f"bundle id lookup HTTP {status}")
    if status == 200 and f'"identifier":"{bundle_id}"' in payload.replace(" ", ""):
        print(f"{bundle_id} is already registered")
        return 0

    status, payload = call(
        "POST",
        "https://api.appstoreconnect.apple.com/v1/bundleIds",
        {
            "data": {
                "type": "bundleIds",
                "attributes": {
                    "identifier": bundle_id,
                    "name": app_name,
                    "platform": "IOS",
                },
            }
        },
    )
    print(f"bundle id create HTTP {status}")
    print(payload[:1500])
    if status in (201, 409):
        return 0
    if status == 200:
        return 0
    print("::error::Could not register bundle id " + bundle_id, file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Verify health and the exact immutable build identity; no Azure SDK required."""
import argparse
import json
import time
import urllib.error
import urllib.request


def get(url):
    with urllib.request.urlopen(url, timeout=10) as response:
        if response.status != 200:
            raise ValueError(f"Unexpected HTTP status {response.status}")
        return response.read().decode("utf-8")


def verify(base_url, expected_commit):
    if get(base_url.rstrip("/") + "/health").strip() != "Healthy":
        raise ValueError("Health response was not Healthy")
    info = json.loads(get(base_url.rstrip("/") + "/api/info"))
    if info.get("service") != "octo" or info.get("commit") != expected_commit:
        raise ValueError("Release identity does not match the expected artifact")
    return info


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("commit")
    parser.add_argument("--attempts", type=int, default=18)
    parser.add_argument("--delay", type=float, default=10)
    args = parser.parse_args()
    if args.attempts < 1 or args.delay < 0:
        parser.error("attempts must be positive and delay must be nonnegative")
    for attempt in range(args.attempts):
        try:
            verify(args.url, args.commit)
            print("Health and release identity verified.")
            return
        except (urllib.error.URLError, TimeoutError, ValueError, KeyError) as error:
            print(f"Verification attempt {attempt + 1}/{args.attempts} failed: {error}")
            if attempt + 1 < args.attempts:
                time.sleep(args.delay)
    raise SystemExit("Smoke test failed; release must not proceed.")


if __name__ == "__main__":
    main()

"""Rewrite a wg-netns profile to point at a random Mullvad-owned relay.

Usage: mullvad-relay <base-profile> <output-profile> <cache-file> <country>...

The base profile (from agenix) supplies the private key, addresses, etc.
Only the Mullvad peer's public-key and endpoint are replaced. The relay list
is cached so a restart still works if the Mullvad API is unreachable.
"""

import json
import os
import random
import sys
import time
import urllib.request

import yaml

RELAYS_URL = "https://api.mullvad.net/public/relays/wireguard/v2"
DEFAULT_PORT = 51820


def fetch_relays(cache_file):
    for attempt in range(5):
        try:
            with urllib.request.urlopen(RELAYS_URL, timeout=15) as resp:
                data = json.load(resp)
            with open(cache_file + ".tmp", "w") as f:
                json.dump(data, f)
            os.replace(cache_file + ".tmp", cache_file)
            return data
        except Exception as e:
            print(f"fetching relay list failed (attempt {attempt + 1}): {e}", file=sys.stderr)
            time.sleep(2 ** attempt)
    print(f"falling back to cached relay list {cache_file}", file=sys.stderr)
    with open(cache_file) as f:
        return json.load(f)


def main():
    base_profile, output_profile, cache_file, *countries = sys.argv[1:]
    prefixes = tuple(f"{c}-" for c in countries)

    with open(base_profile) as f:
        profile = yaml.safe_load(f)

    all_relays = fetch_relays(cache_file)["wireguard"]["relays"]
    relays = [
        r
        for r in all_relays
        if r["active"] and r["owned"] and r["location"].startswith(prefixes)
    ]
    if not relays:
        sys.exit(f"no active Mullvad-owned relays found in {countries}")
    relay = random.choice(relays)

    # The profile may contain non-Mullvad peers too; rewrite the one whose key
    # belongs to a Mullvad relay, falling back to the first peer.
    mullvad_keys = {r["public_key"] for r in all_relays}
    peers = profile["interfaces"][0]["peers"]
    peer = next(
        (p for p in peers if p.get("public-key", p.get("public_key")) in mullvad_keys),
        peers[0],
    )
    # wg-netns accepts both dashed and underscored keys; normalise to dashes.
    peer.pop("public_key", None)
    port = DEFAULT_PORT
    if peer.get("endpoint"):
        port = int(peer["endpoint"].rsplit(":", 1)[1])
    peer["public-key"] = relay["public_key"]
    peer["endpoint"] = f"{relay['ipv4_addr_in']}:{port}"
    print(f"selected relay {relay['hostname']} ({peer['endpoint']})")

    fd = os.open(output_profile, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        yaml.safe_dump(profile, f)


if __name__ == "__main__":
    main()

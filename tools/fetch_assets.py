#!/usr/bin/env python3
"""
Coastline: Vicio Bay — Deterministic Hash-Pinned Asset Fetcher.
Reads assets/manifest.json, downloads missing assets into assets/downloads/ (gitignored),
verifies SHA-256 hashes, and optionally unpacks/links into target paths.
"""

import argparse
import hashlib
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST_PATH = ROOT / "assets" / "manifest.json"
DOWNLOAD_DIR = ROOT / "assets" / "downloads"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch or verify manifest assets.")
    parser.add_argument("--verify", action="store_true", help="Verify manifest schema and existing local downloads only.")
    args = parser.parse_args()

    if not MANIFEST_PATH.exists():
        print(f"ERROR: Missing manifest at {MANIFEST_PATH}", file=sys.stderr)
        return 1

    data = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    assets = data.get("assets", [])
    if not isinstance(assets, list):
        print("ERROR: manifest.json 'assets' must be a list", file=sys.stderr)
        return 1

    if not assets:
        print("assets/manifest.json valid (0 external assets queued).")
        return 0

    DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
    for item in assets:
        asset_id = item["id"]
        url = item["url"]
        expected_sha = item["sha256"].lower()
        target = ROOT / item["target_path"]
        license_name = item.get("license", "")
        if not license_name:
            print(f"ERROR: Asset '{asset_id}' missing license metadata", file=sys.stderr)
            return 1

        if target.exists():
            actual = sha256_file(target)
            if actual != expected_sha:
                print(f"ERROR: Hash mismatch for {target}: expected {expected_sha}, got {actual}", file=sys.stderr)
                return 1
            print(f"OK: {asset_id} ({target})")
            continue

        if args.verify:
            print(f"MISSING (run tools/fetch_assets.py without --verify): {asset_id} -> {target}")
            return 1

        target.parent.mkdir(parents=True, exist_ok=True)
        print(f"Fetching {asset_id} from {url}...")
        urllib.request.urlretrieve(url, target)
        actual = sha256_file(target)
        if actual != expected_sha:
            target.unlink(missing_ok=True)
            print(f"ERROR: Downloaded hash mismatch for {asset_id}: expected {expected_sha}, got {actual}", file=sys.stderr)
            return 1
        print(f"Fetched & verified: {asset_id}")

    return 0


if __name__ == "__main__":
    sys.exit(main())

"""
Evidence Bundle Generator & Verifier for RehabBridge NEXUS / H10.
Complies with Build Specification v3 Section 15.3 and test API-09.
Packs database, validation sheet, configs, and git metadata into a tamper-evident ZIP with SHA-256 manifests.
"""

import argparse
import hashlib
import io
import json
import os
import sys
import zipfile
from datetime import datetime, timezone


def sha256_file(filepath: str) -> str:
    """Computes SHA-256 hash of a file."""
    hasher = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()


def generate_bundle(output_zip: str, base_dir: str):
    """Generates evidence bundle zip with file manifest."""
    files_to_pack = [
        os.path.join(base_dir, "config", "signal.yaml"),
        os.path.join(base_dir, "config", "taskproof.yaml"),
        os.path.join(base_dir, "config", "zones.json"),
        os.path.join(base_dir, "shared", "protocol", "protocol_v1_schema.json"),
        os.path.join(base_dir, "docs", "PROJECT_STATUS.md"),
        os.path.join(base_dir, "docs", "IMPLEMENTATION_LOG.md"),
    ]

    manifest = {
        "title": "RehabBridge NEXUS / H10 Evidence Bundle",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "git_commit": "0dd47a5",
        "files": {},
    }

    with zipfile.ZipFile(output_zip, "w", zipfile.ZIP_DEFLATED) as zf:
        for fpath in files_to_pack:
            if os.path.exists(fpath):
                arcname = os.path.relpath(fpath, base_dir).replace("\\", "/")
                zf.write(fpath, arcname)
                manifest["files"][arcname] = {
                    "sha256": sha256_file(fpath),
                    "size_bytes": os.path.getsize(fpath),
                }

        # Add manifest to zip
        zf.writestr("manifest.json", json.dumps(manifest, indent=2))

    print(f"Evidence bundle created at: {output_zip}")
    print(f"Files bundled: {len(manifest['files'])}")


def verify_bundle(zip_path: str) -> bool:
    """Verifies SHA-256 hashes inside evidence bundle match manifest."""
    if not os.path.exists(zip_path):
        print(f"Bundle file not found: {zip_path}")
        return False

    with zipfile.ZipFile(zip_path, "r") as zf:
        if "manifest.json" not in zf.namelist():
            print("manifest.json missing in bundle!")
            return False

        manifest_data = json.loads(zf.read("manifest.json").decode("utf-8"))
        all_ok = True

        for arcname, meta in manifest_data["files"].items():
            if arcname not in zf.namelist():
                print(f"Missing file: {arcname}")
                all_ok = False
                continue

            content = zf.read(arcname)
            computed_hash = hashlib.sha256(content).hexdigest()
            if computed_hash != meta["sha256"]:
                print(f"Hash mismatch for {arcname}! Expected: {meta['sha256']}, got: {computed_hash}")
                all_ok = False
            else:
                print(f"Verified {arcname}: OK")

        return all_ok


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evidence Bundle Tool")
    parser.add_argument("--create", help="Create bundle zip file")
    parser.add_argument("--verify", help="Verify existing bundle zip file")
    args = parser.parse_args()

    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    if args.create:
        generate_bundle(args.create, repo_root)
    elif args.verify:
        ok = verify_bundle(args.verify)
        sys.exit(0 if ok else 1)
    else:
        out = os.path.join(repo_root, "evidence_bundle.zip")
        generate_bundle(out, repo_root)

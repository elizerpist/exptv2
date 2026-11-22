#!/usr/bin/env python3
"""Check or stage the INCOMPLETE R29 host bootstrap on the pinned AOSP tree.

This does not provide the lockscreen scene integration or frame-level safety
proof. --apply requires --allow-incomplete and a clean, committed Fluvi source.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
UPSTREAM = "99b01a65cc4c104933788b3143285ab6bae65827"
PATCH = ROOT / "platform/aosp16/patches/0001-r29-host-bootstrap-WIP.patch"


def git(cwd, *args):
    return subprocess.run(["git", "-C", str(cwd), *args], check=True, text=True, capture_output=True).stdout.strip()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(base, assets, apply, allow_incomplete):
    base, assets = Path(base).resolve(), Path(assets).resolve()
    if git(base, "rev-parse", "HEAD") != UPSTREAM:
        raise ValueError("frameworks/base HEAD does not match the pinned Android 16 commit")
    if git(base, "status", "--porcelain", "--untracked-files=all"):
        raise ValueError("frameworks/base worktree is not clean")
    subprocess.run(["git", "-C", str(base), "apply", "--check", str(PATCH)], check=True)
    source_head = git(ROOT, "rev-parse", "HEAD")
    source_dirty = bool(git(ROOT, "status", "--porcelain", "--untracked-files=no"))
    source_untracked = bool(git(ROOT, "ls-files", "--others", "--", "platform/aosp16"))
    if apply and (source_dirty or source_untracked or not allow_incomplete):
        raise ValueError("apply needs committed Fluvi source, no untracked platform files and --allow-incomplete")

    with tempfile.TemporaryDirectory(prefix="r29-verify-") as tmp:
        stage = Path(tmp) / "renderer"
        subprocess.run(["python3", str(ROOT / "platform/aosp16/tools/stage_canonical_renderer.py"),
                        "--source", str(ROOT), "--assets", str(assets), "--output", str(stage)], check=True)
        entries = []
        for src, dest in ((stage / "src", base / "packages/SystemUI/src"),
                          (ROOT / "platform/aosp16/contract/src", base / "packages/SystemUI/src"),
                          (ROOT / "platform/aosp16/systemui/src", base / "packages/SystemUI/src"),
                          (ROOT / "platform/aosp16/systemui/tests", base / "packages/SystemUI/tests/robolectric/src"),
                          (stage / "assets", base / "packages/SystemUI/fluvi_r29/assets")):
            for f in src.rglob("*"):
                if f.is_file(): entries.append((f, dest / f.relative_to(src)))
        destinations = [dest for _, dest in entries]
        if len(destinations) != len(set(destinations)):
            raise ValueError("duplicate staged destination")
        for _, dest in entries:
            if dest.exists() or dest.is_symlink():
                raise ValueError("refusing to overwrite " + str(dest))
        receipt = {"status": "INCOMPLETE_HOST_BOOTSTRAP", "frameworksBase": UPSTREAM,
                   "fluviHead": source_head, "fluviTrackedDirty": source_dirty,
                   "fluviPlatformUntracked": source_untracked, "patchSha256": digest(PATCH), "rendererManifestSha256": digest(stage / "renderer-manifest.json"),
                   "staged": {str(d.relative_to(base)): digest(s) for s, d in sorted(entries, key=lambda x: str(x[1]))}}
        print(json.dumps({k: v for k, v in receipt.items() if k != "staged"}, sort_keys=True))
        print("stagedFiles=" + str(len(entries)))
        if not apply:
            return
        created = []
        applied = False
        try:
            subprocess.run(["git", "-C", str(base), "apply", str(PATCH)], check=True)
            applied = True
            for src, dest in entries:
                dest.parent.mkdir(parents=True, exist_ok=True)
                with src.open("rb") as input_file, dest.open("xb") as output_file:
                    shutil.copyfileobj(input_file, output_file)
                created.append(dest)
            receipt_path = base / "packages/SystemUI/fluvi_r29/provenance.json"
            with receipt_path.open("x") as file:
                json.dump(receipt, file, indent=2, sort_keys=True)
                file.write("\n")
            created.append(receipt_path)
            print("hostBootstrapApplied=true; scene integration and safety gates remain missing")
        except Exception:
            for path in reversed(created):
                path.unlink(missing_ok=True)
            if applied:
                subprocess.run(["git", "-C", str(base), "apply", "--reverse", str(PATCH)], check=True)
            raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", required=True, help="clean AOSP frameworks/base worktree")
    parser.add_argument("--assets", required=True, help="Fluvi Gradle generated/keyguardHeaderMaterial/assets")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--allow-incomplete", action="store_true")
    options = parser.parse_args()
    try:
        run(options.base, options.assets, options.apply, options.allow_incomplete)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f"R29 host bootstrap failed: {exc}\n")

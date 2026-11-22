#!/usr/bin/env python3
"""Verify the real-source staging guard without modifying the AOSP checkout."""
import os
import importlib.util
import sys
from unittest import mock
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(os.environ.get("R29_AOSP_BASE", "/nonexistent"))
ASSETS = Path(os.environ.get("R29_GENERATED_ASSETS", ROOT / "build/app/generated/keyguardHeaderMaterial/assets"))

class AospStageGuardTest(unittest.TestCase):
    def test_ignored_untracked_platform_file_cannot_be_staged(self):
        if not (BASE / ".git").exists() and not (BASE / ".git").is_file():
            self.skipTest("R29_AOSP_BASE must name a clean pinned frameworks/base checkout")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in ("platform/aosp16", "android/app/src/main/kotlin/com/fluvi/app/lockscreen/material",
                         "shaders"):
                shutil.copytree(ROOT / name, root / name)
            (root / "android/app").mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / "android/app/build.gradle.kts", root / "android/app/build.gradle.kts")
            (root / ".gitignore").write_text("platform/aosp16/ignored-stage-test.dat\n")
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "add", "."], check=True)
            subprocess.run(["git", "-C", str(root), "-c", "user.name=Stage Test", "-c",
                            "user.email=stage-test@example.invalid", "commit", "-qm", "fixture"], check=True)
            (root / "platform/aosp16/ignored-stage-test.dat").write_text("must never be staged\n")
            status_before = subprocess.check_output(["git", "-C", str(BASE), "status", "--porcelain"], text=True)
            proc = subprocess.run(["python3", str(root / "platform/aosp16/tools/stage_aosp_wip.py"),
                "--base", str(BASE), "--assets", str(ASSETS), "--apply", "--allow-incomplete"],
                text=True, capture_output=True)
            self.assertNotEqual(0, proc.returncode)
            self.assertIn("no untracked platform files", proc.stderr)
            self.assertEqual(status_before, subprocess.check_output(
                ["git", "-C", str(BASE), "status", "--porcelain"], text=True))

    def test_copy_error_rolls_back_the_real_clean_worktree(self):
        if not (BASE / ".git").exists() and not (BASE / ".git").is_file():
            self.skipTest("R29_AOSP_BASE must name a clean pinned frameworks/base checkout")
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in ("platform/aosp16", "android/app/src/main/kotlin/com/fluvi/app/lockscreen/material", "shaders"):
                shutil.copytree(ROOT / name, root / name)
            (root / "android/app").mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / "android/app/build.gradle.kts", root / "android/app/build.gradle.kts")
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            subprocess.run(["git", "-C", str(root), "add", "."], check=True)
            subprocess.run(["git", "-C", str(root), "-c", "user.name=Stage Test", "-c",
                            "user.email=stage-test@example.invalid", "commit", "-qm", "fixture"], check=True)
            script = root / "platform/aosp16/tools/stage_aosp_wip.py"
            sys.dont_write_bytecode = True
            spec = importlib.util.spec_from_file_location("r29_stage_rollback_test", script)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            status_before = subprocess.check_output(["git", "-C", str(BASE), "status", "--porcelain"], text=True)
            with mock.patch.object(module.shutil, "copyfileobj", side_effect=OSError("injected copy failure")):
                with self.assertRaisesRegex(OSError, "injected copy failure"):
                    module.run(BASE, ASSETS, apply=True, allow_incomplete=True)
            self.assertEqual(status_before, subprocess.check_output(
                ["git", "-C", str(BASE), "status", "--porcelain"], text=True))

if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Reproducibility and rejection checks for the source-only R29 renderer staging."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / "platform/aosp16/tools/stage_canonical_renderer.py"
ASSETS = Path(os.environ.get("R29_GENERATED_ASSETS", ROOT / "build/app/generated/keyguardHeaderMaterial/assets"))

class RendererStagingTest(unittest.TestCase):
    def run_stage(self, assets, output):
        return subprocess.run(["python3", str(SCRIPT), "--source", str(ROOT), "--assets", str(assets),
                               "--output", str(output)], text=True, capture_output=True)

    def test_reproducible_and_refuses_overwrite(self):
        with tempfile.TemporaryDirectory() as tmp:
            first, second = Path(tmp) / "one", Path(tmp) / "two"
            self.assertEqual(0, self.run_stage(ASSETS, first).returncode)
            self.assertEqual(0, self.run_stage(ASSETS, second).returncode)
            self.assertEqual((first / "renderer-manifest.json").read_bytes(),
                             (second / "renderer-manifest.json").read_bytes())
            manifest = json.loads((first / "renderer-manifest.json").read_text())
            self.assertEqual((18, 2, 77), (manifest["effects"], manifest["variants"], len(manifest["files"])))
            for name, expected in manifest["files"].items():
                self.assertEqual(expected, hashlib.sha256((first / name).read_bytes()).hexdigest())
            self.assertNotEqual(0, self.run_stage(ASSETS, first).returncode)

    def test_coherently_modified_shader_and_metadata_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "assets"
            source.mkdir()
            for path in ASSETS.iterdir():
                if path.is_file():
                    (source / path.name).symlink_to(path.resolve())
            stem = "fluvi_keyguard_header_material_dualTide_plain"
            shader = source / (stem + ".agsl")
            contents = shader.read_bytes() + b"\n// altered but internally consistent\n"
            shader.unlink()
            shader.write_bytes(contents)
            metadata = source / (stem + ".meta")
            rows = metadata.read_text().splitlines()
            calculated = hashlib.sha256(contents.split(b"\n", 4)[4]).hexdigest()
            rows = [("generated-agsl-sha256=" + calculated) if row.startswith("generated-agsl-sha256=")
                    else row for row in rows]
            metadata.unlink()
            metadata.write_text("\n".join(rows) + "\n")
            output = Path(tmp) / "stage"
            proc = self.run_stage(source, output)
            self.assertNotEqual(0, proc.returncode)
            self.assertFalse(output.exists())

    def test_modified_shader_is_rejected_without_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "assets"
            source.mkdir()
            for path in ASSETS.iterdir():
                if path.is_file():
                    (source / path.name).symlink_to(path.resolve())
            target = source / "fluvi_keyguard_header_material_dualTide_plain.agsl"
            content = target.read_bytes()
            target.unlink()
            target.write_bytes(content + b"tampered")
            output = Path(tmp) / "stage"
            proc = self.run_stage(source, output)
            self.assertNotEqual(0, proc.returncode)
            self.assertIn("pinned asset digest mismatch", proc.stderr)
            self.assertFalse(output.exists())

if __name__ == "__main__":
    unittest.main()

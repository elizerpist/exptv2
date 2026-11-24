#!/usr/bin/env python3
"""Exercise the real Human wrapper without running Flutter or touching app data."""
import os
import pathlib
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix="r36-build-options-") as folder:
    stub = pathlib.Path(folder) / "flutter"
    stub.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
    stub.chmod(0o755)
    env = os.environ.copy()
    env.pop("FLUVI_HUMAN_SEED_DEMO", None)
    env["FLUVI_BUILD_COMMIT"] = "a" * 40
    env["PATH"] = folder + os.pathsep + env["PATH"]
    def args():
        return subprocess.run(["bash", "scripts/build-human-diagnostic-apk.sh"], cwd=root,
                              env=env, text=True, stdout=subprocess.PIPE, check=True).stdout.splitlines()
    default = args()
    assert "--dart-define=FLUVI_SEED_DEMO=false" in default, default
    assert "--dart-define=FLUVI_BUILD_PURPOSE=human_diagnostic" in default, default
    assert "--dart-define=FLUVI_BUILD_COMMIT=" + "a" * 40 in default, default
    env["FLUVI_HUMAN_SEED_DEMO"] = "true"
    assert "--dart-define=FLUVI_SEED_DEMO=true" in args()
print("R36 Human build: no automatic demo database seed by default; explicit opt-in preserved")

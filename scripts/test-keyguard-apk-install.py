#!/usr/bin/env python3
"""Fail-closed host controls for before/after installed-APK receipts."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
helper = root / 'scripts/verify-keyguard-installed-apk.sh'
with tempfile.TemporaryDirectory() as temporary:
    base = Path(temporary)
    app = base / 'source.apk'
    installed = base / 'installed.apk'
    app.write_bytes(b'real candidate bytes\n')
    installed.write_bytes(app.read_bytes())
    adb = base / 'adb'
    adb.write_text('''#!/usr/bin/env bash
set -eu
case "$*" in
  "shell pm path com.fluvi.app")
    if [[ ${FAKE_MODE:-} == path_error ]]; then exit 19; fi
    printf 'package:/data/app/test/base.apk\\r\\n'
    if [[ ${FAKE_MODE:-} == split ]]; then printf 'package:/data/app/test/split.apk\\r\\n'; fi ;;
  "shell pm list packages -f com.fluvi.app")
    if [[ ${FAKE_MODE:-} == wrong_package ]]; then printf 'package:/data/app/test/base.apk=other.app\\r\\n'
    else printf 'package:/data/app/test/base.apk=com.fluvi.app\\r\\n'; fi ;;
  "exec-out cat /data/app/test/base.apk")
    if [[ ${FAKE_MODE:-} == bytes_error ]]; then exit 20; fi
    cat "$FAKE_INSTALLED" ;;
  *) exit 21 ;;
esac
''')
    adb.chmod(0o755)
    env = dict(os.environ, PATH=f'{base}:{os.environ["PATH"]}', FAKE_INSTALLED=str(installed))
    def run(mode: str, label: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(['bash', str(helper), 'com.fluvi.app', str(app), str(base), label],
                              env=dict(env, FAKE_MODE=mode), capture_output=True, text=True)
    assert run('', 'before-app').returncode == 0
    assert run('', 'after-app').returncode == 0
    assert (base / 'installed-before-app-bytes.exit').read_text().strip() == '0'
    for mode in ('split', 'wrong_package', 'path_error', 'bytes_error'):
        assert run(mode, mode.replace('_', '-')).returncode != 0, mode
    installed.write_bytes(b'different installed bytes\n')
    assert run('', 'mismatch').returncode != 0
print('PASS installed APK receipts: before/after match and five split/identity/command/byte negatives')

#!/usr/bin/env python3
"""Fixed admission-baseline runner negative controls; not Android evidence."""
from pathlib import Path
import io
import os
import shutil
import subprocess
import tarfile
import tempfile

source = Path(__file__).resolve().with_name('test-keyguard-r12-admission-baseline.sh')
with tempfile.TemporaryDirectory(prefix='r12-admission-harness-', dir='/tmp') as temp:
    base = Path(temp)
    root = base / 'repo'
    bindir = base / 'bin'
    for path in (root / 'scripts', root / 'android', root / 'build/app/outputs/apk/debug',
                 root / 'build/app/outputs/apk/androidTest/debug', bindir):
        path.mkdir(parents=True, exist_ok=True)
    shutil.copy(source, root / 'scripts/baseline.sh')
    (root / 'scripts/prepare-keyguard-lower-environment.sh').write_text('mkdir -p "$1"\necho CLEAN > "$1/status.txt"\n')
    app = root / 'build/app/outputs/apk/debug/app-debug.apk'
    test_apk = root / 'build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk'
    (bindir / 'git').write_text('''#!/bin/bash
case "$*" in
 'rev-parse --show-toplevel') echo "$FAKE_ROOT" ;;
 'rev-parse HEAD') echo harness ;;
 *'diff --exit-code'*) [[ "${FAKE_MODE:-}" != source-mismatch ]] ;;
 *'status --porcelain'*) [[ "${FAKE_MODE:-}" != dirty ]] || echo ' M app.kt' ;;
 *) exit 2 ;;
esac
''')
    (bindir / 'adb').write_text('''#!/usr/bin/env python3
import os,pathlib,sys
args=' '.join(sys.argv[1:]); mode=os.environ.get('FAKE_MODE','')
if 'ro.build.version.sdk' in args: print('34' if mode=='bad-api' else '35')
elif 'ro.product.cpu.abi' in args: print('x86_64')
elif 'am instrument' in args:
 if mode != 'missing-method': print('INSTRUMENTATION_STATUS: test=r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply')
 if mode == 'wrong-failure': print('FAILURES!!!\\nfixture was not ready')
 else: print('FAILURES!!!\\ncompatible B did not start before the held ordered A application')
 if mode == 'apk-changed': pathlib.Path(os.environ['FAKE_APP']).write_bytes(b'changed')
elif 'run-as' in args:
 if mode == 'missing-probe': sys.exit(1)
 sys.stdout.buffer.write(pathlib.Path(os.environ['FAKE_TAR']).read_bytes())
elif 'logcat' in args: print('test log')
else: print('ok')
''')
    for binary in bindir.iterdir(): binary.chmod(0o755)
    archive = base / 'probe.tar'
    with tarfile.open(archive, 'w') as out:
        for name, data in [('fixture.txt', b'R12_ADMISSION_ORDER a=1 b=2 bStartedBeforeAApply=false\nR12_ADMISSION_CLEANUP status=PASS\n'),
                           ('capture.txt', b'req=1 reason=NO_MAIN_MARKER\n')]:
            entry = tarfile.TarInfo('files/keyguard-service-probe/r12-admission/' + name)
            entry.size = len(data)
            out.addfile(entry, io.BytesIO(data))
    env = dict(os.environ, PATH=str(bindir)+':'+os.environ['PATH'], FAKE_ROOT=str(root),
               FAKE_APP=str(app), FAKE_TAR=str(archive))
    def run(mode=''):
        shutil.rmtree(root / 'android/keyguard-r12-admission-baseline', ignore_errors=True)
        app.write_bytes(b'baseline-app')
        test_apk.write_bytes(b'baseline-test')
        return subprocess.run(['bash', str(root/'scripts/baseline.sh')], cwd=root,
                              env={**env, 'FAKE_MODE':mode}, capture_output=True, text=True)
    good=run()
    assert good.returncode == 0, (good.stdout, good.stderr)
    assert 'RED_EXPECTED=actual_service_serial_order' in (root/'android/keyguard-r12-admission-baseline/status.txt').read_text()
    for mode in ('source-mismatch','dirty','bad-api','missing-method','wrong-failure','missing-probe','apk-changed'):
        failure=run(mode)
        assert failure.returncode != 0, (mode, failure.stdout, failure.stderr)
    print('PASS R12 baseline fake runner: exact source, device, test method, assertion, evidence and APK identity fail closed')

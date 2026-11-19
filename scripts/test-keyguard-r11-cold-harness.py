#!/usr/bin/env python3
"""Fake-host orchestration checks. These are not Android or pixel evidence."""
import io
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile

source = Path(__file__).resolve().with_name('test-keyguard-r11-cold.sh')
with tempfile.TemporaryDirectory(prefix='r11-cold-harness-', dir='/tmp') as temporary:
    base = Path(temporary)
    root = base / 'repo'
    target = root / 'r11-baseline'
    bindir = base / 'bin'
    for path in (root / 'scripts', root / 'android', target / 'android', bindir,
                 target / 'build/app/outputs/apk/debug', target / 'build/app/outputs/apk/androidTest/debug'):
        path.mkdir(parents=True, exist_ok=True)
    shutil.copy(source, root / 'scripts/cold.sh')
    (root / 'scripts/keyguard-service-trace.pbtxt').write_text('fake trace\n')
    (root / 'scripts/keyguard-r10-cold-trace.sql').write_text('SELECT 1;\n')
    (root / 'scripts/prepare-keyguard-lower-environment.sh').write_text('mkdir -p "$1"\necho CLEAN > "$1/status.txt"\n')
    app = target / 'build/app/outputs/apk/debug/app-debug.apk'
    test_apk = target / 'build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk'
    (bindir / 'git').write_text('''#!/bin/bash
case "$*" in
 'rev-parse --show-toplevel') echo "$FAKE_ROOT" ;;
 *'rev-parse HEAD'*) if [[ "$*" == *r11-baseline* ]]; then echo "${FAKE_BASE_SHA:-8a91bf2d79f25780bb420c1a4d14abe846eac333}"; else echo harness; fi ;;
 *'diff --name-only'*) printf '%s\\n' android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt ;;
 *'diff --exit-code'*) exit 0 ;;
 *'status --porcelain'*) : ;;
 *) exit 2 ;;
esac
''')
    (bindir / 'adb').write_text('''#!/usr/bin/env python3
import os,pathlib,sys
args=' '.join(sys.argv[1:]); state=pathlib.Path(os.environ['FAKE_STATE']); n=int(state.read_text()) if state.exists() else 0
mode=os.environ.get('FAKE_MODE','')
if 'ro.build.version.sdk' in args: print('35')
elif 'ro.product.cpu.abi' in args: print('x86_64')
elif 'ro.build.fingerprint' in args: print('fake-fingerprint')
elif 'perfetto --background-wait' in args: print('123')
elif 'ps -A' in args: print('PID NAME')
elif 'am instrument' in args:
 if 'r11PositiveReadyBeforeGrant' in args: print('FAILURES!!!\\npositive lease was incorrectly classified as detached')
 else:
  n+=1; state.write_text(str(n))
  method='r11ColdAndWarmVisualControl' if 'VisualControl' in args else 'r11ColdAndWarmTimingOnly'
  if mode!='missing-method': print('INSTRUMENTATION_STATUS: test='+method)
  if mode=='skipped': print('INSTRUMENTATION_STATUS_CODE: -3')
  if mode in ('first-fail','invalid-bounds','sampler-fail') and (n==1 if mode=='first-fail' else n==3): print('FAILURES!!!')
  else: print('OK (1 test)')
  if mode=='apk-changed' and n==1: pathlib.Path(os.environ['FAKE_APP']).write_bytes(b'mutated')
elif args.startswith('pull '): pathlib.Path(sys.argv[-1]).write_bytes(b'' if mode=='missing-trace' else b'trace')
elif 'run-as' in args: sys.stdout.buffer.write(pathlib.Path(os.environ['FAKE_TAR_'+str(n)]).read_bytes())
elif 'screencap' in args:
 if mode=='failed-screenshot': sys.exit(1)
 sys.stdout.buffer.write(b'PNG')
elif 'dumpsys window' in args: print('mCurrentFocus=null')
else: print('ok')
''')
    (bindir / 'curl').write_text('''#!/bin/bash
while (( $# )); do if [[ "$1" == -o ]]; then shift; out=$1; fi; shift; done
printf '#!/bin/sh\\necho fake-processor\\n' > "$out"
''')
    for binary in bindir.iterdir():
        binary.chmod(0o755)
    archives = []
    for number in (1, 2, 3):
        archive = base / f'probe-{number}.tar'
        with tarfile.open(archive, 'w') as out:
            for name, marker in [('r11-timing', 'R11_PROCESS'), ('r11-visual', 'R10_PROCESS')]:
                data = f'{marker} capture=x up=1 pid={100+number}\n'.encode()
                entry = tarfile.TarInfo(f'files/keyguard-service-probe/{name}/fixture.txt')
                entry.size = len(data)
                out.addfile(entry, io.BytesIO(data))
        archives.append(archive)
    env = dict(os.environ, PATH=str(bindir) + ':' + os.environ['PATH'], FAKE_ROOT=str(root),
               FAKE_STATE=str(base / 'state'), FAKE_APP=str(app), FLUVI_R11_SCOPE='r11_cold_baseline',
               **{f'FAKE_TAR_{i+1}': str(p) for i,p in enumerate(archives)})
    def run(extra):
        shutil.rmtree(root / 'android/keyguard-r11-cold', ignore_errors=True)
        Path(env['FAKE_STATE']).unlink(missing_ok=True)
        app.write_bytes(b'baseline-app')
        test_apk.write_bytes(b'baseline-test')
        return subprocess.run(['bash', str(root / 'scripts/cold.sh')], cwd=root,
                              env={**env, **extra}, capture_output=True, text=True)
    good = run({})
    assert good.returncode == 0, (good.stdout, good.stderr)
    evidence = root / 'android/keyguard-r11-cold'
    assert 'pid1=101 pid2=102 aggregate=0' in (evidence / 'status.txt').read_text()
    assert 'visual_pid=103' in (evidence / 'visual/status.txt').read_text()
    assert (evidence / 'baseline-red.status').read_text().startswith('RED_EXPECTED')
    for mode in ('first-fail', 'invalid-bounds', 'sampler-fail', 'missing-method', 'skipped',
                 'apk-changed', 'missing-trace', 'failed-screenshot'):
        failure = run({'FAKE_MODE': mode})
        assert failure.returncode != 0, (mode, failure.stdout, failure.stderr)
        if mode in ('first-fail','invalid-bounds','sampler-fail','missing-method','skipped','apk-changed'):
            assert Path(env['FAKE_STATE']).read_text() == '3', f'{mode}: independent phases stopped'
    assert run({'FAKE_BASE_SHA':'wrong'}).returncode != 0
    assert run({'FLUVI_R11_SCOPE':'full'}).returncode != 0
    reused = run({'FAKE_TAR_2': str(archives[0])})
    assert reused.returncode != 0, 'reused process must fail'
    print('PASS fake R11 harness: source/pair, independent processes, failures, missing trace/method, skipped and visual errors')

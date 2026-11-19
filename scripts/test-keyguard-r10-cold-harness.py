#!/usr/bin/env python3
"""Exercise orchestration only; never claim these fake results as device data."""
import io
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile

source = Path(__file__).resolve().with_name('test-keyguard-r10-cold.sh')
with tempfile.TemporaryDirectory(prefix='r10-cold-harness-', dir='/tmp') as temp:
    root = Path(temp) / 'repo'
    target = root / 'r10-baseline'
    bindir = Path(temp) / 'bin'
    for path in [root / 'scripts', root / 'android', target / 'android', bindir,
                 target / 'build/app/outputs/apk/debug', target / 'build/app/outputs/apk/androidTest/debug']:
        path.mkdir(parents=True, exist_ok=True)
    shutil.copy(source, root / 'scripts/cold.sh')
    (root / 'scripts/keyguard-service-trace.pbtxt').write_text('fake trace config\n')
    (root / 'scripts/keyguard-r10-cold-trace.sql').write_text('SELECT 1;\n')
    (root / 'scripts/prepare-keyguard-lower-environment.sh').write_text('mkdir -p "$1"\necho CLEAN > "$1/status.txt"\n')
    (target / 'build/app/outputs/apk/debug/app-debug.apk').write_bytes(b'baseline-app')
    (target / 'build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk').write_bytes(b'baseline-test')
    (bindir / 'git').write_text('''#!/bin/bash
case "$*" in
  'rev-parse --show-toplevel') echo "$FAKE_ROOT" ;;
  *'rev-parse HEAD'*) if [[ "$*" == *r10-baseline* ]]; then echo "${FAKE_BASE_SHA:-1dddbf6f6fbe4b17ec0fdcb033848c8996721529}"; else echo harness; fi ;;
  *'diff --name-only'*) printf '%s\\n' android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardServiceOverlayInstrumentationTest.kt android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt ;;
  *'diff --exit-code'*) exit 0 ;;
  *'status --porcelain'*) : ;;
  *) exit 2 ;;
esac
''')
    (bindir / 'adb').write_text('''#!/usr/bin/env python3
import os,pathlib,sys
args=' '.join(sys.argv[1:]); state=pathlib.Path(os.environ['FAKE_STATE']); n=int(state.read_text()) if state.exists() else 0
if 'ro.build.version.sdk' in args: print('35')
elif 'ro.product.cpu.abi' in args: print('x86_64')
elif 'ro.build.fingerprint' in args: print('fake-fingerprint')
elif 'perfetto --background-wait' in args: print('123')
elif 'ps -A' in args: print('PID NAME')
elif 'am instrument' in args:
 if 'r10PreparedOnlyScene' in args: print('FAILURES!!!\\na preparation-only scene must not be a visible previous layer')
 else:
  n+=1; state.write_text(str(n)); print('INSTRUMENTATION_STATUS: test=r10ColdFirstAndWarmServiceObservation')
  if os.environ.get('FAKE_FAIL_FIRST')=='1' and n==1: print('FAILURES!!!')
  else: print('OK (1 test)')
elif args.startswith('pull '): pathlib.Path(sys.argv[-1]).write_bytes(b'trace')
elif 'run-as' in args: sys.stdout.buffer.write(pathlib.Path(os.environ['FAKE_TAR_'+str(n)]).read_bytes())
elif 'screencap' in args: sys.stdout.buffer.write(b'PNG')
elif 'dumpsys window' in args: print('mCurrentFocus=null')
else: print('ok')
''')
    (bindir / 'curl').write_text('''#!/bin/bash
while (( $# )); do if [[ "$1" == -o ]]; then shift; out=$1; fi; shift; done
printf '#!/bin/sh\\necho fake-processor\\n' > "$out"
''')
    for binary in bindir.iterdir():
        binary.chmod(0o755)
    tars = []
    for number in (1, 2):
        path = Path(temp) / f'probe-{number}.tar'
        with tarfile.open(path, 'w') as archive:
            data = f'R10_PROCESS capture=x up=1 pid={100 + number}\n'.encode()
            info = tarfile.TarInfo('files/keyguard-service-probe/r10-cold/fixture.txt')
            info.size = len(data)
            archive.addfile(info, io.BytesIO(data))
        tars.append(path)
    env = dict(os.environ, PATH=str(bindir) + ':' + os.environ['PATH'], FAKE_ROOT=str(root),
               FAKE_STATE=str(Path(temp) / 'state'), FAKE_TAR_1=str(tars[0]), FAKE_TAR_2=str(tars[1]),
               FLUVI_R10_SCOPE='r10_cold_baseline')
    def run(extra):
        shutil.rmtree(root / 'android/keyguard-r10-cold', ignore_errors=True)
        Path(env['FAKE_STATE']).unlink(missing_ok=True)
        return subprocess.run(['bash', str(root / 'scripts/cold.sh')], cwd=root,
                              env={**env, **extra}, capture_output=True, text=True)
    good = run({})
    assert good.returncode == 0, (good.stdout, good.stderr)
    evidence = root / 'android/keyguard-r10-cold'
    assert 'pid1=101 pid2=102 aggregate=0' in (evidence / 'status.txt').read_text()
    assert (evidence / 'baseline-red.status').read_text().startswith('RED_EXPECTED')
    first_failed = run({'FAKE_FAIL_FIRST': '1'})
    assert first_failed.returncode != 0, 'first failure must remain a failure'
    assert Path(env['FAKE_STATE']).read_text() == '2', 'second independent episode must still execute'
    assert (evidence / 'repetition-1/result.xml').exists() and (evidence / 'repetition-2/result.xml').exists()
    assert run({'FAKE_BASE_SHA': 'wrong'}).returncode != 0
    assert run({'FLUVI_R10_SCOPE': 'full'}).returncode != 0
    print('PASS fake cold harness: pinned baseline, two independent processes, failure aggregation, expected RED and wrong-scope/source rejection')

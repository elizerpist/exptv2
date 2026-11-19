import os, pathlib, shutil, subprocess, tempfile
source=pathlib.Path(__file__).resolve().with_name('test-keyguard-r09-panel.sh')
with tempfile.TemporaryDirectory(prefix='r09-panel-harness-',dir='/tmp') as d:
 r=pathlib.Path(d); root=r/'repo'; target=root/'r09-baseline'; bindir=r/'bin'
 for p in (root/'scripts',root/'android',target/'scripts',target/'android',target/'build/app/outputs/apk/debug',target/'build/app/outputs/apk/androidTest/debug',bindir):p.mkdir(parents=True,exist_ok=True)
 shutil.copy(source,root/'scripts/panel.sh')
 for p in [target/'build/app/outputs/apk/debug/app-debug.apk',target/'build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk']:p.write_bytes(b'apk')
 (target/'scripts/prepare-keyguard-lower-environment.sh').write_text('mkdir -p "$1"\necho PASS > "$1/status.txt"\n')
 (bindir/'git').write_text('''#!/bin/bash
case "$*" in
 'rev-parse --show-toplevel') printf '%s\\n' "$FAKE_ROOT";;
 *'rev-parse HEAD'*) if [[ "$*" == *r09-baseline* ]]; then echo "${FAKE_BASE_SHA:-4464cd0f5fe7abf8eab1e8b876063bdbbf37350a}"; else echo harness-sha; fi;;
 *'status --porcelain'*) :;;
 *) exit 2;;
esac
''')
 (bindir/'adb').write_text('''#!/bin/bash
case "$*" in
 *ro.build.version.sdk*) echo 35;;
 *ro.product.cpu.abi*) echo x86_64;;
 *ro.build.fingerprint*) echo fake-pixel;;
 *'wm size'*) echo 'Physical size: 1080x2400';;
 *'wm density'*) echo 'Physical density: 420';;
 *'dumpsys window'*) echo 'mCurrentFocus=null';;
 *'screencap -p'*) printf PNG;;
 *logcat*) echo logcat;;
 *'run-as'*) echo tar;;
 *) exit 0;;
esac
''')
 (target/'android/gradlew').write_text('''#!/usr/bin/env python3
import os,pathlib,sys,xml.etree.ElementTree as E
p=next(a.split('=',1)[1] for a in sys.argv if a.startswith('-Pandroid.testInstrumentationRunnerArguments.class='))
names=[x.split('#')[-1] for x in p.split(',')]
if os.getenv('FAKE_OMIT')=='1': names.pop()
r=E.Element('testsuite')
for n in names:
 t=E.SubElement(r,'testcase',name=n)
 if os.getenv('FAKE_SKIP')=='1' and n==names[0]:E.SubElement(t,'skipped')
out=pathlib.Path('../build/app/outputs/androidTest-results/connected/debug');out.mkdir(parents=True,exist_ok=True)
E.ElementTree(r).write(out/'TEST-fake.xml')
out=pathlib.Path('../build/app/reports/androidTests/connected');out.mkdir(parents=True,exist_ok=True)
(out/'index.html').write_text('fake')
''')
 for p in (bindir/'git',bindir/'adb',target/'android/gradlew'):p.chmod(0o755)
 env=dict(os.environ,PATH=str(bindir)+':'+os.environ['PATH'],FAKE_ROOT=str(root),FLUVI_R09_SCOPE='r09_panel_baseline')
 def run(extra):
  shutil.rmtree(root/'android/keyguard-r09-panel',ignore_errors=True)
  return subprocess.run(['bash',str(root/'scripts/panel.sh')],cwd=root,env={**env,**extra},capture_output=True,text=True)
 a=run({});assert a.returncode==0,(a.returncode,a.stdout,a.stderr)
 e=root/'android/keyguard-r09-panel'; assert len((e/'requested-tests.txt').read_text().splitlines())==6
 assert all('PASS' in line for line in (e/'executed-tests.txt').read_text().splitlines())
 assert '4464cd0f' in (e/'manifest.txt').read_text() and (e/'screen-after.png').read_bytes()==b'PNG'
 for extra in [{'FAKE_OMIT':'1'},{'FAKE_SKIP':'1'},{'FAKE_BASE_SHA':'wrong'},{'FLUVI_R09_SCOPE':'full'}]:
  a=run(extra);assert a.returncode!=0,(extra,a.stdout,a.stderr)
 print('PASS fake-device baseline runner: exact source, six executed tests, omitted/skipped/mismatched/invalid scope fail closed, evidence retained')

#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r224-overhead"
mkdir -p "$out"
{ adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
test "$(adb shell getprop ro.product.cpu.abi | tr -d '\r')" = x86_64
adb shell wm density 420
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell wm size | tr -d '\r' | grep -Eq '(^|: )1080x2400$'
(cd "$GITHUB_WORKSPACE/app" && timeout -k 2s 60s bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight")
failed=0
for mode in OFF LIGHT; do
 dest="$out/$mode"; mkdir -p "$dest"
 app="$GITHUB_WORKSPACE/app/build/app/outputs/apk/debug/app-debug.apk"
 test_apk="$GITHUB_WORKSPACE/app/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
 adb shell am force-stop com.fluvi.app || true
 adb uninstall com.fluvi.app > "$dest/uninstall.txt" 2>&1 || true
 adb install -r "$app" > "$dest/install-app.txt" 2>&1
 adb install -r "$test_apk" > "$dest/install-test.txt" 2>&1
 (cd "$GITHUB_WORKSPACE/app" && bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app "$app" "$dest" app)
 (cd "$GITHUB_WORKSPACE/app" && bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app.test "$test_apk" "$dest" test)
 run=$(python3 -c 'import uuid; print(uuid.uuid4())')
 printf 'source=%s\nmode=%s\nuuid=%s\n' "$APP_SHA" "$mode" "$run" > "$dest/identity.txt"
 adb logcat -c || true
 rc=0
 timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$run" -e r12Mode SURFACE_LIVE -e r224CaptureMode "$mode" \
  -e class 'com.fluvi.app.lockscreen.KeyguardR12ServiceTimingInstrumentationTest#r22_4CaptureOverheadArm' \
  com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$dest/instrumentation.txt" 2>&1 || rc=$?
 printf '%s\n' "$rc" > "$dest/exit.txt"
 adb logcat -b all -d -v monotonic > "$dest/logcat.txt" 2>&1 || true
 adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r12-timing/$run" > "$dest/evidence.tar" 2> "$dest/evidence.stderr" || true
 if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$dest/instrumentation.txt" || ! grep -Eq '^OK \(1 test\)' "$dest/instrumentation.txt"; then failed=1; fi
 cat "$dest/instrumentation.txt"
done
python3 - "$out" <<'PY' > "$out/comparison.json"
import json, pathlib, re, statistics, sys, tarfile
root=pathlib.Path(sys.argv[1]); result={'physical_presentation':'UNOBSERVED','observer':'identical test-only bounded recorder','mode':'SURFACE_LIVE'}
for mode in ['OFF','LIGHT']:
 d=root/mode; row={'mode':mode}
 try:
  with tarfile.open(d/'evidence.tar') as a:
   def get(name):
    m=[x for x in a.getmembers() if x.name.endswith('/'+name)]
    assert len(m)==1, name+' missing/ambiguous'
    return a.extractfile(m[0]).read().decode()
   fixture=get('fixture.txt'); lines=get('r22-4-overhead.jsonl'); row['meta']=get('r22-4-overhead-meta.txt').strip()
  events=[json.loads(l) for l in lines.splitlines() if l]
  finishes=[e for e in events if e['kind']=='finish' and not e['aborted']]
  starts=[e for e in events if e['kind']=='start']
  durations=[e['finish']-e['start'] for e in finishes]
  delays=[e['observed']-e['callback'] for e in starts if isinstance(e.get('callback'),int)]
  pairs=[]
  for line in fixture.splitlines():
   m=re.search(r'^WAKE .*name=(\S+) wake=(\d+) attached=(\d+)',line)
   if m: pairs.append({'wake':m[1],'trigger_to_observed_attached_ms':int(m[3])-int(m[2])})
  def summary(values):
   return {'n':len(values),'values_ms':values,'median_ms':statistics.median(values) if values else None,'max_ms':max(values) if values else None}
  row.update({'reader':summary(durations),'callback_to_probe_start':summary(delays),'cycles':pairs,'test_result':next((x for x in fixture.splitlines() if x.startswith('RESULT ')),'UNOBSERVED')})
 except Exception as e: row['status']='NOT_ESTABLISHED: '+str(e)
 result[mode]=row
print(json.dumps(result,indent=2,sort_keys=True))
PY
cat "$out/comparison.json"
exit "$failed"

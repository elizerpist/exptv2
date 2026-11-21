#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r22-3-cadence"
{ adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell wm size; adb shell wm density; } > "$out/device.txt" 2>&1
test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
test "$(adb shell getprop ro.product.cpu.abi | tr -d '\r')" = x86_64
adb shell wm density 420
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell wm size | tr -d '\r' | grep -Eq '(^|: )1080x2400$'
failed=0
for arm in baseline candidate; do
  dir="$GITHUB_WORKSPACE/$arm"
  source="$BASE_SHA"
  if [[ "$arm" == candidate ]]; then source="$APP_SHA"; fi
  app="$dir/build/app/outputs/apk/debug/app-debug.apk"
  test_apk="$dir/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
  adb shell am force-stop com.fluvi.app || true
  adb uninstall com.fluvi.app > "$out/$arm/uninstall-before.txt" 2>&1 || true
  adb install -r "$app" > "$out/$arm/install-app.txt" 2>&1
  adb install -r "$test_apk" > "$out/$arm/install-test.txt" 2>&1
  (cd "$dir" && bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app "$app" "$out/$arm" app)
  (cd "$dir" && bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app.test "$test_apk" "$out/$arm" test)
  if [[ "$arm" == baseline ]]; then
    (cd "$dir" && timeout -k 2s 60s bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight")
  fi
  adb shell run-as com.fluvi.app rm -rf files/keyguard-material-smoke || true
  adb logcat -c || true
  run=$(python3 -c 'import uuid; print(uuid.uuid4())')
  printf '%s\n' "$run" > "$out/$arm/uuid.txt"
  rc=0
  timeout -k 5s 180s adb shell am instrument -w -r -e sourceSha "$source" -e runUuid "$run" \
    -e class 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r22_3TranslucentSteadyCadence' \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$arm/instrumentation.txt" 2>&1 || rc=$?
  printf '%s\n' "$rc" > "$out/$arm/exit.txt"
  adb logcat -b all -d -v monotonic > "$out/$arm/logcat.txt" 2>&1 || true
  adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke > "$out/$arm/evidence.tar" 2> "$out/$arm/evidence.stderr" || true
  cat "$out/$arm/instrumentation.txt"
  if [[ "$rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$arm/instrumentation.txt" || ! grep -Eq '^OK \(1 test\)' "$out/$arm/instrumentation.txt"; then failed=1; fi
  # Separate held/controlled phase probe: never insert readback into the timed 15s pair.
  adb shell am force-stop com.fluvi.app || true
  adb shell run-as com.fluvi.app rm -rf files/keyguard-material-smoke || true
  adb logcat -c || true
  phase_run=$(python3 -c 'import uuid; print(uuid.uuid4())')
  printf '%s\n' "$phase_run" > "$out/$arm/phase-uuid.txt"
  phase_rc=0
  timeout -k 5s 240s adb shell am instrument -w -r -e sourceSha "$source" -e runUuid "$phase_run" \
    -e class 'com.fluvi.app.lockscreen.material.KeyguardHeaderMaterialViewInstrumentationTest#r22_4ControlledTranslucentProducerAndCompositorPhases' \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$out/$arm/phase-instrumentation.txt" 2>&1 || phase_rc=$?
  printf '%s\n' "$phase_rc" > "$out/$arm/phase-exit.txt"
  adb logcat -b all -d -v monotonic > "$out/$arm/phase-logcat.txt" 2>&1 || true
  adb exec-out run-as com.fluvi.app tar -cf - files/keyguard-material-smoke > "$out/$arm/phase-evidence.tar" 2> "$out/$arm/phase-evidence.stderr" || true
  if [[ "$phase_rc" != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$out/$arm/phase-instrumentation.txt" || ! grep -Eq '^OK \(1 test\)' "$out/$arm/phase-instrumentation.txt"; then failed=1; fi
done
python3 - "$out" <<'PY' > "$out/comparison.json" || failed=1
import json,pathlib,re,statistics,sys,tarfile
root=pathlib.Path(sys.argv[1]); result={}
for arm in ('baseline','candidate'):
    try:
        with tarfile.open(root/arm/'evidence.tar') as archive:
            items=[m for m in archive.getmembers() if m.name.endswith('/r22-3-cadence.txt')]
            assert len(items)==1, 'cadence evidence missing or ambiguous'
            text=archive.extractfile(items[0]).read().decode()
        frames=[]
        for line in text.splitlines():
            m=re.search(r'frameNs=(\d+) submittedMs=(\d+) phase=([^ ]+) slot=(\d+)/(\d+)',line)
            if m: frames.append((int(m[1]),int(m[2]),float(m[3]),int(m[4]),int(m[5])))
        refresh=re.search(r'refreshRate=([0-9.]+)',text)
        assert refresh and float(refresh[1])>0, 'refresh unavailable'
        intervals=[(b[0]-a[0])/1e6 for a,b in zip(frames,frames[1:])]
        assert len(intervals)>=100 and all(x>0 for x in intervals), 'insufficient distinct frames'
        assert len(set(f[2] for f in frames))>=100, 'insufficient distinct phases'
        ordered=sorted(intervals)
        result[arm]={'frames':len(frames),'intervals':len(intervals),'median_ms':statistics.median(intervals),
                     'p95_ms':ordered[(len(ordered)*95+99)//100-1],'worst_ms':ordered[-1],
                     'over50':sum(x>50 for x in intervals),'refresh_hz':float(refresh[1]),
                     'slots':{str(slot):sum(f[3]==slot for f in frames) for slot in sorted(set(f[3] for f in frames))},
                     'terminal_snapshot':next((line for line in text.splitlines() if line.startswith('terminalSnapshot=')),'UNOBSERVED'),
                     'release_fence':'UNOBSERVED in no-op-hook timed sample; see separate phase traces'}
    except Exception as e:
        result[arm]={'status':'NOT_REACHED','reason':str(e)}
base=result['baseline'];candidate=result['candidate']
if 'status' in base or 'status' in candidate:
    result['status']='NOT_REACHED'
else:
    tolerance=1000/base['refresh_hz']
    same=abs(base['refresh_hz']-candidate['refresh_hz'])<0.1
    ok=same and candidate['median_ms']<=base['median_ms']+tolerance and candidate['p95_ms']<=base['p95_ms']+tolerance and candidate['over50']<=base['over50']
    result['status']='PASS' if ok else 'FAIL'
    result['tolerance_ms']=tolerance
print(json.dumps(result,indent=2,sort_keys=True))
if result['status']!='PASS': sys.exit(1)
PY
cat "$out/comparison.json"
exit "$failed"

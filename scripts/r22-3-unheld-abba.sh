#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r22-3-abba"
mkdir -p "$out"
{ adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; adb shell cat /proc/sys/kernel/random/boot_id; adb shell wm size; adb shell wm density; } > "$out/device-before.txt" 2>&1
test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
test "$(adb shell getprop ro.product.cpu.abi | tr -d '\r')" = x86_64
adb shell wm density 420
adb shell settings put system accelerometer_rotation 0
adb shell settings put system user_rotation 0
adb shell wm size | tr -d '\r' | grep -Eq '(^|: )1080x2400$'
failed=0
for spec in 1:baseline 1:candidate 2:candidate 2:baseline; do
 IFS=: read -r block arm <<< "$spec"
 dir="$GITHUB_WORKSPACE/$arm"
 if [[ "$arm" == baseline ]]; then source="$BASE_SHA"; else source="$APP_SHA"; fi
 dest="$out/block-$block-$arm"
 mkdir -p "$dest"
 run=$(python3 -c 'import uuid; print(uuid.uuid4())')
 printf 'source=%s\nblock=%s\narm=%s\nuuid=%s\n' "$source" "$block" "$arm" "$run" > "$dest/identity.txt"
 app="$dir/build/app/outputs/apk/debug/app-debug.apk"
 test_apk="$dir/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk"
 adb shell am force-stop com.fluvi.app > "$dest/force-stop-before.txt" 2>&1 || true
 adb uninstall com.fluvi.app > "$dest/uninstall-before.txt" 2>&1 || true
 rc=0
 adb install -r "$app" > "$dest/install-app.txt" 2>&1 || rc=$?
 adb install -r "$test_apk" > "$dest/install-test.txt" 2>&1 || rc=$?
 if [[ $rc != 0 ]]; then printf 'install_exit=%s\n' "$rc" > "$dest/not-reached.txt"; failed=1; continue; fi
 (cd "$dir" && timeout -k 2s 60s bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app "$app" "$dest" app-before) || failed=1
 (cd "$dir" && timeout -k 2s 60s bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app.test "$test_apk" "$dest" test-before) || failed=1
 if [[ "$block:$arm" == 1:baseline ]]; then
   (cd "$dir" && timeout -k 2s 60s bash scripts/prepare-keyguard-lower-environment.sh "$out/preflight") || failed=1
 fi
 adb logcat -c || true
 adb exec-out screencap -p > "$dest/before-screen.png" 2> "$dest/before-screen.stderr" || true
 remote="/sdcard/fluvi-r22-3-abba-$run.mp4"
 pidfile="/data/local/tmp/fluvi-r22-3-abba-$run.pid"
 adb shell "sh -c 'echo \$\$ > $pidfile; exec screenrecord --verbose --bit-rate 2000000 --time-limit 180 $remote'" > "$dest/recorder.txt" 2>&1 &
 rec_host=$!
 ready=0
 for _ in {1..20}; do
   if adb shell "test -s '$pidfile' && test -s '$remote'" > /dev/null 2>&1; then ready=1; break; fi
   kill -0 "$rec_host" 2>/dev/null || break
   sleep 0.25
 done
 printf 'recorder_started=%s\n' "$ready" > "$dest/recorder-status.txt"
 if [[ $ready != 1 ]]; then failed=1; fi
 rc=0
 timeout -k 5s 260s adb shell am instrument -w -r -e sourceSha "$source" -e runUuid "$run" -e r12Mode SURFACE_LIVE \
   -e class 'com.fluvi.app.lockscreen.KeyguardR12ServiceTimingInstrumentationTest#fourRealWakeCyclesUseRequestedRoute' \
   com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$dest/instrumentation.txt" 2>&1 || rc=$?
 printf '%s\n' "$rc" > "$dest/instrumentation.exit"
 if [[ $rc != 0 ]] || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$dest/instrumentation.txt" || ! grep -Eq '^OK \(1 test\)' "$dest/instrumentation.txt"; then failed=1; fi
 timeout -k 2s 10s adb shell "p=\$(cat '$pidfile' 2>/dev/null); case \"\$(cat /proc/\$p/cmdline 2>/dev/null | tr '\\0' ' ')\" in *fluvi-r22-3-abba-$run*) kill -INT \$p ;; *) exit 1 ;; esac" > "$dest/recorder-signal.txt" 2>&1 || true
 for _ in {1..20}; do kill -0 "$rec_host" 2>/dev/null || break; sleep 0.5; done
 if kill -0 "$rec_host" 2>/dev/null; then kill "$rec_host" 2>/dev/null || true; failed=1; fi
 wait "$rec_host" 2>/dev/null || true
 timeout -k 2s 30s adb pull "$remote" "$dest/recording.mp4" > "$dest/pull-video.txt" 2>&1 || failed=1
 if [[ -s "$dest/recording.mp4" ]]; then sha256sum "$dest/recording.mp4" > "$dest/recording.sha256"; else printf 'video=UNOBSERVED\n' >> "$dest/recorder-status.txt"; failed=1; fi
 timeout -k 2s 30s adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r12-timing/$run" > "$dest/service-probe.tar" 2> "$dest/service-probe.stderr" || failed=1
 timeout -k 2s 30s adb logcat -b all -d -v monotonic > "$dest/logcat.txt" 2>&1 || true
 adb exec-out screencap -p > "$dest/after-screen.png" 2> "$dest/after-screen.stderr" || true
 (cd "$dir" && timeout -k 2s 60s bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app "$app" "$dest" app-after) || failed=1
 (cd "$dir" && timeout -k 2s 60s bash scripts/verify-keyguard-installed-apk.sh com.fluvi.app.test "$test_apk" "$dest" test-after) || failed=1
 adb shell rm -f "$remote" "$pidfile" > "$dest/recorder-cleanup.txt" 2>&1 || true
 cat "$dest/instrumentation.txt"
done
{ adb shell cat /proc/sys/kernel/random/boot_id; adb shell wm size; adb shell wm density; } > "$out/device-after.txt" 2>&1 || true
python3 - "$out" <<'PY' > "$out/slot-inventory.json"
import json,pathlib,re,sys,tarfile
root=pathlib.Path(sys.argv[1]); result={'order':[], 'physical_presentation':'UNOBSERVED','comparison':'NOT_ESTABLISHED_UNTIL_DIRECT_EPISODES_AND_VISUAL_EVIDENCE_ARE_COMPARABLE'}
for block,arm in ((1,'baseline'),(1,'candidate'),(2,'candidate'),(2,'baseline')):
 d=root/f'block-{block}-{arm}'; item={'block':block,'arm':arm,'slots':[]}
 ident=(d/'identity.txt').read_text().splitlines() if (d/'identity.txt').exists() else []
 item['identity']=ident
 try:
  with tarfile.open(d/'service-probe.tar') as a:
   def find(s):
    files=[m for m in a.getmembers() if m.name.endswith('/'+s)]
    return a.extractfile(files[0]).read().decode(errors='replace') if len(files)==1 else ''
   fixture=find('fixture.txt');capture=find('capture.txt')
  core={}
  starts={}
  for line in capture.splitlines():
   m=re.search(r'^ R21_CORE .*?attempt=(\d+)',line)
   if m: core[m[1]]=line.strip()
   m=re.search(r'^attemptId=(\d+).*?wakeCycleStartedAt=(\d+)',line)
   if m: starts[m[1]]=int(m[2])
  triggers={}
  for line in fixture.splitlines():
   m=re.search(r'WAKE_TRIGGER .*name=(cold|warm[123]) wake=(\d+)',line)
   if m: triggers[m[1]]=int(m[2])
  names=('cold','warm1','warm2','warm3')
  for i,name in enumerate(names):
   start=triggers.get(name)
   following=[triggers[n] for n in names[i+1:] if n in triggers]
   end=min(following) if following else None
   attempts=[key for key,at in starts.items() if start is not None and at>=start and (end is None or at<end)]
   row={'name':name,'wake_trigger':start,'associated_attempts':attempts,
        'association':'ONE_ATTEMPT_SAME_UPTIME_INTERVAL' if len(attempts)==1 else ('NO_ATTEMPT' if not attempts else 'MULTIPLE_ATTEMPTS')}
   if len(attempts)==1: row['r21_core']=core.get(attempts[0],'UNOBSERVED')
   item['slots'].append(row)
  item['captured_r21_records']=len(core)
  item['unassociated_core_records']=core
 except Exception as exc:
  item['error']=type(exc).__name__+': '+str(exc)
  item['slots']=[{'name':name,'status':'NOT_REACHED'} for name in ('cold','warm1','warm2','warm3')]
 result['order'].append(item)
print(json.dumps(result,indent=2))
PY
cat "$out/slot-inventory.json"
exit "$failed"

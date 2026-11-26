#!/usr/bin/env bash
# Executed after the real R45 -> signed R46 update. No method-channel or
# instrumentation shortcut starts or freezes the owner recording.
set -euo pipefail
case "$R46_UI_ROUTE" in
  FLUVI_STREAM) label='Fluvi'; route=fluvi;;
  WIDGETS_ANYWHERE) label='Widgets Anywhere'; route=wa;;
  *) printf 'Unknown R46 renderer\n' >&2; exit 2;;
esac
adb install -r "$RUNNER_TEMP/r46-receiver/receiver.apk" > "$out/r46-receiver-install.txt" 2>&1
mkdir -p "$out/r46frames"
result=0
for wakes in 1 3; do
  tap_label "$label" "r448-select-r46-$route-$wakes"
  tap_label 'Felvétel indítása' r46-start
  ack=false
  for attempt in $(seq 1 45); do
    adb shell uiautomator dump /sdcard/r46-ack.xml >/dev/null 2>&1 || true
    adb exec-out cat /sdcard/r46-ack.xml > "$out/ui-r46-$route-$wakes-ack-$attempt.xml" 2>/dev/null || true
    if grep -Fq 'Leállítás és másolás' "$out/ui-r46-$route-$wakes-ack-$attempt.xml"; then ack=true; break; fi
    sleep 1
  done
  if [[ "$ack" != true ]]; then
    printf 'NOT REACHED: actual owner button did not obtain native recording acknowledgement\n' > "$out/r46-$route-$wakes-result.txt"
    exit 1
  fi
  observe "r46-$route-$wakes-after-ack"
  adb shell locksettings set-disabled false > "$out/r46-locksettings.txt" 2>&1
  for cycle in $(seq 1 "$wakes"); do
    adb shell input keyevent KEYCODE_SLEEP
    sleep 1
    # Retain each frame and the surrounding logcat timestamps. These slow
    # screenshots are evidence, not a fabricated 200/500/1000ms pass.
    adb shell "mkdir -p /data/local/tmp/r46frames/$wakes-$cycle; for n in \$(seq 1 24); do log -t R46Optical 'before $wakes $cycle ' \"\$n\"; screencap -p /data/local/tmp/r46frames/$wakes-$cycle/\$n.png; log -t R46Optical 'after $wakes $cycle ' \"\$n\"; sleep 0.01; done" > "$out/r46-stream-$wakes-$cycle.txt" 2>&1 &
    stream=$!
    sleep 0.5
    adb shell input keyevent KEYCODE_WAKEUP
    sleep 5
    adb shell wm dismiss-keyguard || true
    wait "$stream" || true
    sleep 1
  done
  adb pull /data/local/tmp/r46frames/. "$out/r46frames" > "$out/r46-pull-$wakes.txt" 2>&1 || true
  adb logcat -b all -d -v monotonic -s R46Optical:I > "$out/r46-frame-times-$wakes.txt" 2>&1 || true
  adb shell am start -n com.fluvi.app/.MainActivity > "$out/r46-reopen-$wakes.txt" 2>&1
  sleep 2
  adb shell uiautomator dump /sdcard/r46-reopen.xml >/dev/null 2>&1 || true
  adb exec-out cat /sdcard/r46-reopen.xml > "$out/ui-r46-$route-$wakes-reopen.xml" 2>/dev/null || true
  if ! grep -Fq 'Leállítás és másolás' "$out/ui-r46-$route-$wakes-reopen.xml"; then
    tap_label 'Debug log' entry
  fi
  tap_label 'Leállítás és másolás' r46-stop
  copied=false
  for attempt in $(seq 1 30); do
    adb shell uiautomator dump /sdcard/r46-copy.xml >/dev/null 2>&1 || true
    adb exec-out cat /sdcard/r46-copy.xml > "$out/ui-r46-$route-$wakes-copy-$attempt.xml" 2>/dev/null || true
    if grep -Fq 'Riport a vágólapon.' "$out/ui-r46-$route-$wakes-copy-$attempt.xml"; then copied=true; break; fi
    sleep 1
  done
  if [[ "$copied" != true ]]; then
    printf 'FAIL: stop did not confirm clipboard success\n' > "$out/r46-$route-$wakes-result.txt"
    exit 1
  fi
  adb shell am start -n com.fluvi.r46receiver/.PasteActivity > "$out/r46-receiver-launch-$wakes.txt" 2>&1
  tap_label 'Paste report' "r46-paste-$wakes"
  adb exec-out run-as com.fluvi.r46receiver cat files/report.txt > "$out/r46-$route-$wakes-pasted.txt"
  python3 "$GITHUB_WORKSPACE/orchestrator/.github/scripts/r46-check-paste.py" \
    "$out/r46-$route-$wakes-pasted.txt" "$R46_UI_ROUTE" "$wakes" > "$out/r46-$route-$wakes-result.txt" 2>&1 || result=1
  capture=$(sed -n 's/^captureId=\([^ ]*\).*/\1/p' "$out/r46-$route-$wakes-pasted.txt" | head -1)
  [[ "$capture" =~ ^[a-f0-9-]{36}$ ]]
  adb exec-out run-as com.fluvi.app cat "files/r46-recordings/$capture.txt" > "$out/r46-$route-$wakes-sealed.txt"
  if ! cmp "$out/r46-$route-$wakes-sealed.txt" "$out/r46-$route-$wakes-pasted.txt"; then
    printf 'independentReceiverPaste=FAIL\n' >> "$out/r46-$route-$wakes-result.txt"
    result=1
  else
    printf 'independentReceiverPaste=PASS\n' >> "$out/r46-$route-$wakes-result.txt"
  fi
  sha256sum "$out/r46-$route-$wakes-sealed.txt" "$out/r46-$route-$wakes-pasted.txt" >> "$out/r46-$route-$wakes-result.txt"
  printf 'opticalMotion=NOT_QUALIFIED (slow bracketed screenshots retained)\n' >> "$out/r46-$route-$wakes-result.txt"
  adb shell am start -n com.fluvi.app/.MainActivity >/dev/null 2>&1
  sleep 2
  if [[ "$wakes" -eq 1 ]]; then
    adb shell uiautomator dump /sdcard/r46-next.xml >/dev/null 2>&1 || true
    adb exec-out cat /sdcard/r46-next.xml > "$out/ui-r46-next.xml" 2>/dev/null || true
    if ! grep -Fq 'Felvétel indítása' "$out/ui-r46-next.xml"; then tap_label 'Debug log' entry; fi
  fi
done
exit "$result"

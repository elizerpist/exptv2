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

# UiAutomator's ordinary dump can suppress the accessibility service and end
# the very trial being measured. This separate instrumentation requests the
# platform's DONT_SUPPRESS_ACCESSIBILITY_SERVICES flag for active recordings.
r46_dump() {
  local destination=$1
  adb shell run-as com.fluvi.r46receiver rm -f files/tree.xml >/dev/null 2>&1 || true
  adb shell am instrument -w com.fluvi.r46receiver/.TreeDumpInstrumentation > "$out/r46-tree-instrumentation.txt" 2>&1 || return 1
  grep -Fq 'INSTRUMENTATION_CODE: -1' "$out/r46-tree-instrumentation.txt" || return 1
  adb exec-out run-as com.fluvi.r46receiver cat files/tree.xml > "$destination" 2>/dev/null
  test -s "$destination"
}
tap_label() {
  local label=$1 name=$2 coords=''
  for attempt in $(seq 1 25); do
    local xml="$out/ui-$name-$attempt.xml"
    if [[ "$name" == r46-paste-* ]]; then
      adb shell uiautomator dump /sdcard/r46-paste.xml >/dev/null 2>&1 || true
      adb exec-out cat /sdcard/r46-paste.xml > "$xml" 2>/dev/null || true
    else
      r46_dump "$xml" || true
    fi
    coords=$(python3 - "$xml" "$label" <<'PY'
import re,sys,xml.etree.ElementTree as ET
try:
    for n in ET.parse(sys.argv[1]).getroot().iter():
        if not any(sys.argv[2].casefold() in n.attrib.get(k,'').casefold() for k in ('text','content-desc')): continue
        if n.attrib.get('clickable') != 'true' or n.attrib.get('enabled') != 'true': continue
        m=re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',n.attrib.get('bounds',''))
        if m:
            x1,y1,x2,y2=map(int,m.groups())
            if x2>x1 and y2>y1: print((x1+x2)//2,(y1+y2)//2); break
except (ET.ParseError,OSError): pass
PY
)
    if [[ "$coords" =~ ^[0-9]+\ [0-9]+$ ]]; then
      if [[ "$name" == r46-start ]]; then observe before-r46-tap; fi
      adb shell input tap $coords
      return 0
    fi
    sleep 1
  done
  printf 'NOT REACHED: actionable %s\n' "$label" >> "$out/ui-result.txt"
  return 1
}
mkdir -p "$out/r46frames"
result=0
trials=(1 3)
if [[ "${R46_SINGLE:-false}" == true ]]; then trials=(1); fi
if [[ "${R46_LONG:-false}" == true ]]; then trials=(3); fi
for wakes in "${trials[@]}"; do
  tap_label "$label" "r448-select-r46-$route-$wakes"
  tap_label 'Felvétel indítása' r46-start
  ack=false
  for attempt in $(seq 1 45); do
    r46_dump "$out/ui-r46-$route-$wakes-ack-$attempt.xml" || true
    if grep -Fq 'Leállítás és másolás' "$out/ui-r46-$route-$wakes-ack-$attempt.xml"; then ack=true; break; fi
    sleep 1
  done
  if [[ "$ack" != true ]]; then
    printf 'NOT REACHED: actual owner button did not obtain native recording acknowledgement\n' > "$out/r46-$route-$wakes-result.txt"
    exit 1
  fi
  printf 'after_ack ' >> "$out/r46-$route-$wakes-clock.txt"
  adb shell cat /proc/uptime >> "$out/r46-$route-$wakes-clock.txt"
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
    if [[ "${R47_REQUIRE_ACTIVE_HEADER:-false}" == true ]]; then
      sleep 7
      mkdir -p "$out/r46frames/$wakes-$cycle"
      adb exec-out screencap -p > "$out/r46frames/$wakes-$cycle/after-seven-seconds.png" || true
    else
      sleep 5
    fi
    adb shell wm dismiss-keyguard || true
    wait "$stream" || true
    printf 'after_wake_%s ' "$cycle" >> "$out/r46-$route-$wakes-clock.txt"
    adb shell cat /proc/uptime >> "$out/r46-$route-$wakes-clock.txt"
    sleep 1
    if [[ "${R46_LONG:-false}" == true && "$cycle" -eq 1 ]]; then sleep 125; fi
    if [[ "${R46_LONG:-false}" == true && "$cycle" -eq 2 ]]; then sleep 185; fi
  done
  adb pull /data/local/tmp/r46frames/. "$out/r46frames" > "$out/r46-pull-$wakes.txt" 2>&1 || true
  adb logcat -b all -d -v monotonic -s R46Optical:I > "$out/r46-frame-times-$wakes.txt" 2>&1 || true
  python3 "$GITHUB_WORKSPACE/orchestrator/.github/scripts/r46-frame-witness.py" \
    "$out/r46frames" "$out/r46-frame-times-$wakes.txt" "$wakes" "$out/r46-optical-$route-$wakes.json" \
    > "$out/r46-optical-$route-$wakes.txt" 2>&1 || true
  adb shell am start -n com.fluvi.app/.MainActivity > "$out/r46-reopen-$wakes.txt" 2>&1
  sleep 2
  r46_dump "$out/ui-r46-$route-$wakes-reopen.xml" || true
  if ! grep -Fq 'Leállítás és másolás' "$out/ui-r46-$route-$wakes-reopen.xml"; then
    tap_label 'Debug log' entry
  fi
  tap_label 'Leállítás és másolás' r46-stop
  copied=false
  for attempt in $(seq 1 30); do
    r46_dump "$out/ui-r46-$route-$wakes-copy-$attempt.xml" || true
    if grep -Fq 'Riport a vágólapon.' "$out/ui-r46-$route-$wakes-copy-$attempt.xml"; then copied=true; break; fi
    sleep 1
  done
  if [[ "$copied" != true ]]; then
    printf 'FAIL: stop did not confirm clipboard success\n' > "$out/r46-$route-$wakes-result.txt"
    exit 1
  fi
  # Preserve the immutable native report even if the independent receiver
  # itself fails to start or paste; it is not counted as a paste result.
  adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_r46_recording.xml > "$out/r46-$route-$wakes-prefs.xml"
  capture=$(python3 - "$out/r46-$route-$wakes-prefs.xml" <<'PY'
import sys,xml.etree.ElementTree as ET
root=ET.parse(sys.argv[1]).getroot()
print(next((n.text or '' for n in root if n.attrib.get('name') == 'id'), ''))
PY
)
  [[ "$capture" =~ ^[a-f0-9-]{36}$ ]]
  adb exec-out run-as com.fluvi.app cat "files/r46-recordings/$capture.txt" > "$out/r46-$route-$wakes-sealed.txt"
  adb shell run-as com.fluvi.r46receiver rm -f files/report.txt >/dev/null 2>&1 || true
  adb shell am start -n com.fluvi.r46receiver/.PasteActivity > "$out/r46-receiver-launch-$wakes.txt" 2>&1
  tap_label 'Paste report' "r46-paste-$wakes"
  pasted=false
  for attempt in $(seq 1 20); do
    if adb shell run-as com.fluvi.r46receiver test -s files/report.txt >/dev/null 2>&1; then
      adb exec-out run-as com.fluvi.r46receiver cat files/report.txt > "$out/r46-$route-$wakes-pasted.txt"
      pasted=true
      break
    fi
    sleep 1
  done
  if [[ "$pasted" != true ]]; then
    adb shell uiautomator dump /sdcard/r46-paste-result.xml >/dev/null 2>&1 || true
    adb exec-out cat /sdcard/r46-paste-result.xml > "$out/ui-r46-paste-result-$wakes.xml" 2>/dev/null || true
    printf 'NOT REACHED: independent receiver did not persist pasted text\n' > "$out/r46-$route-$wakes-result.txt"
    exit 1
  fi
  python3 "$GITHUB_WORKSPACE/orchestrator/.github/scripts/r46-check-paste.py" \
    "$out/r46-$route-$wakes-pasted.txt" "$R46_UI_ROUTE" "$wakes" > "$out/r46-$route-$wakes-result.txt" 2>&1 || result=1
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
    r46_dump "$out/ui-r46-next.xml" || true
    if ! grep -Fq 'Felvétel indítása' "$out/ui-r46-next.xml"; then tap_label 'Debug log' entry; fi
  fi
done
exit "$result"

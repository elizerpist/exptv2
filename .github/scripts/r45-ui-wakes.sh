#!/usr/bin/env bash
# Sourced by r44-update.sh after the genuine signed update and real debug UI.
# A receipt alone is never an optical pass. Raw frames remain private artifacts.
case "$R45_UI_ROUTE" in
  FLUVI_STREAM) route_label='Fluvi adatfolyam'; route_name=fluvi;;
  WIDGETS_ANYWHERE) route_label='Widgets Anywhere'; route_name=wa;;
  *) printf 'Unknown R45 route\n' >&2; exit 2;;
esac
if [[ "$R45_UI_ROUTE" == FLUVI_STREAM ]]; then
  tap_label 'Widgets Anywhere' r448-select-wa
fi
tap_label "$route_label" "r448-select-$route_name"
if [[ "$R45_UI_SHAPE" == CIRCLE ]]; then
  tap_label 'Kontrasztpróba: tömör kör' r45-shape
fi
if [[ "$R45_UI_ACTION" == SESSION ]]; then
  tap_label "Mintaorb több ébresztésnél · 2 perc – $route_label" r45-action
  wakes=3
else
  tap_label "Egyszeri mintaorb és rögzítés – $route_label" r45-action
  wakes=1
fi
sleep 6
adb exec-out screencap -p > "$out/r45-$route_name-prewake.png" || true
adb shell locksettings set-disabled false > "$out/r45-locksettings.txt" 2>&1
mkdir -p "$out/r45frames"
for cycle in $(seq 1 "$wakes"); do
  adb shell input keyevent KEYCODE_SLEEP
  sleep 1
  # Keep all samples and their bounds, but do not spend the two-minute
  # session on 80 slow PNG captures before starting the next wake.
  adb shell "mkdir -p /data/local/tmp/r45frames/$cycle; for n in \$(seq 1 24); do log -t R45Optical 'before $cycle ' \"\$n\"; screencap -p /data/local/tmp/r45frames/$cycle/\$n.png; log -t R45Optical 'after $cycle ' \"\$n\"; sleep 0.01; done" > "$out/r45-stream-$cycle.txt" 2>&1 &
  stream_pid=$!
  sleep 0.5
  adb shell input keyevent KEYCODE_WAKEUP
  # A real admission can complete seconds after SCREEN_ON. Do not force an
  # unlock before the sample has had a chance to use its own two-second cap.
  sleep 5
  adb exec-out screencap -p > "$out/r45-$route_name-wake-$cycle.png" || true
  adb shell wm dismiss-keyguard || true
  wait "$stream_pid" || true
  sleep 1
done
adb pull /data/local/tmp/r45frames/. "$out/r45frames" > "$out/r45-pull.txt" 2>&1 || true
adb logcat -b all -d -v monotonic -s R45Optical:I > "$out/r45-frame-times.txt" 2>&1 || true
adb shell am start -n com.fluvi.app/.MainActivity > "$out/r45-reopen.txt" 2>&1
adb shell uiautomator dump /sdcard/r45-reopen.xml > /dev/null 2>&1 || true
adb exec-out cat /sdcard/r45-reopen.xml > "$out/ui-r45-reopen.xml" 2>/dev/null || true
if ! grep -Fq 'ZÁRKÉPERNYŐ' "$out/ui-r45-reopen.xml"; then tap_label 'Debug log' entry; fi
tap_label 'ZÁRKÉPERNYŐ' tab
tap_label 'leállítás' r449-freeze
for attempt in $(seq 1 30); do
  adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_keyguard_r448_comparison.xml > "$out/r45-comparison.xml" 2>/dev/null || true
  if python3 - "$out/r45-comparison.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
try: ET.parse(sys.argv[1])
except (ET.ParseError,OSError): sys.exit(1)
PY
  then break; fi
  sleep 1
done
python3 - "$out/r45-comparison.xml" "$R45_UI_ROUTE" "$R45_UI_ACTION" "$R45_UI_SHAPE" "$wakes" > "$out/r45-result.txt" <<'PY'
import sys, xml.etree.ElementTree as ET
path, route, action, shape, expected = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5])
try:
    root=ET.parse(path).getroot()
    report=next((e.text or '' for e in root if e.attrib.get('name') == route), '')
    rows=[s for s in report.splitlines() if s.startswith('R44_9_OUTCOME ')]
    lives=[s for s in report.splitlines() if s.startswith('R45_LIFECYCLE ')]
    print('route=',route,'action=',action,'shape=',shape,'required_wakes=',expected)
    print('\n'.join(rows)); print('\n'.join(lives))
    assert any('routeConfirmed='+route in s and 'action='+action in s for s in rows), 'NOT REACHED: native route/action receipt'
    relevant=[s for s in lives if 'route='+route in s and 'shape='+shape in s]
    errors=[]
    if len(relevant) < expected:
        errors.append('NOT REACHED: fewer protected lifecycle rows than requested wakes')
    for s in relevant:
        if 'reveal=UNOBSERVED' in s or 'firstDraw=UNOBSERVED' in s:
            errors.append('FAIL: the selected backend did not reach both reveal and real View draw')
        if shape == 'ORB' and 'firstShader=UNOBSERVED' in s:
            errors.append('FAIL: no first real shader observation')
    print('\n'.join(errors))
    if errors: raise SystemExit(2)
except (ET.ParseError, OSError, AssertionError) as error:
    print('NOT REACHED:',error)
    raise SystemExit(1)
PY
python3 "$GITHUB_WORKSPACE/orchestrator/.github/scripts/r45-optics.py" "$out/r45-optical-witness.json" "$wakes" | tee -a "$out/r45-result.txt"

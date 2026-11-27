#!/usr/bin/env bash
set -euo pipefail
out=evidence/preflight
mkdir -p "$out"
adb shell getprop ro.build.fingerprint > "$out/fingerprint.txt"
adb shell perfetto --query > "$out/perfetto-sources.txt"
adb shell screenrecord --help > "$out/screenrecord-help.txt" 2>&1 || true
ffmpeg -version > "$out/decoder.txt"
ffprobe -version >> "$out/decoder.txt"
adb shell wm size > "$out/display.txt"
adb shell wm density >> "$out/display.txt"
adb shell input keyevent KEYCODE_WAKEUP
adb shell wm dismiss-keyguard
adb shell am start -W -a android.settings.SETTINGS
adb shell 'cat /proc/uptime; dumpsys power | grep -E "mWakefulness=|Display Power: state="; dumpsys display | grep -m 2 "state ON"' > "$out/power-on.txt"
adb shell screenrecord --bit-rate 3000000 --time-limit 8 --size 540x1200 /data/local/tmp/r52-cal.mp4 > "$out/record.log" 2>&1 &
record=$!
sleep 2
adb shell 'cat /proc/uptime; input keyevent KEYCODE_HOME; cat /proc/uptime' > "$out/action.txt"
sleep 2
adb shell input keyevent KEYCODE_SLEEP
adb shell 'cat /proc/uptime; dumpsys power | grep -E "mWakefulness=|Display Power: state="; dumpsys display | grep -m 2 "state OFF"' > "$out/power-off.txt"
wait "$record"
adb pull /data/local/tmp/r52-cal.mp4 "$out/calibration.mp4"
bash .github/r52-stock/decode.sh "$out"

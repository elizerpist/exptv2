#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r44-update"
mkdir -p "$out"
case "${R44_BASELINE:-r44_2_owner}" in
  r44_5)
    base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/d2063820c056251d3b653b4068673c635bb3bc08/fluvi_R44_5_HUMAN_7c3caaffd2bd.apk'
    base_size=121252624
    base_sha=14ab71a908d94600ac3d0e2c57c8e59808a8a2940a121955cc107cca6c0a3bc3;;
  r44_4)
    base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/84763fd4fa820b6e0fdb2ad5c7b4d5716ba20f1b/fluvi_R44_4_HUMAN_157539474803.apk'
    base_size=121236240
    base_sha=ccbc29660930b76a97c36a919a9b5eea772eee4725063224f39af385926d66c3;;
  r44_1)
    base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/1f842db6394e0a44904133ae4825820cf61418f7/Fluvi_R44.1_HUMAN_1cd0b8fb31f6.apk'
    base_size=121072400
    base_sha=58915a3a0161b9132af821a72c789fb00c266f047c052ec597bd57af7f523b9c;;
  r44_3)
    base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/86d98402ff3f72be47fa52a29e97bfff025843e0/fluvi_R44_3_HUMAN_7dd17596cf2b.apk'
    base_size=121203472
    base_sha=4831c948c5db7416d921f7bb67f9fd541ea2e1758006a41f33885d0ebdcdbfdf;;
  r44_2_owner)
    base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/22ce8d1c96ec2e11cc3a6a8321c50849223a5edc/fluvi_R44_2_HUMAN_3c6618400e54.apk'
    base_size=121170704
    base_sha=3fbd2c77c36125a2ecd1e8144b285b5f70f9f86994cbc7a55c8215d6575af31d;;
  r44_2_successor)
    base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/d8c099290874ea2c9b8b4b88615acb993aeb281e/fluvi_R44_2_HUMAN_31df90e7dc83.apk'
    base_size=121170704
    base_sha=e62fa8ce52aae4ee1b06fe3705fe57c24ff5a6b70bee5004d4ab1cb25906eb76;;
  *) printf 'unrecognised baseline\n' >&2; exit 2;;
esac
case "$1" in
  prepare)
    [[ "$APP_SHA" =~ ^[0-9a-f]{40}$ && "$CANDIDATE_SHA256" =~ ^[0-9a-f]{64}$ && "$CANDIDATE_SIZE" =~ ^[0-9]+$ ]]
    if [[ "${R44_PRIVATE:-false}" == true ]]; then
      test -s "$out/r43.apk"
      test -s "$out/r44.apk"
    else
    curl -fLsS --retry 3 "$base_url" -o "$out/r43.apk"
    test "$(wc -c < "$out/r43.apk")" -eq "$base_size"
    printf '%s  %s\n' "$base_sha" "$out/r43.apk" | sha256sum -c -
    case "$CANDIDATE_URL" in
      https://media.githubusercontent.com/media/elizerpist/exptv2/*/*.zstpatch.enc)
        [[ "$R44_STAGE_SHA256" =~ ^[0-9a-f]{64}$ && "$R44_STAGE_SIZE" =~ ^[0-9]+$ && -n "${FLUVI_R44_STAGE_KEY:-}" ]]
        curl -fLsS --retry 3 "$CANDIDATE_URL" -o "$out/stage.enc"
        test "$(wc -c < "$out/stage.enc")" -eq "$R44_STAGE_SIZE"
        printf '%s  %s\n' "$R44_STAGE_SHA256" "$out/stage.enc" | sha256sum -c -
        openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass env:FLUVI_R44_STAGE_KEY -in "$out/stage.enc" -out "$out/r44.zstpatch"
        zstd -q -d --patch-from="$out/r43.apk" -f "$out/r44.zstpatch" -o "$out/r44.apk"
        ;;
      https://media.githubusercontent.com/media/elizerpist/exptv2/*/*.apk)
        curl -fLsS --retry 3 "$CANDIDATE_URL" -o "$out/r44.apk"
        ;;
      *) printf '%s\n' 'unsupported candidate source' >&2; exit 2;;
    esac
    fi
    test "$(wc -c < "$out/r43.apk")" -eq "$base_size"
    printf '%s  %s\n' "$base_sha" "$out/r43.apk" | sha256sum -c -
    test "$(wc -c < "$out/r44.apk")" -eq "$CANDIDATE_SIZE"
    printf '%s  %s\n' "$CANDIDATE_SHA256" "$out/r44.apk" | sha256sum -c -
    signer=$(find "$ANDROID_HOME/build-tools" -mindepth 2 -maxdepth 2 -name apksigner -type f | sort -V | tail -1)
    for name in r43 r44; do
      "$signer" verify --verbose --print-certs "$out/$name.apk" > "$out/$name-signature.txt"
      grep -Fqi faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb "$out/$name-signature.txt"
      unzip -tq "$out/$name.apk" > "$out/$name-zip.txt"
    done
    for abi in armeabi-v7a arm64-v8a x86_64; do
      unzip -p "$out/r44.apk" "lib/$abi/libapp.so" > "$out/libapp.so"
      grep -aqF "$APP_SHA" "$out/libapp.so"
      grep -aqF HUMAN_DIAGNOSTIC "$out/libapp.so"
      printf '%s exact source/purpose PASS\n' "$abi" >> "$out/embedded.txt"
    done
    rm "$out/libapp.so"
    ;;
  run)
    trap 'adb logcat -b all -d -v monotonic > "$out/logcat.txt" 2>&1 || true' EXIT
    { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.build.fingerprint; } > "$out/device.txt"
    test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 37
    adb install "$out/r43.apk" > "$out/install-r43.txt" 2>&1
    adb shell am force-stop com.fluvi.app
    cat > "$out/seed.xml" <<'XML'
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
  <boolean name="requested" value="true" />
  <boolean name="details" value="true" />
  <string name="presentationMode">orb</string>
  <string name="animationMode">orbOnly</string>
  <boolean name="focusMigrated" value="true" />
  <string name="focus.mode">budget</string>
  <string name="focus.axis">month</string>
  <string name="focus.direction">expense</string>
  <string name="focus.categoryId">r44-synthetic-category</string>
  <string name="focus.eventLine">related</string>
  <long name="focus.generation" value="7" />
</map>
XML
    printf '%s\n' 'r44-update-sentinel' > "$out/sentinel.txt"
    adb push "$out/seed.xml" /data/local/tmp/r44-seed.xml > /dev/null
    adb push "$out/sentinel.txt" /data/local/tmp/r44-sentinel.txt > /dev/null
    adb shell 'run-as com.fluvi.app sh -c "mkdir -p files shared_prefs; cp /data/local/tmp/r44-seed.xml shared_prefs/fluvi_native_keyguard_card.xml; cp /data/local/tmp/r44-sentinel.txt files/r44-update-sentinel.txt"'
    # force-stop above protects the seeded preferences but leaves the package
    # stopped. Launch the original app before asking Android to bind its
    # accessibility service; otherwise the pre-update service is unreachable.
    adb shell am start -n com.fluvi.app/.MainActivity > "$out/launch-before.txt" 2>&1
    component='com.fluvi.app/com.fluvi.app.lockscreen.FluviKeyguardCardService'
    adb shell settings put secure enabled_accessibility_services "$component"
    adb shell settings put secure accessibility_enabled 1
    observe() {
      local label=$1 ok=false pid
      for _ in $(seq 1 60); do
        adb shell dumpsys activity services "$component" > "$out/service-$label.txt" 2>&1 || true
        adb shell dumpsys accessibility > "$out/accessibility-$label.txt" 2>&1 || true
        # The accessibility service binds asynchronously after its setting is
        # enabled or the package is replaced. A missing PID is a retryable
        # observation, not a shell error that should abort the first poll.
        pid=$(adb shell pidof com.fluvi.app 2>/dev/null | tr -d '\r' | awk '{print $1}' || true)
        if [[ "$pid" =~ ^[0-9]+$ ]] && grep -Fq 'com.fluvi.app/.lockscreen.FluviKeyguardCardService' "$out/service-$label.txt" &&
            grep -Eq "app=ProcessRecord\\{[^}]*[[:space:]]${pid}:com[.]fluvi[.]app/" "$out/service-$label.txt" &&
            grep -Fq 'Bound services:{Service[label=Fluvi' "$out/accessibility-$label.txt"; then ok=true; break; fi
        sleep 0.5
      done
      adb shell settings get secure enabled_accessibility_services > "$out/enabled-$label.txt"
      "$ok" && grep -Fq "$component" "$out/enabled-$label.txt"
    }
    bound_before=true
    if ! observe before; then
      # On a fresh emulator install the asynchronous package monitor can
      # remove the secure setting we wrote before it has registered the app.
      # Preserve that observation and re-arm only the disposable pre-update
      # fixture when the setting is demonstrably absent. Never repair it after
      # install -r: the candidate must preserve the real enabled service.
      initial_setting=$(tr -d '\r' < "$out/enabled-before.txt")
      printf 'initial_before_setting=%s initial_bind=NOT_REACHED\n' "$initial_setting" >> "$out/service-gate.txt"
      if [[ "$initial_setting" == null || -z "$initial_setting" ]]; then
        adb shell settings put secure enabled_accessibility_services "$component"
        adb shell settings put secure accessibility_enabled 1
        if observe before-rearm; then
          printf '%s\n' 'Pre-update fixture re-armed after Android removed its initial setting; original service observed bound.' >> "$out/service-gate.txt"
        else
          bound_before=false
        fi
      else
        bound_before=false
      fi
      if [[ "$bound_before" != true ]]; then
        printf '%s\n' 'NOT REACHED: original accessibility service was not observed bound before update.' >> "$out/service-gate.txt"
      fi
    fi
    adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$out/prefs-before.xml"
    adb exec-out run-as com.fluvi.app cat files/r44-update-sentinel.txt > "$out/sentinel-before.txt"
    adb install -r "$out/r44.apk" > "$out/install-r44.txt" 2>&1
    bound_after=true
    if ! observe after; then
      bound_after=false
      printf '%s\n' 'NOT REACHED: accessibility service was not observed bound after update.' >> "$out/service-gate.txt"
    fi
    adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$out/prefs-after.xml"
    adb exec-out run-as com.fluvi.app cat files/r44-update-sentinel.txt > "$out/sentinel-after.txt"
    python3 - "$out/seed.xml" "$out/prefs-before.xml" "$out/prefs-after.xml" > "$out/settings-check.txt" <<'PY'
import sys,xml.etree.ElementTree as ET
def values(p):
    return {n.attrib['name']:(n.tag,n.attrib.get('value',n.text or '')) for n in ET.parse(p).getroot()}
seed,before,after=map(values,sys.argv[1:])
for name,expected in seed.items():
    assert before.get(name)==expected and after.get(name)==expected, name
    print(name, 'PASS')
PY
    cmp "$out/sentinel.txt" "$out/sentinel-before.txt"
    cmp "$out/sentinel.txt" "$out/sentinel-after.txt"
    printf '%s\n' 'PASS: genuine signed selected baseline to candidate install -r; synthetic preferences and sentinel survived on API 37.' > "$out/result.txt"
    printf 'bound_before=%s bound_after=%s\n' "$bound_before" "$bound_after" >> "$out/service-gate.txt"
    if [[ "${R44_REOPEN_ONLY:-false}" == true ]]; then
      # Independent activity reopen control: no UiAutomator connection and no
      # forced package stop; the preceding run covers the trial and freeze.
      [[ "$bound_before" == true && "$bound_after" == true ]]
      adb shell am start -n com.fluvi.app/.MainActivity > "$out/reopen-first.txt" 2>&1
      adb shell input keyevent KEYCODE_BACK
      adb shell am start -n com.fluvi.app/.MainActivity > "$out/reopen-second.txt" 2>&1
      observe reopened
      adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$out/prefs-reopened.xml"
      adb exec-out run-as com.fluvi.app cat files/r44-update-sentinel.txt > "$out/sentinel-reopened.txt"
      cmp "$out/sentinel.txt" "$out/sentinel-reopened.txt"
      python3 - "$out/seed.xml" "$out/prefs-reopened.xml" >> "$out/settings-check.txt" <<'PY'
import sys,xml.etree.ElementTree as ET
def values(p):
    return {n.attrib['name']:(n.tag,n.attrib.get('value',n.text or '')) for n in ET.parse(p).getroot()}
seed,after=map(values,sys.argv[1:])
for name,expected in seed.items():
    assert after.get(name)==expected, name
    print(name, 'REOPEN PASS')
PY
      printf '%s\n' 'PASS: normal activity reopen preserved settings, sentinel and the enabled bound service.' >> "$out/result.txt"
      exit 0
    fi
    # Exercise the control in the installed signed profile. A missing semantic
    # node, startup crash or unacknowledged action is an explicit failure, not
    # evidence from the debug test APK or from a different source.
    adb shell input keyevent KEYCODE_WAKEUP
    adb shell wm dismiss-keyguard || true
    adb shell am start -n com.fluvi.app/.MainActivity > "$out/launch.txt" 2>&1
    scroll_controls() {
      local xml=$1 direction=$2 points
      points=$(python3 - "$xml" "$direction" <<'PY'
import re,sys,xml.etree.ElementTree as ET
try:
    for n in ET.parse(sys.argv[1]).getroot().iter():
        if n.attrib.get('scrollable') != 'true': continue
        m=re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',n.attrib.get('bounds',''))
        if not m: continue
        a,b,c,d=map(int,m.groups())
        if d-b < 100: continue
        x=(a+c)//2; hi=b+(d-b)//5; lo=d-(d-b)//5
        print(x,lo if sys.argv[2]=='down' else hi,x,hi if sys.argv[2]=='down' else lo)
        break
except (ET.ParseError,OSError): pass
PY
)
      if [[ "$points" =~ ^[0-9]+\ [0-9]+\ [0-9]+\ [0-9]+$ ]]; then
        adb shell input swipe $points 350 || true
      fi
    }
    tap_label() {
      local label=$1 name=$2 coords=''
      for attempt in $(seq 1 12); do
        adb shell uiautomator dump /sdcard/r442-window.xml > /dev/null 2>&1 || true
        adb exec-out cat /sdcard/r442-window.xml > "$out/ui-$name.xml" 2>/dev/null || true
        coords=$(python3 - "$out/ui-$name.xml" "$label" <<'PY'
import re,sys,xml.etree.ElementTree as ET
try:
    root=ET.parse(sys.argv[1]).getroot()
    for n in root.iter():
        if any(sys.argv[2] in n.attrib.get(k,'') for k in ('text','content-desc')):
            m=re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',n.attrib.get('bounds',''))
            if m:
                a,b,c,d=map(int,m.groups()); print((a+c)//2,(b+d)//2); break
except (ET.ParseError,OSError): pass
PY
)
        if [[ "$coords" =~ ^[0-9]+\ [0-9]+$ ]]; then
          adb shell input tap $coords
          return 0
        fi
        if (( attempt > 3 )); then scroll_controls "$out/ui-$name.xml" down; fi
        sleep 1
      done
      printf 'NOT REACHED: %s\n' "$label" >> "$out/ui-result.txt"
      return 1
    }
    tap_label 'Debug log' entry
    tap_label 'ZÁRKÉPERNYŐ' tab
    adb shell dumpsys accessibility > "$out/accessibility-normal.txt" 2>&1 || true
    tap_label 'Mintaorb kipróbálása és rögzítés' action
    receipt=false
    for attempt in $(seq 1 12); do
      adb shell uiautomator dump /sdcard/r442-window.xml > /dev/null 2>&1 || true
      adb exec-out cat /sdcard/r442-window.xml > "$out/ui-receipt.xml" 2>/dev/null || true
      if grep -Fq 'Mintaorb-próba aktív' "$out/ui-receipt.xml" &&
          grep -Fq 'Szokásos nézetprofil visszaigazolva' "$out/ui-receipt.xml"; then
        printf '%s\n' 'PASS: signed profile primary control returned an active native standard-profile sample receipt.' > "$out/ui-result.txt"
        receipt=true
        break
      fi
      # The active receipt is below the start button in this scroll view.
      # The previous control moved toward the top and left the receipt just
      # outside the viewport even though the signed capture was recording.
      if (( attempt > 1 )); then scroll_controls "$out/ui-receipt.xml" down; fi
      sleep 1
    done
    if [[ "$receipt" != true ]]; then
      printf '%s\n' 'FAIL: no active standard sample receipt observed after the signed profile action.' > "$out/ui-result.txt"
      exit 1
    fi
    adb shell dumpsys accessibility > "$out/accessibility-expanded.txt" 2>&1 || true
    tap_label 'Próba leállítása és riport megtartása' freeze
    frozen_state=false
    for attempt in $(seq 1 12); do
      adb shell uiautomator dump /sdcard/r442-window.xml > /dev/null 2>&1 || true
      adb exec-out cat /sdcard/r442-window.xml > "$out/ui-frozen-state.xml" 2>/dev/null || true
      if python3 - "$out/ui-frozen-state.xml" <<'PY'
import sys,xml.etree.ElementTree as ET
try:
    values=[n.attrib.get(k,'') for n in ET.parse(sys.argv[1]).getroot().iter() for k in ('text','content-desc')]
    assert any(s.startswith('FROZEN ·') for s in values)
except (AssertionError,ET.ParseError,OSError):
    sys.exit(1)
PY
      then frozen_state=true; break; fi
      scroll_controls "$out/ui-frozen-state.xml" down
      sleep 1
    done
    "$frozen_state" || { printf '%s\n' 'FAIL: frozen native capture state was not observed after stop.' >> "$out/ui-result.txt"; exit 1; }
    frozen=false
    for attempt in $(seq 1 12); do
      adb shell uiautomator dump /sdcard/r442-window.xml > /dev/null 2>&1 || true
      adb exec-out cat /sdcard/r442-window.xml > "$out/ui-frozen.xml" 2>/dev/null || true
      if ! grep -Fq 'Mintaorb-próba aktív' "$out/ui-frozen.xml" &&
          grep -Fq 'Mintaorb kipróbálása és rögzítés' "$out/ui-frozen.xml"; then
        frozen=true; break
      fi
      scroll_controls "$out/ui-frozen.xml" up
      sleep 1
    done
    "$frozen" || { printf '%s\n' 'FAIL: inactive sample control was not observed after freeze.' >> "$out/ui-result.txt"; exit 1; }
    adb shell dumpsys accessibility > "$out/accessibility-restored.txt" 2>&1 || true
    printf '%s\n' 'PASS: stop/freeze returned to the inactive sample control; service snapshots retained for flag inspection.' >> "$out/ui-result.txt"
    # Reopen through the ordinary user flow. Force-stop is not an activity
    # close: on this API 37 image it removed the enabled accessibility
    # service and made the subsequent rebind check test a different action.
    adb shell input keyevent KEYCODE_BACK
    adb shell input keyevent KEYCODE_BACK
    adb shell am start -n com.fluvi.app/.MainActivity > "$out/reopen.txt" 2>&1
    observe reopened
    adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$out/prefs-reopened.xml"
    adb exec-out run-as com.fluvi.app cat files/r44-update-sentinel.txt > "$out/sentinel-reopened.txt"
    cmp "$out/sentinel.txt" "$out/sentinel-reopened.txt"
    python3 - "$out/seed.xml" "$out/prefs-reopened.xml" >> "$out/settings-check.txt" <<'PY'
import sys,xml.etree.ElementTree as ET
def values(p):
    return {n.attrib['name']:(n.tag,n.attrib.get('value',n.text or '')) for n in ET.parse(p).getroot()}
seed,after=map(values,sys.argv[1:])
for name,expected in seed.items():
    assert after.get(name)==expected, name
    print(name, 'REOPEN PASS')
PY
    [[ "$bound_before" == true && "$bound_after" == true ]]
    ;;
  *) exit 2;;
esac

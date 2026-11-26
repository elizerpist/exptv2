#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r44-update"
mkdir -p "$out"
case "${R44_BASELINE:-r44_2_owner}" in
  r44_8)
    base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/a67dfc8d207a254a4b14b9abfa8cdfe4ec223c85/fluvi_R44_8_SAMPLE_ONLY_HUMAN_adf87004bde3.apk'
    base_size=121371601
    base_sha=4ead8ab16911bd30a920690a167483e1b47ae3afb1fc03cdc27b8b293097728c;;
  r44_7)
    base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/32f179cc771e430487a045b7b7d034dd6a297d13/fluvi_R44_7_HUMAN_ee8528501758.apk'
    base_size=121301776
    base_sha=776c6297f34a2bd1d0c74f2a04ff431c0f883a33bb7b6fd7fbda6700e5c099d8;;
  r44_6)
    base_url='https://media.githubusercontent.com/media/elizerpist/exptv2/7833606f902c43131f90f1948fd56e2620af13ec/fluvi_R44_6_HUMAN_398a53891f3a.apk'
    base_size=121285392
    base_sha=2d1d0721cb09ef3742b00850cd570471097d54dc2ecc8cb3935b5004e9b13b79;;
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
      local xml=$1 direction=$2 points precision=${3:-normal}
      points=$(python3 - "$xml" "$direction" "$precision" <<'PY'
import re,sys,xml.etree.ElementTree as ET
try:
    for n in ET.parse(sys.argv[1]).getroot().iter():
        if n.attrib.get('scrollable') != 'true': continue
        m=re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',n.attrib.get('bounds',''))
        if not m: continue
        a,b,c,d=map(int,m.groups())
        if d-b < 100: continue
        x=(a+c)//2
        hi=b+(d-b)*(2 if sys.argv[3]=='fine' else 1)//5
        lo=b+(d-b)*(3 if sys.argv[3]=='fine' else 4)//5
        print(x,lo if sys.argv[2]=='down' else hi,x,hi if sys.argv[2]=='down' else lo)
        break
except (ET.ParseError,OSError): pass
PY
)
      if [[ "$points" =~ ^[0-9]+\ [0-9]+\ [0-9]+\ [0-9]+$ ]]; then
        adb shell input swipe $points 350 || true
      fi
    }
    wait_for_system_anr() {
      local xml=$1 phase=$2 wait_coords=''
      if ! grep -Fq "Quickstep isn't responding" "$xml" && ! grep -Fq "System UI isn't responding" "$xml"; then
        return 1
      fi
      # Keep each observed Android system dialog. This is only fixture
      # recovery; selecting Wait never satisfies a Fluvi UI assertion.
      cp "$xml" "$out/ui-system-anr-$phase.xml"
      wait_coords=$(python3 - "$xml" <<'PY'
import re,sys,xml.etree.ElementTree as ET
try:
    for n in ET.parse(sys.argv[1]).getroot().iter():
        if n.attrib.get('resource-id') != 'android:id/aerr_wait': continue
        m=re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',n.attrib.get('bounds',''))
        if m:
            a,b,c,d=map(int,m.groups()); print((a+c)//2,(b+d)//2); break
except (ET.ParseError,OSError): pass
PY
)
      [[ "$wait_coords" =~ ^[0-9]+\ [0-9]+$ ]] || return 1
      printf 'System ANR at %s; selected Wait.\n' "$phase" >> "$out/ui-environment.txt"
      adb shell input tap $wait_coords
      sleep 2
      return 0
    }
    tap_label() {
      local label=$1 name=$2 coords=''
      for attempt in $(seq 1 20); do
        adb shell uiautomator dump /sdcard/r442-window.xml > /dev/null 2>&1 || true
        adb exec-out cat /sdcard/r442-window.xml > "$out/ui-$name.xml" 2>/dev/null || true
        if [[ "$name" == r448-select-* || "$name" == r449-action || "$name" == r449-freeze ]]; then
          cp "$out/ui-$name.xml" "$out/ui-$name-$attempt.xml" || true
        fi
        if wait_for_system_anr "$out/ui-$name.xml" "$name-$attempt"; then
          if [[ "$name" == entry ]]; then adb shell am start -n com.fluvi.app/.MainActivity >> "$out/launch.txt" 2>&1 || true; fi
          continue
        fi
        if [[ "$name" == entry && "${R448_RESTART_PROBE:-false}" == true ]] &&
            grep -Fq 'package="com.android.launcher3"' "$out/ui-$name.xml"; then
          # The first start can be delivered to a dying top activity while
          # Android is replacing its process. Retry only after the hierarchy
          # positively shows the launcher, not after an app assertion.
          adb shell am start -n com.fluvi.app/.MainActivity >> "$out/restart-r448.txt" 2>&1 || true
          sleep 2
          continue
        fi
        coords=$(python3 - "$out/ui-$name.xml" "$label" "$name" <<'PY'
import re,sys,xml.etree.ElementTree as ET
try:
    root=ET.parse(sys.argv[1]).getroot()
    for n in root.iter():
        if any((sys.argv[2].casefold() in n.attrib.get(k,'').casefold() if sys.argv[3] == 'r449-freeze'
                else sys.argv[2] in n.attrib.get(k,'')) for k in ('text','content-desc')):
            # A clipped or temporarily loading Flutter choice can still be
            # exposed by semantics while it is not actionable. Never count a
            # tap on that node as a route-selection attempt.
            if sys.argv[3].startswith('r448-select-') and (n.attrib.get('clickable') != 'true' or n.attrib.get('enabled') != 'true'):
                continue
            if sys.argv[3] == 'r449-action' and (n.attrib.get('clickable') != 'true' or n.attrib.get('enabled') != 'true'):
                continue
            if sys.argv[3] == 'r449-freeze' and (n.attrib.get('clickable') != 'true' or n.attrib.get('enabled') != 'true'):
                continue
            m=re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',n.attrib.get('bounds',''))
            if m:
                a,b,c,d=map(int,m.groups()); print((a+c)//2,(b+d)//2); break
except (ET.ParseError,OSError): pass
PY
)
        if [[ "$coords" =~ ^[0-9]+\ [0-9]+$ ]]; then
          if [[ "$name" == r446-action || "$name" == r449-action ]]; then
            # uiautomator dump registers UiAutomation with flags=0 and can
            # temporarily suppress/rebind the service. Wait until the actual
            # service is bound before starting the single-use owner action.
            observe before-print-tap
          fi
          adb shell input tap $coords
          return 0
        fi
        if (( attempt > 3 )); then
          if [[ "$name" == r446-action || ( "$name" == action && "${R448_UI_PROBE:-false}" == true ) ]] && (( attempt <= 12 )); then
            # The signed selector sits below both sample buttons. After the
            # route/reopen probe, scroll back toward the buttons first.
            scroll_controls "$out/ui-$name.xml" up
          elif [[ "$name" == r448-select-* ]]; then
            if (( attempt > 10 )); then scroll_controls "$out/ui-$name.xml" up fine
            else scroll_controls "$out/ui-$name.xml" down fine; fi
          else
            scroll_controls "$out/ui-$name.xml" down
          fi
        fi
        sleep 1
      done
      printf 'NOT REACHED: %s\n' "$label" >> "$out/ui-result.txt"
      return 1
    }
    tap_label 'Debug log' entry
    tap_label 'ZÁRKÉPERNYŐ' tab
    adb shell dumpsys accessibility > "$out/accessibility-normal.txt" 2>&1 || true
    if [[ -n "${R449_UI_ROUTE:-}" ]]; then
      case "$R449_UI_ROUTE" in
        FLUVI_STREAM) route_label='Fluvi adatfolyam'; route_name=fluvi;;
        WIDGETS_ANYWHERE) route_label='Widgets Anywhere'; route_name=wa;;
        *) printf 'Unknown R449 route\n' >&2; exit 2;;
      esac
      # The default is Fluvi. Switch away first so that this case also
      # exercises an actual user change and then return to the requested route.
      if [[ "$R449_UI_ROUTE" == FLUVI_STREAM ]]; then tap_label 'Widgets Anywhere' r448-select-wa; fi
      tap_label "$route_label" "r448-select-$route_name"
      confirmed=false
      for attempt in $(seq 1 18); do
        adb shell uiautomator dump /sdcard/r449-route.xml > /dev/null 2>&1 || true
        adb exec-out cat /sdcard/r449-route.xml > "$out/ui-r449-route-$attempt.xml" 2>/dev/null || true
        adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_keyguard_r448_display_route.xml > "$out/r449-route-prefs.xml" 2>/dev/null || true
        if grep -Fq "Natív választás: $route_label" "$out/ui-r449-route-$attempt.xml" &&
            grep -Fq ">$R449_UI_ROUTE</string>" "$out/r449-route-prefs.xml"; then confirmed=true; break; fi
        scroll_controls "$out/ui-r449-route-$attempt.xml" down fine
        sleep 1
      done
      "$confirmed" || { printf 'FAIL: native route %s was not acknowledged\n' "$R449_UI_ROUTE" > "$out/r449-result.txt"; exit 1; }
      tap_label "Egyszeri mintaorb és rögzítés – $route_label" r449-action
      sleep 8
      adb exec-out screencap -p > "$out/r449-$route_name-prewake.png" || true
      adb shell locksettings set-disabled false > "$out/r449-locksettings.txt" 2>&1
      # Independent continuous capture. Monotonic logcat brackets every
      # screenshot. Retain all frames, even if none qualifies as a baseline.
      adb shell 'mkdir -p /data/local/tmp/r449frames; for n in $(seq 1 32); do log -t R449Optical "before $n"; screencap -p "/data/local/tmp/r449frames/$n.png"; log -t R449Optical "after $n"; sleep 0.1; done' > "$out/r449-frame-stream.txt" 2>&1 &
      stream_pid=$!
      sleep 1
      adb shell input keyevent KEYCODE_SLEEP
      sleep 1
      adb shell input keyevent KEYCODE_WAKEUP
      sleep 5
      adb exec-out screencap -p > "$out/r449-$route_name-wake.png" || true
      adb shell wm dismiss-keyguard || true
      sleep 2
      wait "$stream_pid" || true
      adb pull /data/local/tmp/r449frames "$out/r449frames" > "$out/r449-pull.txt" 2>&1 || true
      adb logcat -b all -d -v monotonic -s R449Optical:I > "$out/r449-frame-times.txt" 2>&1 || true
      # Read the frozen route report from the signed app's own capture store.
      # UiAutomation is only reattached after the observed wake has ended.
      adb shell am start -n com.fluvi.app/.MainActivity > "$out/r449-reopen.txt" 2>&1
      adb shell uiautomator dump /sdcard/r449-reopen.xml > /dev/null 2>&1 || true
      adb exec-out cat /sdcard/r449-reopen.xml > "$out/ui-r449-reopen.xml" 2>/dev/null || true
      if ! grep -Fq 'ZÁRKÉPERNYŐ' "$out/ui-r449-reopen.xml"; then tap_label 'Debug log' entry; fi
      tap_label 'ZÁRKÉPERNYŐ' tab
      tap_label 'leállítás' r449-freeze
      sleep 2
      adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_keyguard_r448_comparison.xml > "$out/r449-comparison.xml" 2>/dev/null || true
      python3 - "$out/r449-comparison.xml" "$R449_UI_ROUTE" > "$out/r449-result.txt" <<'PY'
import sys, xml.etree.ElementTree as ET
try:
    root=ET.parse(sys.argv[1]).getroot()
    report=next((e.text or '' for e in root if e.attrib.get('name') == sys.argv[2]), '')
    rows=[s for s in report.splitlines() if s.startswith('R44_9_OUTCOME ')]
    assert rows, 'NOT REACHED: no protected R44.9 outcome in the frozen report'
    assert any('routeConfirmed='+sys.argv[2] in s and 'action=ONE_WAKE' in s for s in rows), 'FAIL: route/action was not confirmed by service'
    print('PASS: signed UI action and frozen native route receipt')
    print('\n'.join(rows))
    print('OPTICAL=NOT QUALIFIED: raw continuous frames retained; no calibrated same-wake comparison performed by this script.')
except (ET.ParseError,OSError,AssertionError) as e:
    print(e)
    sys.exit(1)
PY
      [[ "$bound_before" == true && "$bound_after" == true ]]
      exit 0
    fi
    if [[ "${R448_UI_PROBE:-false}" == true ]]; then
      # Observe the signed Flutter control and its native readback, then the
      # persisted preference after a normal activity reopen. This verifies the
      # selector; it does not claim a stock-keyguard visual pass.
      wait_route() {
        local label=$1 wire=$2 phase=$3 ok=false
        for attempt in $(seq 1 18); do
          adb shell uiautomator dump /sdcard/r448-route.xml > /dev/null 2>&1 || true
          adb exec-out cat /sdcard/r448-route.xml > "$out/ui-route-$phase-$attempt.xml" 2>/dev/null || true
          if wait_for_system_anr "$out/ui-route-$phase-$attempt.xml" "route-$phase-$attempt"; then continue; fi
          adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_keyguard_r448_display_route.xml > "$out/prefs-route-$phase.xml" 2>/dev/null || true
          if grep -Fq "Natív választás: $label" "$out/ui-route-$phase-$attempt.xml" &&
             grep -Fq ">$wire</string>" "$out/prefs-route-$phase.xml"; then ok=true; break; fi
          if (( attempt <= 10 )); then scroll_controls "$out/ui-route-$phase-$attempt.xml" down
          else scroll_controls "$out/ui-route-$phase-$attempt.xml" up; fi
          sleep 1
        done
        "$ok" || { printf 'FAIL: native route %s not observed at %s\n' "$wire" "$phase" >> "$out/ui-route-result.txt"; return 1; }
        printf 'PASS: native route %s acknowledged at %s\n' "$wire" "$phase" >> "$out/ui-route-result.txt"
      }
      reopen_route_panel() {
        adb shell input keyevent KEYCODE_BACK
        adb shell input keyevent KEYCODE_BACK
        adb shell am start -n com.fluvi.app/.MainActivity >> "$out/reopen-r448.txt" 2>&1
        tap_label 'Debug log' entry
        tap_label 'ZÁRKÉPERNYŐ' tab
      }
      restart_route_panel() {
        local phase=$1 old_pid new_pid=''
        old_pid=$(adb shell pidof com.fluvi.app | tr -d '\r' | awk '{print $1}')
        [[ "$old_pid" =~ ^[0-9]+$ ]]
        adb shell run-as com.fluvi.app kill -9 "$old_pid"
        adb shell am start -n com.fluvi.app/.MainActivity >> "$out/restart-r448.txt" 2>&1
        observe "route-restart-$phase"
        new_pid=$(adb shell pidof com.fluvi.app | tr -d '\r' | awk '{print $1}')
        [[ "$new_pid" =~ ^[0-9]+$ && "$new_pid" != "$old_pid" ]]
        printf '%s old_pid=%s new_pid=%s\n' "$phase" "$old_pid" "$new_pid" >> "$out/ui-route-result.txt"
        tap_label 'Debug log' entry
        tap_label 'ZÁRKÉPERNYŐ' tab
      }
      tap_label 'Widgets Anywhere' r448-select-wa
      wait_route 'Widgets Anywhere' WIDGETS_ANYWHERE wa-selected
      if [[ "${R448_RESTART_PROBE:-false}" == true ]]; then restart_route_panel wa
      else reopen_route_panel; fi
      wait_route 'Widgets Anywhere' WIDGETS_ANYWHERE wa-reopened
      tap_label 'Fluvi adatfolyam' r448-select-fluvi
      wait_route 'Fluvi adatfolyam' FLUVI_STREAM fluvi-selected
      if [[ "${R448_RESTART_PROBE:-false}" == true ]]; then restart_route_panel fluvi
      else reopen_route_panel; fi
      wait_route 'Fluvi adatfolyam' FLUVI_STREAM fluvi-reopened
      printf '%s\n' 'Selector only: no window or physical-pixel assertion.' >> "$out/ui-route-result.txt"
    fi
    if [[ "${R446_UI_PROBE:-false}" == true ]]; then
      # Exercise the actual new button in the signed profile, followed by one
      # unmodified Android lock/wake. Do not run uiautomator between the tap
      # and wake: its flags=0 suppress other accessibility services.
      tap_label 'Egyszeri rajzpróba – fix minta' r446-action
      sleep 12
      scroll_controls "$out/ui-r446-action.xml" down
      sleep 1
      adb exec-out screencap -p > "$out/r446-prewake-receipt.png"
      printf '%s\n' 'OBSERVED: signed one-wake button tapped; pre-wake screenshot retained for independent receipt inspection.' > "$out/ui-r446-result.txt"
      if [[ "${R446_ARM_ONLY:-false}" == true ]]; then
        # Separate arm-only diagnostic. The first hierarchy is read only
        # after the preparation interval; UiAutomation may end the probe.
        # Do not use this run to claim an uninterrupted wake.
        r446_receipt=false
        for attempt in $(seq 1 16); do
          adb shell uiautomator dump /sdcard/r446-arm-only.xml > /dev/null 2>&1 || true
          adb exec-out cat /sdcard/r446-arm-only.xml > "$out/ui-r446-arm-$attempt.xml" 2>/dev/null || true
          if wait_for_system_anr "$out/ui-r446-arm-$attempt.xml" "arm-only-$attempt"; then continue; fi
          if grep -Fq 'Egyszeri rajzpróba előkészítve' "$out/ui-r446-arm-$attempt.xml"; then
            r446_receipt=true; break
          fi
          if (( attempt <= 8 )); then scroll_controls "$out/ui-r446-arm-$attempt.xml" down
          else scroll_controls "$out/ui-r446-arm-$attempt.xml" up; fi
          sleep 1
        done
        "$r446_receipt" || { printf '%s\n' 'FAIL: signed one-wake receipt not observed in arm-only UI.' >> "$out/ui-r446-result.txt"; exit 1; }
        printf '%s\n' 'PASS: signed one-wake UI receipt observed; this arm-only run does not prove an uninterrupted wake.' >> "$out/ui-r446-result.txt"
        [[ "$bound_before" == true && "$bound_after" == true ]]
        exit 0
      fi
      adb shell locksettings set-disabled false > "$out/r446-locksettings.txt" 2>&1
      adb shell input keyevent KEYCODE_SLEEP
      sleep 1
      adb shell input keyevent KEYCODE_WAKEUP
      sleep 2
      adb shell dumpsys window > "$out/r446-stock-window.txt" 2>&1 || true
      adb exec-out screencap -p > "$out/r446-stock-wake.png" || true
      printf '%s\n' 'One stock wake performed; screenshot retained. Pixel visibility and physical presentation are not inferred from this receipt.' >> "$out/ui-r446-result.txt"
      adb shell wm dismiss-keyguard || true
      sleep 1
      adb shell uiautomator dump /sdcard/r446-after-wake.xml > /dev/null 2>&1 || true
      adb exec-out cat /sdcard/r446-after-wake.xml > "$out/ui-r446-after-wake.xml" 2>/dev/null || true
      [[ "$bound_before" == true && "$bound_after" == true ]]
      exit 0
    fi
    tap_label 'Mintaorb kipróbálása és rögzítés' action
    receipt=false
    for attempt in $(seq 1 12); do
      adb shell uiautomator dump /sdcard/r442-window.xml > /dev/null 2>&1 || true
      adb exec-out cat /sdcard/r442-window.xml > "$out/ui-receipt.xml" 2>/dev/null || true
      if wait_for_system_anr "$out/ui-receipt.xml" "receipt-$attempt"; then continue; fi
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
      if wait_for_system_anr "$out/ui-frozen-state.xml" "frozen-state-$attempt"; then continue; fi
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
      if wait_for_system_anr "$out/ui-frozen.xml" "frozen-$attempt"; then continue; fi
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

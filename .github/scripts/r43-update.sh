#!/usr/bin/env bash
set -euo pipefail
out="$RUNNER_TEMP/r43-update"
mkdir -p "$out"
case "$1" in
  prepare)
    [[ "$APP_SHA" =~ ^[0-9a-f]{40}$ && "$CANDIDATE_SHA256" =~ ^[0-9a-f]{64}$ && "$CANDIDATE_SIZE" =~ ^[0-9]+$ ]]
    [[ "$CANDIDATE_URL" == https://media.githubusercontent.com/media/elizerpist/exptv2/*/*.apk ]]
    curl -fLsS --retry 3 'https://media.githubusercontent.com/media/elizerpist/exptv2/c0b06e1a673a64b817cf5c82bc6dc3f9299a9228/fluvi_R42_HUMAN_1584ccb020a8.apk' -o "$out/r42.apk"
    curl -fLsS --retry 3 "$CANDIDATE_URL" -o "$out/r43.apk"
    test "$(wc -c < "$out/r42.apk")" -eq 121006864
    test "$(wc -c < "$out/r43.apk")" -eq "$CANDIDATE_SIZE"
    printf '%s  %s\n' 8be8969bc11845f46518d23d5f99706a01032a251c3a3b65444f13f58b849ad8 "$out/r42.apk" | sha256sum -c -
    printf '%s  %s\n' "$CANDIDATE_SHA256" "$out/r43.apk" | sha256sum -c -
    signer=$(find "$ANDROID_HOME/build-tools" -mindepth 2 -maxdepth 2 -name apksigner -type f | sort -V | tail -1)
    for name in r42 r43; do
      "$signer" verify --verbose --print-certs "$out/$name.apk" > "$out/$name-signature.txt"
      grep -Fqi faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb "$out/$name-signature.txt"
      unzip -tq "$out/$name.apk" > "$out/$name-zip.txt"
    done
    for abi in armeabi-v7a arm64-v8a x86_64; do
      unzip -p "$out/r43.apk" "lib/$abi/libapp.so" > "$out/libapp.so"
      grep -aqF "$APP_SHA" "$out/libapp.so"
      grep -aqF HUMAN_DIAGNOSTIC "$out/libapp.so"
      printf '%s exact source/purpose PASS\n' "$abi" >> "$out/embedded.txt"
    done
    rm "$out/libapp.so"
    ;;
  run)
    { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.build.fingerprint; } > "$out/device.txt"
    test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 37
    adb install "$out/r42.apk" > "$out/install-r42.txt" 2>&1
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
  <string name="focus.categoryId">r43-synthetic-category</string>
  <string name="focus.eventLine">related</string>
  <long name="focus.generation" value="7" />
</map>
XML
    printf '%s\n' 'r43-update-sentinel' > "$out/sentinel.txt"
    adb push "$out/seed.xml" /data/local/tmp/r43-seed.xml > /dev/null
    adb push "$out/sentinel.txt" /data/local/tmp/r43-sentinel.txt > /dev/null
    adb shell 'run-as com.fluvi.app sh -c "mkdir -p files shared_prefs; cp /data/local/tmp/r43-seed.xml shared_prefs/fluvi_native_keyguard_card.xml; cp /data/local/tmp/r43-sentinel.txt files/r43-update-sentinel.txt"'
    component='com.fluvi.app/com.fluvi.app.lockscreen.FluviKeyguardCardService'
    adb shell settings put secure enabled_accessibility_services "$component"
    adb shell settings put secure accessibility_enabled 1
    observe() {
      local label=$1 ok=false pid
      for _ in $(seq 1 60); do
        adb shell dumpsys activity services "$component" > "$out/service-$label.txt" 2>&1 || true
        adb shell dumpsys accessibility > "$out/accessibility-$label.txt" 2>&1 || true
        pid=$(adb shell pidof com.fluvi.app | tr -d '\r' | awk '{print $1}')
        if [[ "$pid" =~ ^[0-9]+$ ]] && grep -Fq 'com.fluvi.app/.lockscreen.FluviKeyguardCardService' "$out/service-$label.txt" &&
            grep -Eq "app=ProcessRecord\\{[^}]*[[:space:]]${pid}:com[.]fluvi[.]app/" "$out/service-$label.txt" &&
            grep -Fq 'Bound services:{Service[label=Fluvi' "$out/accessibility-$label.txt"; then ok=true; break; fi
        sleep 0.5
      done
      adb shell settings get secure enabled_accessibility_services > "$out/enabled-$label.txt"
      "$ok" && grep -Fq "$component" "$out/enabled-$label.txt"
    }
    observe before
    adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$out/prefs-before.xml"
    adb exec-out run-as com.fluvi.app cat files/r43-update-sentinel.txt > "$out/sentinel-before.txt"
    adb install -r "$out/r43.apk" > "$out/install-r43.txt" 2>&1
    observe after
    adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$out/prefs-after.xml"
    adb exec-out run-as com.fluvi.app cat files/r43-update-sentinel.txt > "$out/sentinel-after.txt"
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
    printf '%s\n' 'PASS: genuine signed R42 to R43 install -r; synthetic preferences, sentinel and live bound service survived on API 37.' > "$out/result.txt"
    ;;
  *) exit 2;;
esac

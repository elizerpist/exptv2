#!/usr/bin/env bash
set -euo pipefail
dir="$RUNNER_TEMP/r41-update"
evidence="$dir/evidence"
mkdir -p "$evidence"
case "${1:-}" in
 retrieve)
  cd "$GITHUB_WORKSPACE/orchestrator"
  branch="refs/heads/test/r42-encrypted-update-$GITHUB_RUN_ID"
  found=false
  for _ in $(seq 1 180); do
    if git fetch --quiet --depth=1 origin "$branch"; then found=true; break; fi
    sleep 5
  done
  "$found" || { echo 'Encrypted payload branch was not received.' >&2; exit 1; }
  git rev-parse FETCH_HEAD > "$evidence/payload-commit.txt"
  git show FETCH_HEAD:wrapped.key > "$dir/wrapped.key"
  git show FETCH_HEAD:payload.enc | git lfs smudge > "$dir/payload.enc"
  umask 077
  openssl pkeyutl -decrypt -inkey "$dir/private.pem" -in "$dir/wrapped.key" -out "$dir/password" -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256
  openssl enc -d -aes-256-cbc -pbkdf2 -pass "file:$dir/password" -in "$dir/payload.enc" | tar -xf - -C "$dir" --no-same-owner --no-same-permissions
  [[ "$CANDIDATE_SHA256" =~ ^[0-9a-f]{64}$ && "$TEST_SHA256" =~ ^[0-9a-f]{64}$ ]]
  printf '%s  %s\n' "$CANDIDATE_SHA256" "$dir/candidate.apk" | sha256sum -c - > "$evidence/candidate-hash.txt"
  printf '%s  %s\n' "$TEST_SHA256" "$dir/test.apk" | sha256sum -c - > "$evidence/test-hash.txt"
  ;;
 verify)
  [[ "$APP_SHA" =~ ^[0-9a-f]{40}$ && "$CANDIDATE_SIZE" =~ ^[0-9]+$ && "$TEST_SIZE" =~ ^[0-9]+$ ]]
  curl --fail --location --retry 3 --silent --show-error 'https://media.githubusercontent.com/media/elizerpist/exptv2/9264dfd1d79ce6e8034b72530362dfe1ab7fd871/fluvi_R41_HUMAN_97f9704120e2.apk' -o "$dir/r41.apk"
  test "$(wc -c < "$dir/r41.apk")" -eq 120965705
  printf '%s  %s\n' 541c609c7e5fcdddf3a579ba30a42eaf5863c8db82a61406c0349a0b72aecd82 "$dir/r41.apk" | sha256sum -c - > "$evidence/r41-hash.txt"
  test "$(wc -c < "$dir/candidate.apk")" -eq "$CANDIDATE_SIZE"
  test "$(wc -c < "$dir/test.apk")" -eq "$TEST_SIZE"
  tools="$ANDROID_HOME/build-tools/36.0.0"
  for label in r41 candidate; do
    apk="$dir/$label.apk"
    "$tools/apksigner" verify --verbose --print-certs "$apk" > "$evidence/$label-signature.txt"
    grep -Fqi 'faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb' "$evidence/$label-signature.txt"
    "$tools/aapt" dump badging "$apk" > "$evidence/$label-badging.txt"
    grep -Fq "package: name='com.fluvi.app' versionCode='1'" "$evidence/$label-badging.txt"
    grep -Fq 'application-debuggable' "$evidence/$label-badging.txt"
    unzip -tq "$apk" > "$evidence/$label-zip.txt"
  done
  "$tools/apksigner" verify --verbose --print-certs "$dir/test.apk" > "$evidence/test-signature.txt"
  grep -Fqi 'faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb' "$evidence/test-signature.txt"
  "$tools/aapt" dump badging "$dir/test.apk" > "$evidence/test-badging.txt"
  grep -Fq "package: name='com.fluvi.app.test'" "$evidence/test-badging.txt"
  for abi in armeabi-v7a arm64-v8a x86_64; do
    unzip -p "$dir/candidate.apk" "lib/$abi/libapp.so" > "$dir/libapp.so"
    grep -aqF "$APP_SHA" "$dir/libapp.so"
    grep -aqF HUMAN_DIAGNOSTIC "$dir/libapp.so"
    printf '%s embedded source and purpose confirmed\n' "$abi" >> "$evidence/embedded.txt"
  done
  ;;
 install)
  { adb devices -l; adb shell getprop ro.build.version.sdk; adb shell getprop ro.product.cpu.abi; adb shell getprop ro.build.fingerprint; } > "$evidence/device.txt"
  test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 35
  adb install "$dir/r41.apk" > "$evidence/install-r41.txt" 2>&1
  adb shell am force-stop com.fluvi.app
  cat > "$dir/seed.xml" <<'XML'
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
    <string name="focus.categoryId">r41-synthetic-category</string>
    <string name="focus.eventLine">related</string>
    <long name="focus.generation" value="7" />
</map>
XML
  printf '%s\n' 'r41-synthetic-update-sentinel' > "$dir/sentinel.txt"
  adb push "$dir/seed.xml" /data/local/tmp/r41-seed.xml > "$evidence/push-seed.txt" 2>&1
  adb push "$dir/sentinel.txt" /data/local/tmp/r41-sentinel.txt >> "$evidence/push-seed.txt" 2>&1
  adb shell 'run-as com.fluvi.app sh -c "mkdir -p files shared_prefs; cp /data/local/tmp/r41-seed.xml shared_prefs/fluvi_native_keyguard_card.xml; cp /data/local/tmp/r41-sentinel.txt files/r41-update-sentinel.txt"'
  adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$evidence/prefs-before.xml"
  adb exec-out run-as com.fluvi.app cat files/r41-update-sentinel.txt > "$evidence/sentinel-before.txt"
  cmp "$dir/seed.xml" "$evidence/prefs-before.xml"
  cmp "$dir/sentinel.txt" "$evidence/sentinel-before.txt"
  # Confirm the actual accessibility service exists and runs before update;
  # an enabled component alone is not evidence of a bound live process.
  component='com.fluvi.app/.lockscreen.FluviKeyguardCardService'
  adb shell am start -n com.fluvi.app/.MainActivity > "$evidence/launch-r41.txt" 2>&1
  adb shell settings put secure enabled_accessibility_services "$component"
  adb shell settings put secure accessibility_enabled 1
  observe_service() {
    local label="$1" seen=false app_pid
    for _ in $(seq 1 60); do
      adb shell dumpsys activity services "$component" > "$evidence/service-$label.txt" 2>&1 || true
      adb shell dumpsys accessibility > "$evidence/accessibility-$label.txt" 2>&1 || true
      adb shell pidof com.fluvi.app > "$evidence/pid-$label.txt" 2>&1 || true
      app_pid=$(tr -d '\r' < "$evidence/pid-$label.txt" | awk '{print $1}')
      if [[ "$app_pid" =~ ^[0-9]+$ ]] &&
         grep -Fq 'com.fluvi.app/.lockscreen.FluviKeyguardCardService' "$evidence/service-$label.txt" &&
         grep -Eq "app=ProcessRecord\\{[^}]*[[:space:]]${app_pid}:com[.]fluvi[.]app/" "$evidence/service-$label.txt" &&
         grep -Fq 'Bound services:{Service[label=Fluvi' "$evidence/accessibility-$label.txt" &&
         grep -Fq 'Binding services:{}' "$evidence/accessibility-$label.txt"; then
        seen=true; break
      fi
      sleep 0.5
    done
    adb shell settings get secure enabled_accessibility_services > "$evidence/enabled-$label.txt"
    "$seen" && grep -Fq "$component" "$evidence/enabled-$label.txt"
  }
  observe_service before
  # The old app may write its own canonical preferences during startup.
  # Compare the exact on-device state immediately before the upgrade.
  adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$evidence/prefs-before.xml"
  adb exec-out run-as com.fluvi.app cat files/r41-update-sentinel.txt > "$evidence/sentinel-before.txt"
  cmp "$dir/sentinel.txt" "$evidence/sentinel-before.txt"
  adb install -r "$dir/candidate.apk" > "$evidence/install-r42-update.txt" 2>&1
  observe_service after
  adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$evidence/prefs-after.xml"
  adb exec-out run-as com.fluvi.app cat files/r41-update-sentinel.txt > "$evidence/sentinel-after.txt"
  # Android may reorder SharedPreferences XML and add unrelated defaults.
  # Verify every original synthetic selection by typed key/value, including
  # the category, against both the R41 and R42 observations.
  python3 - "$dir/seed.xml" "$evidence/prefs-before.xml" "$evidence/prefs-after.xml" > "$evidence/settings-check.txt" <<'PY'
import sys, xml.etree.ElementTree as ET
def load(path):
    return {node.attrib['name']: (node.tag, node.attrib.get('value', node.text or ''))
            for node in ET.parse(path).getroot()}
seed, before, after = map(load, sys.argv[1:])
for name, expected in sorted(seed.items()):
    assert before.get(name) == expected, f'Prior or updated version did not retain synthetic {name}'
    assert after.get(name) == expected, f'Prior or updated version did not retain synthetic {name}'
    print(name, 'PASS')
PY
  cmp "$dir/sentinel.txt" "$evidence/sentinel-after.txt"
  adb shell am start -n com.fluvi.app/.MainActivity > "$evidence/launch.txt" 2>&1
  adb shell dumpsys package com.fluvi.app > "$evidence/package-after.txt"
  printf '%s\n' 'PASS: API 35 R41-to-R42 install -r, synthetic preferences/file preserved and accessibility service is bound with a live process before/after.' > "$evidence/result.txt"
  # The instrumentation package is signed with the same update key and
  # exercises the actual installed PROFILE application, not the debug APK.
  adb install -r "$dir/test.apk" > "$evidence/install-test.txt" 2>&1
  trial=$(cat /proc/sys/kernel/random/uuid)
  printf '%s\n' "$trial" > "$evidence/motion-trial.txt"
  rc=0
  timeout -k 5s 300s adb shell am instrument -w -r -e sourceSha "$APP_SHA" -e runUuid "$trial" -e captureBuildMode profile \
    -e class 'com.fluvi.app.lockscreen.KeyguardR42SignedProfileProbeTest#signedProfileShowsCurrentGrantedOrbAndNaturalMotion' \
    com.fluvi.app.test/androidx.test.runner.AndroidJUnitRunner > "$evidence/profile-motion.txt" 2>&1 || rc=$?
  adb exec-out run-as com.fluvi.app tar -cf - "files/keyguard-service-probe/r42-profile/$trial" > "$evidence/profile-motion.tar" 2> "$evidence/profile-motion-tar.stderr" || true
  # These are test-environment observations, retained even if the profile
  # instrumentation cannot reconnect after Android restarts its process.
  adb shell settings get global animator_duration_scale > "$evidence/animator-duration-scale.txt" 2>&1 || true
  adb shell dumpsys accessibility > "$evidence/accessibility-post-instrumentation.txt" 2>&1 || true
  adb shell dumpsys activity services com.fluvi.app/.lockscreen.FluviKeyguardCardService > "$evidence/service-post-instrumentation.txt" 2>&1 || true
  adb logcat -d -v monotonic -s FluviKeyguard:* AndroidRuntime:E ActivityManager:I > "$evidence/profile-motion-logcat.txt" 2>&1 || true
  if (( rc != 0 )) || grep -Eq 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed|shortMsg=' "$evidence/profile-motion.txt" ||
     ! grep -Eq '^OK \(1 test\)' "$evidence/profile-motion.txt"; then
    printf '%s\n' 'FAIL or NOT REACHED: profile visible-motion instrumentation; see retained transcript and samples.' >> "$evidence/result.txt"
    exit 1
  fi
  mkdir -p "$dir/motion"
  tar -xf "$evidence/profile-motion.tar" -C "$dir/motion"
  report=$(find "$dir/motion" -name capture.txt -type f -print -quit)
  test -n "$report"
  cp "$report" "$evidence/profile-motion-capture.txt"
  if ! grep -Eq '^ R41_CORE .*outcome=SUCCESS .*owner=[0-9]+/[0-9]+/[0-9]+' "$report"; then
    printf '%s\n' 'FAIL or NOT REACHED: no matching owner-bound R41 grant/winner in profile capture.' >> "$evidence/result.txt"
    exit 1
  fi
  # Android force-stops the target when `am instrument` finishes. That is a
  # test-runner teardown, not the package update: the bound service before and
  # immediately after the update was already verified above. Preserve the
  # pre-cleanup dumps and explicitly request a normal rebind for teardown.
  if grep -Eq 'Force stopping com[.]fluvi[.]app .*: finished inst' "$evidence/profile-motion-logcat.txt"; then
    printf '%s\n' 'Instrumentation force-stopped target at finish; requesting ordinary accessibility-service rebind.' > "$evidence/post-instrumentation-rebind.txt"
    adb shell "settings put secure enabled_accessibility_services ''"
    adb shell settings put secure accessibility_enabled 0
    adb shell settings put secure enabled_accessibility_services "$component"
    adb shell settings put secure accessibility_enabled 1
  fi
  observe_service post-motion
  adb exec-out run-as com.fluvi.app cat files/r41-update-sentinel.txt > "$evidence/sentinel-post-motion.txt"
  cmp "$dir/sentinel.txt" "$evidence/sentinel-post-motion.txt"
  printf '%s\n' 'PASS: matching owner-bound grant/winner and repeated distinct natural compositor samples on the installed profile candidate.' 'Physical phone latency and continuous privacy remain unmeasured.' >> "$evidence/result.txt"
  ;;
 *) exit 2;;
esac

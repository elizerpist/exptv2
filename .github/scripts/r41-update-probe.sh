#!/usr/bin/env bash
set -euo pipefail
dir="$RUNNER_TEMP/r41-update"
evidence="$dir/evidence"
mkdir -p "$evidence"
case "${1:-}" in
 retrieve)
  cd "$GITHUB_WORKSPACE/orchestrator"
  branch="refs/heads/test/r41-encrypted-update-$GITHUB_RUN_ID"
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
  openssl enc -d -aes-256-cbc -pbkdf2 -pass "file:$dir/password" -in "$dir/payload.enc" -out "$dir/candidate.apk"
  [[ "$CANDIDATE_SHA256" =~ ^[0-9a-f]{64}$ ]]
  printf '%s  %s\n' "$CANDIDATE_SHA256" "$dir/candidate.apk" | sha256sum -c - > "$evidence/candidate-hash.txt"
  ;;
 verify)
  [[ "$APP_SHA" =~ ^[0-9a-f]{40}$ && "$CANDIDATE_SIZE" =~ ^[0-9]+$ ]]
  curl --fail --location --retry 3 --silent --show-error 'https://media.githubusercontent.com/media/elizerpist/exptv2/465eaeca287663d152b36b76f12fc8b05ea2d8e0/fluvi_R40_HUMAN_11b4a67a08f4.apk' -o "$dir/r40.apk"
  test "$(wc -c < "$dir/r40.apk")" -eq 120957712
  printf '%s  %s\n' d0442e4af8352a7f9e3e1d55e8a2147875b228585938145efd574f3ec577677c "$dir/r40.apk" | sha256sum -c - > "$evidence/r40-hash.txt"
  test "$(wc -c < "$dir/candidate.apk")" -eq "$CANDIDATE_SIZE"
  tools="$ANDROID_HOME/build-tools/36.0.0"
  for label in r40 candidate; do
    apk="$dir/$label.apk"
    "$tools/apksigner" verify --verbose --print-certs "$apk" > "$evidence/$label-signature.txt"
    grep -Fqi 'faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb' "$evidence/$label-signature.txt"
    "$tools/aapt" dump badging "$apk" > "$evidence/$label-badging.txt"
    grep -Fq "package: name='com.fluvi.app' versionCode='1'" "$evidence/$label-badging.txt"
    grep -Fq 'application-debuggable' "$evidence/$label-badging.txt"
    unzip -tq "$apk" > "$evidence/$label-zip.txt"
  done
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
  adb install "$dir/r40.apk" > "$evidence/install-r40.txt" 2>&1
  adb shell am force-stop com.fluvi.app
  cat > "$dir/seed.xml" <<'XML'
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <boolean name="requested" value="true" />
    <boolean name="details" value="true" />
    <string name="presentationMode">orb</string>
    <string name="animationMode">orbOnly</string>
    <string name="focus.categoryId">r41-synthetic-category</string>
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
  adb shell am start -n com.fluvi.app/.MainActivity > "$evidence/launch-r40.txt" 2>&1
  adb shell settings put secure enabled_accessibility_services "$component"
  adb shell settings put secure accessibility_enabled 1
  observe_service() {
    local label="$1" seen=false app_pid
    for _ in $(seq 1 60); do
      adb shell dumpsys activity services "$component" > "$evidence/service-$label.txt" 2>&1 || true
      adb shell pidof com.fluvi.app > "$evidence/pid-$label.txt" 2>&1 || true
      app_pid=$(tr -d '\r' < "$evidence/pid-$label.txt" | awk '{print $1}')
      if [[ "$app_pid" =~ ^[0-9]+$ ]] &&
         grep -Fq 'com.fluvi.app/.lockscreen.FluviKeyguardCardService' "$evidence/service-$label.txt" &&
         grep -Eq "app=ProcessRecord\\{[^}]*[[:space:]]${app_pid}:com[.]fluvi[.]app/" "$evidence/service-$label.txt"; then
        seen=true; break
      fi
      sleep 0.5
    done
    adb shell settings get secure enabled_accessibility_services > "$evidence/enabled-$label.txt"
    adb shell dumpsys accessibility > "$evidence/accessibility-$label.txt" 2>&1 || true
    "$seen" && grep -Fq "$component" "$evidence/enabled-$label.txt"
  }
  observe_service before
  # The old app may write its own canonical preferences during startup.
  # Compare the exact on-device state immediately before the upgrade.
  adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$evidence/prefs-before.xml"
  adb exec-out run-as com.fluvi.app cat files/r41-update-sentinel.txt > "$evidence/sentinel-before.txt"
  cmp "$dir/sentinel.txt" "$evidence/sentinel-before.txt"
  adb install -r "$dir/candidate.apk" > "$evidence/install-r41-update.txt" 2>&1
  observe_service after
  adb exec-out run-as com.fluvi.app cat shared_prefs/fluvi_native_keyguard_card.xml > "$evidence/prefs-after.xml"
  adb exec-out run-as com.fluvi.app cat files/r41-update-sentinel.txt > "$evidence/sentinel-after.txt"
  cmp "$evidence/prefs-before.xml" "$evidence/prefs-after.xml"
  cmp "$dir/sentinel.txt" "$evidence/sentinel-after.txt"
  adb shell am start -n com.fluvi.app/.MainActivity > "$evidence/launch.txt" 2>&1
  adb shell dumpsys package com.fluvi.app > "$evidence/package-after.txt"
  printf '%s\n' 'PASS: API 35 R40-to-R41 install -r, synthetic preferences/file preserved and enabled accessibility service has a live process before/after.' 'NOT TESTED: authorization, ORB pixels, animation, privacy and phone performance.' > "$evidence/result.txt"
  ;;
 *) exit 2;;
esac

#!/usr/bin/env bash
set -euo pipefail
: "${RUNNER_TEMP:?}" "${APK_ARTIFACT:?}" "${APP_SHA:?}" "${APK_SHA256:?}" "${APK_SIZE:?}"
test "${#APK_ARTIFACT}" -eq 40 && [[ "$APK_ARTIFACT" =~ ^[0-9a-f]+$ ]]
test "${#APP_SHA}" -eq 40 && [[ "$APP_SHA" =~ ^[0-9a-f]+$ ]]
test "${#APK_SHA256}" -eq 64 && [[ "$APK_SHA256" =~ ^[0-9a-f]+$ ]]
[[ "$APK_SIZE" =~ ^[0-9]+$ ]]
state="$RUNNER_TEMP/r50-signed-upgrade"
out="$GITHUB_WORKSPACE/r50-upgrade-evidence"
mkdir -p "$state" "$out"
if [[ "${1:-}" = download ]]; then
    base=https://media.githubusercontent.com/media/elizerpist/exptv2
    curl --disable -fLsS --retry 2 "$base/b1257de29bd0342383f305fa7189feaf4586ee20/Fluvi_R49_HUMAN_a614bf74f7a0.apk" -o "$state/r49.apk"
    curl --disable -fLsS --retry 2 "$base/$APK_ARTIFACT/Fluvi_R50_HUMAN_${APP_SHA:0:12}.apk" -o "$state/r50.apk"
    printf '%s  %s\n' a70263a536f54d7d9d5d00d5052bfdbd75775c924d0fa0b27d8db59e9cff264e "$state/r49.apk" \
        "$APK_SHA256" "$state/r50.apk" | sha256sum -c - | tee "$out/binaries.txt"
    test "$(wc -c < "$state/r50.apk")" -eq "$APK_SIZE"
    signer="$ANDROID_HOME/build-tools/36.0.0/apksigner"
    for file in "$state/r49.apk" "$state/r50.apk" .github/r50-upgrade/fixture.apk; do
        "$signer" verify --verbose --print-certs "$file" | tee -a "$out/signatures.txt" |
            grep -F 'Signer #1 certificate SHA-256 digest: faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb'
    done
    exit
fi
adb shell getprop ro.build.fingerprint | tee "$out/device.txt"
test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 37
test "$(adb shell getprop ro.kernel.qemu | tr -d '\r')" = 1
trap 'adb logcat -d -v threadtime > "$out/logcat.txt" 2>&1 || true' EXIT
adb root
adb wait-for-device
package=com.fluvi.app
service="$package/tk.zwander.lockscreenwidgets.services.Accessibility"
adb install "$state/r49.apk" | tee "$out/r49-install.txt"
adb install .github/r50-upgrade/fixture.apk | tee "$out/fixture-install.txt"
adb shell wm dismiss-keyguard
adb shell am start -W -n "$package/.MainActivity" | tee "$out/r49-launch.txt"
db="/data/user/0/$package/databases/fluvi_core.db"
for _ in $(seq 1 10); do
    if adb shell test -f "$db"; then break; fi
    sleep 1
done
adb shell test -f "$db"
adb shell am force-stop "$package"
adb pull "$db" "$state/seed.db" >/dev/null
if adb shell test -f "$db-wal"; then adb pull "$db-wal" "$state/seed.db-wal" >/dev/null; fi
python3 - "$state/seed.db" <<'PY'
import sqlite3, sys
with sqlite3.connect(sys.argv[1]) as db:
    db.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    db.execute("PRAGMA journal_mode=DELETE")
    c = db.execute("SELECT id FROM fluvi_categories WHERE is_system_uncategorized=1").fetchone()
    assert c, "R49 initial category unavailable"
    db.execute("INSERT INTO fluvi_partners VALUES(?, ?, NULL, ?, NULL, 1000, 1000)", ("r50-synthetic-partner", "Synthetic fixture", c[0]))
    db.execute("INSERT INTO fluvi_ledger_entries VALUES(?, ?, ?, 'partnerDefault', ?, 'expense', 12345, 20784, 600, 1795600800000, 'manual', NULL, NULL, 1000, 1000, 1)",
               ("r50-synthetic-entry", "r50-synthetic-partner", c[0], "R49→R50 continuity fixture"))
    db.execute("INSERT INTO fluvi_notification_inbox (id, raw_notification_text, received_at_utc_ms, parse_status, processing_status, training_status, review_status, created_at_utc_ms, updated_at_utc_ms) VALUES('r50-synthetic-notification','Synthetic update fixture',1000,'unclassified','unprocessed','unused','none',1000,1000)")
PY
adb push "$state/seed.db" /data/local/tmp/r50-seed.db >/dev/null
adb shell "cat /data/local/tmp/r50-seed.db > '$db'; rm -f '$db-wal' '$db-shm' /data/local/tmp/r50-seed.db"
adb shell cmd appwidget grantbind --package "$package" --user 0
fixture=com.fluvi.r50.updatefixture/.BindFixture
adb shell am instrument -w -e phase seed "$fixture" | tee "$out/seed-host.txt"
grep -x 'INSTRUMENTATION_RESULT: r50Fixture=PASS' "$out/seed-host.txt"
active="$(sed -n 's/^INSTRUMENTATION_RESULT: active=//p' "$out/seed-host.txt")"
obsolete="$(sed -n 's/^INSTRUMENTATION_RESULT: obsolete=//p' "$out/seed-host.txt")"
foreign="$(sed -n 's/^INSTRUMENTATION_RESULT: foreign=//p' "$out/seed-host.txt")"
adb shell cmd appwidget revokebind --package "$package" --user 0
adb shell settings put secure enabled_accessibility_services "$service"
adb shell settings put secure accessibility_enabled 1
adb shell dumpsys appwidget > "$out/r49-appwidgets.txt"
adb install -r "$state/r50.apk" | tee "$out/r50-update-install.txt"
grep -x Success "$out/r50-update-install.txt"
adb shell am start -W -n "$package/.MainActivity" | tee "$out/r50-launch.txt"
prefs="/data/user/0/$package/shared_prefs/fluvi_balance_orb.xml"
for _ in $(seq 1 15); do
    if adb shell test -f "$prefs"; then break; fi
    sleep 1
done
adb shell settings get secure enabled_accessibility_services | tee "$out/enabled-accessibility.txt" | grep -F "$service"
adb shell am instrument -w -e phase after -e active "$active" -e obsolete "$obsolete" -e foreign "$foreign" "$fixture" |
    tee "$out/migrated-host.txt"
grep -x 'INSTRUMENTATION_RESULT: r50Fixture=PASS' "$out/migrated-host.txt"
adb shell dumpsys appwidget > "$out/r50-appwidgets.txt"
adb shell am force-stop "$package"
adb pull "$db" "$state/after.db" >/dev/null
if adb shell test -f "$db-wal"; then adb pull "$db-wal" "$state/after.db-wal" >/dev/null; fi
python3 - "$state/after.db" <<'PY'
import sqlite3, sys
with sqlite3.connect(sys.argv[1]) as db:
    assert db.execute("SELECT note,amount_scaled_100 FROM fluvi_ledger_entries WHERE id='r50-synthetic-entry'").fetchone() == ("R49→R50 continuity fixture",12345)
    assert db.execute("SELECT raw_notification_text FROM fluvi_notification_inbox WHERE id='r50-synthetic-notification'").fetchone() == ("Synthetic update fixture",)
    assert not db.execute("PRAGMA foreign_key_check").fetchall()
    print("PASS unchanged ledger and notification test records")
PY
printf '%s\n' 'PASS signed R49→R50 update, fixed host migration, dormant intent and retained app data' | tee "$out/result.txt"

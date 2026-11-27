#!/usr/bin/env bash
set -euo pipefail
state="$RUNNER_TEMP/r49-update"
out="$GITHUB_WORKSPACE/r49-upgrade-evidence"
mkdir -p "$out"
adb shell getprop ro.build.fingerprint | tee "$out/device.txt"
test "$(adb shell getprop ro.build.version.sdk | tr -d '\r')" = 37
test "$(adb shell getprop ro.kernel.qemu | tr -d '\r')" = 1
trap 'status=$?; adb logcat -d -v threadtime > "$out/logcat.txt" 2>&1 || true; printf "exit=%s\n" "$status" > "$out/exit.txt"' EXIT
trap 'printf "first-failed-line=%s status=%s\n" "$LINENO" "$?" | tee "$out/error.txt"' ERR
adb root
adb wait-for-device
test "$(adb shell id -u | tr -d '\r')" = 0
apk_signer="$ANDROID_HOME/build-tools/36.0.0/apksigner"
for apk in "$state"/{r43,r44}.apk; do
    "$apk_signer" verify --verbose --print-certs "$apk" | tee -a "$out/signatures.txt" |
        grep -F 'Signer #1 certificate SHA-256 digest: faedbe8483532ebb1412bf4d8387c36ff6bbcd4b1da560ba0eabbaea9bad49fb'
done
python3 - "$state/r44.apk" "$APP_SHA" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as apk:
    assert apk.testzip() is None
    for abi in ('arm64-v8a','armeabi-v7a','x86_64'):
        data=apk.read(f'lib/{abi}/libapp.so')
        assert sys.argv[2].encode() in data and b'HUMAN_DIAGNOSTIC' in data
PY
adb install "$state/r43.apk" | tee "$out/r48-install.txt"
adb shell wm dismiss-keyguard
adb shell am start -W -n com.fluvi.app/.MainActivity | tee "$out/r48-launch.txt"
db=/data/user/0/com.fluvi.app/databases/fluvi_core.db
for i in $(seq 1 10); do
    if adb shell test -f "$db"; then break; fi
    sleep 1
done
adb shell test -f "$db"
adb shell am force-stop com.fluvi.app
adb pull "$db" "$state/seed.db" >/dev/null
if adb shell test -f "$db-wal"; then adb pull "$db-wal" "$state/seed.db-wal" >/dev/null; fi
python3 - "$state/seed.db" <<'PY'
import sqlite3,sys
with sqlite3.connect(sys.argv[1]) as db:
    db.execute('PRAGMA wal_checkpoint(TRUNCATE)')
    db.execute('PRAGMA journal_mode=DELETE')
    db.execute('PRAGMA foreign_keys=ON')
    db.execute('CREATE TABLE r49_fixture_sentinel (value TEXT NOT NULL)')
    db.execute('INSERT INTO r49_fixture_sentinel VALUES (?)', ('r49-disposable-update',))
    category = db.execute('SELECT id FROM fluvi_categories ORDER BY is_system_uncategorized DESC LIMIT 1').fetchone()
    assert category is not None, 'R48 did not initialize the ordinary category model'
    category_id = category[0]
    db.execute('''
        INSERT INTO fluvi_partners (id,original_name,default_category_id,created_at_utc_ms,updated_at_utc_ms)
        VALUES ('r49-upgrade-partner', 'R49 test partner', ?, 1795734000000, 1795734000000)
    ''', (category_id,))
    db.execute('''
        INSERT INTO fluvi_ledger_entries
            (id,partner_id,category_id,category_assignment_mode,note,direction,amount_scaled_100,
             booked_local_epoch_day,booked_local_time_minutes,occurred_at_utc_ms,origin_kind,
             created_at_utc_ms,updated_at_utc_ms,revision)
        VALUES ('01JN8F4K1P0000000000000001','r49-upgrade-partner',?,'partnerDefault','R49 disposable fixture',
                'expense',94200,20784,600,1795734000000,'manual',1795734000000,1795734000000,1)
    ''', (category_id,))
    assert not db.execute('PRAGMA foreign_key_check').fetchall()
    print('Original ledger rows', db.execute('SELECT count(*) FROM fluvi_ledger_entries').fetchone()[0])
PY
adb push "$state/seed.db" /data/local/tmp/r49-seed.db >/dev/null
adb shell "cat /data/local/tmp/r49-seed.db > '$db'; rm -f '$db-wal' '$db-shm' /data/local/tmp/r49-seed.db"
cat > "$state/prefs.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<map><boolean name="enabled" value="true" /><string name="route">WIDGETS_ANYWHERE</string></map>
XML
adb push "$state/prefs.xml" /data/local/tmp/r49-prefs.xml >/dev/null
legacy=(fluvi_lock_screen_card fluvi_lock_screen_card_content fluvi_native_keyguard_card
    fluvi_native_keyguard_card_diagnostics fluvi_keyguard_header_material fluvi_keyguard_r448_display_route
    fluvi_keyguard_r448_comparison fluvi_keyguard_orb_diagnostic_route fluvi_r38_reference_admission
    fluvi_r444_flag_recovery fluvi_r29_reference_ownership fluvi_r46_recording)
preserve=(fluvi_financial_snapshot_widget fluvi_home_orb_configurations fluvi_runtime_monitoring)
for pref in "${legacy[@]}" "${preserve[@]}"; do
    adb shell "run-as com.fluvi.app sh -c 'mkdir -p shared_prefs; cp /data/local/tmp/r49-prefs.xml shared_prefs/$pref.xml'"
done
adb install -r "$state/r44.apk" | tee "$out/r49-update-install.txt"
adb shell am start -W -n com.fluvi.app/.MainActivity | tee "$out/r49-launch.txt"
grep -F 'Status: ok' "$out/r49-launch.txt"
adb shell pidof com.fluvi.app
basedir=/data/user/0/com.fluvi.app
for i in $(seq 1 10); do
    if adb shell test -f "$basedir/no_backup/fluvi-retired-lockscreen-v1"; then break; fi
    sleep 1
done
adb shell test -f "$basedir/no_backup/fluvi-retired-lockscreen-v1"
for pref in "${legacy[@]}"; do
    adb shell test ! -f "$basedir/shared_prefs/$pref.xml"
    echo "Retired $pref" >> "$out/migration.txt"
done
for pref in "${preserve[@]}"; do
    adb shell test -f "$basedir/shared_prefs/$pref.xml"
    printf 'Retained owned prefs %s\n' "$pref" >> "$out/migration.txt"
done
adb shell test ! -f "$basedir/no_backup/header-orb-sharing-v1"
if adb shell settings get secure enabled_accessibility_services | grep 'com\.fluvi\.app/tk\.zwander'; then
    echo 'New service unexpectedly enabled on install'
    exit 1
fi
adb shell am force-stop com.fluvi.app
adb pull "$db" "$state/after.db" >/dev/null
if adb shell test -f "$db-wal"; then adb pull "$db-wal" "$state/after.db-wal" >/dev/null; fi
python3 - "$state/seed.db" "$state/after.db" <<'PY' | tee "$out/ledger.txt"
import sqlite3,sys
with sqlite3.connect(sys.argv[1]) as original, sqlite3.connect(sys.argv[2]) as updated:
    assert updated.execute('SELECT value FROM r49_fixture_sentinel').fetchone() == ('r49-disposable-update',)
    ledger = 'SELECT * FROM fluvi_ledger_entries ORDER BY id'
    before, after = original.execute(ledger).fetchall(), updated.execute(ledger).fetchall()
    assert before == after, (len(before), len(after))
    assert updated.execute(
        "SELECT note,amount_scaled_100,revision FROM fluvi_ledger_entries WHERE id='01JN8F4K1P0000000000000001'"
    ).fetchone() == ('R49 disposable fixture',94200,1)
    print(f'Persisted database sentinel and {len(before)} unchanged pre-existing ledger rows')
PY
printf '%s\n' 'PASS signed R48 → R49 install -r, database sentinel, owned prefs and retired-state migration.' > "$out/result.txt"

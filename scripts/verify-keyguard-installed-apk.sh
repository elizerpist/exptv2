#!/usr/bin/env bash
set -euo pipefail

# Capture and verify the actual installed package, split list and byte hash.
# This helper is suitable for both pre-test and post-test receipts. It never
# replaces an instrumentation/compositor result with a package identity check.
[[ $# == 4 ]] || { echo 'usage: verify-keyguard-installed-apk.sh PACKAGE APK EVIDENCE_DIR LABEL' >&2; exit 64; }
package=$1
apk=$2
evidence=$3
label=$4
[[ -s "$apk" && -d "$evidence" && "$label" =~ ^[a-zA-Z0-9_-]+$ ]] || exit 64
prefix="$evidence/installed-$label"
printf 'package=%s\nsource_file=%s\n' "$package" "$apk" > "$prefix-identity.txt"

rc=0
adb shell pm path "$package" > "$prefix-path.raw" 2> "$prefix-path.stderr" || rc=$?
printf '%s\n' "$rc" > "$prefix-path.exit"
tr -d '\r' < "$prefix-path.raw" > "$prefix-path.txt"
[[ $rc == 0 ]] || { echo 'FAIL pm path command'; exit 1; }
[[ $(wc -l < "$prefix-path.txt") -eq 1 ]] || { echo 'FAIL package split list'; exit 1; }
installed_path=$(sed -n 's/^package://p' "$prefix-path.txt")
[[ "$installed_path" == /*/base.apk ]] || { echo 'FAIL installed base path'; exit 1; }

rc=0
adb shell pm list packages -f "$package" > "$prefix-packages.raw" 2> "$prefix-packages.stderr" || rc=$?
printf '%s\n' "$rc" > "$prefix-packages.exit"
tr -d '\r' < "$prefix-packages.raw" > "$prefix-packages.txt"
[[ $rc == 0 ]] || { echo 'FAIL package listing command'; exit 1; }
grep -Fxq "package:$installed_path=$package" "$prefix-packages.txt" || { echo 'FAIL installed package identity'; exit 1; }

expected=$(sha256sum "$apk" | cut -d ' ' -f 1)
rc=0
actual=$(timeout -k 2s 30s adb exec-out cat "$installed_path" | sha256sum | cut -d ' ' -f 1) || rc=$?
printf '%s\n' "$rc" > "$prefix-bytes.exit"
printf 'expected=%s installed=%s\n' "$expected" "${actual:-UNOBSERVED}" > "$prefix-sha256.txt"
[[ $rc == 0 && "$expected" == "$actual" ]] || { echo 'FAIL installed bytes'; exit 1; }
printf 'PASS package=%s path=%s sha256=%s\n' "$package" "$installed_path" "$actual"

#!/usr/bin/env bash
set -euo pipefail
script=$(cd "$(dirname "$0")" && pwd)/r47-paired-ci.sh
task_tmp=$(mktemp -d)
trap 'rm -rf "$task_tmp"' EXIT
mkdir -p "$task_tmp/work/baseline/android" "$task_tmp/work/app/android" "$task_tmp/bin" "$task_tmp/temp"
for arm in baseline app; do
 mkdir -p "$task_tmp/work/$arm/scripts"
 for file in test-keyguard-runtime.sh test-keyguard-service-trace.sh run-dashboard-profile.sh; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$task_tmp/work/$arm/scripts/$file"
 done
 printf '#!/usr/bin/env bash\nexit 0\n' > "$task_tmp/work/$arm/scripts/test-keyguard-native-diagnostic.sh"
 cat > "$task_tmp/work/$arm/android/gradlew" <<'GRADLE'
#!/usr/bin/env bash
mkdir -p ../build/app/outputs/apk/debug ../build/app/outputs/apk/androidTest/debug
printf 'debug' > ../build/app/outputs/apk/debug/app-debug.apk
printf 'test' > ../build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk
GRADLE
 chmod +x "$task_tmp/work/$arm/android/gradlew"
done
cat > "$task_tmp/bin/git" <<'GIT'
#!/usr/bin/env bash
if [[ "$1" == rev-parse ]]; then
 if [[ "$PWD" == */baseline ]]; then printf '%s\n' fd74df6057793f6fdd12e0ccb61a20bdbfdd7f20
 else printf '%s\n' af20365a5ec96ff92b35321a03c0a2679ee7d2fd; fi
fi
GIT
cat > "$task_tmp/bin/flutter" <<'FLUTTER'
#!/usr/bin/env bash
if [[ "$PWD" == */baseline && "${R47_FAKE_FAIL_BASELINE:-0}" == 1 ]]; then exit 7; fi
exit 0
FLUTTER
cat > "$task_tmp/bin/adb" <<'ADB'
#!/usr/bin/env bash
case "$*" in
 *'getprop ro.build.version.sdk'*) echo 35;;
 *'getprop ro.product.cpu.abi'*) echo x86_64;;
 *'pm path '*) exit 1;;
 *) echo ok;;
esac
ADB
chmod +x "$task_tmp/bin/"*
export PATH="$task_tmp/bin:$PATH" GITHUB_WORKSPACE="$task_tmp/work" RUNNER_TEMP="$task_tmp/temp" PAIR_KIND=native R47_FAKE_FAIL_BASELINE=1
if bash "$script" build-baseline; then echo 'baseline failure not detected' >&2; exit 1; fi
if bash "$script" run; then echo 'aggregate lost baseline failure' >&2; exit 1; fi
test "$(cat "$task_tmp/temp/r47-paired-native/baseline/build.exit")" = 7
test "$(cat "$task_tmp/temp/r47-paired-native/candidate/build.exit")" = 0
test "$(cat "$task_tmp/temp/r47-paired-native/candidate/helper.exit")" = 0
test "$(cat "$task_tmp/temp/r47-paired-native/candidate/runtime.exit")" = 0
printf 'PASS: baseline build failure retained and candidate still executed\n'

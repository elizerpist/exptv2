#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

fail() {
  printf 'Fluvi boundary violation: %s\n' "$1" >&2
  exit 1
}

for required_path in \
  pubspec.yaml \
  android/settings.gradle.kts \
  android/app/build.gradle.kts \
  android/fluvi-core/build.gradle.kts; do
  [[ -f "$required_path" ]] || fail "missing $required_path"
done

grep -Eq 'include\(.*":app"' android/settings.gradle.kts || \
  fail 'android settings must include :app'
grep -Eq 'include\(.*":fluvi-core"' android/settings.gradle.kts || \
  fail 'android settings must include :fluvi-core'
asset_declarations=$(grep -E '^[[:space:]]*-[[:space:]]+assets/' pubspec.yaml || true)
[[ -n "$asset_declarations" ]] || fail 'pubspec must declare a local Fluvi asset root'
if printf '%s\n' "$asset_declarations" | \
  grep -Eqv '^[[:space:]]*-[[:space:]]+assets/'; then
  fail 'pubspec must declare only local asset directories'
fi
grep -Eq 'https?://' pubspec.yaml && fail 'pubspec must not declare remote asset URLs'

source_matches() {
  local pattern=$1
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -n -i \
      --glob '!build/**' \
      --glob '*.dart' \
      --glob '*.java' \
      --glob '*.kt' \
      --glob '*.kts' \
      --glob '*.xml' \
      "$pattern" "$@"
  else
    grep -R -n -i -E \
      --exclude-dir=build \
      --include='*.dart' \
      --include='*.java' \
      --include='*.kt' \
      --include='*.kts' \
      --include='*.xml' \
      "$pattern" "$@"
  fi
}

if source_matches 'dev\.flutter|io\.flutter|com\.android\.application' \
  android/fluvi-core; then
  fail 'android:fluvi-core must remain Flutter and application-plugin free'
fi

if source_matches 'com\.exptv2|spendee|spendee_test' lib android/app; then
  fail 'Flutter and Android application sources must not reference legacy apps'
fi

if source_matches 'FluviCoreFactory|androidx\.room|RoomDatabase' \
  lib/features/dashboard; then
  fail 'the Flutter dashboard must not import the Android Room core'
fi

if source_matches 'androidx\.room|RoomDatabase|\b(DAO|SQL|sqlite)\b' \
  lib/features/dashboard/presentation lib/features/dashboard/widgets; then
  fail 'dashboard presentation/widgets must not own storage or SQL access'
fi

grep -Eq '^internal abstract class FluviDatabase' \
  android/fluvi-core/src/main/kotlin/com/fluvi/core/database/FluviDatabase.kt || \
  fail 'the Room database implementation must remain internal'
grep -Eq '^internal object FluviDatabaseFactory' \
  android/fluvi-core/src/main/kotlin/com/fluvi/core/database/FluviDatabaseFactory.kt || \
  fail 'the Room database factory must remain internal'
grep -Eq '^object FluviCoreFactory' \
  android/fluvi-core/src/main/kotlin/com/fluvi/core/FluviCore.kt || \
  fail 'the typed FluviCoreFactory facade must remain public'

printf '%s\n' 'Fluvi Flutter/core boundaries verified.'

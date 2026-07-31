#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

test -f android/settings.gradle.kts
test -f android/fluvi-core/build.gradle.kts

if rg -n \
  'dev\.flutter|io\.flutter|com\.exptv2|com\.android\.application|include\(":app"\)' \
  android .github README.md; then
  echo "Fluvi clean-room boundary violation in active build/source files." >&2
  exit 1
fi

if git ls-files | rg -n '^(lib|test|assets|web|android/app)/|^pubspec(\.lock)?\.yaml$'; then
  echo "Fluvi must not retain inherited Flutter/app source paths." >&2
  exit 1
fi

if ! rg -q '^internal abstract class FluviDatabase' \
  android/fluvi-core/src/main/kotlin/com/fluvi/core/database/FluviDatabase.kt || \
  ! rg -q '^internal object FluviDatabaseFactory' \
  android/fluvi-core/src/main/kotlin/com/fluvi/core/database/FluviDatabaseFactory.kt || \
  ! rg -q '^object FluviCoreFactory' \
  android/fluvi-core/src/main/kotlin/com/fluvi/core/FluviCore.kt; then
  echo "Fluvi must expose the typed core facade, not the raw Room implementation." >&2
  exit 1
fi

echo "Clean Fluvi core boundary verified."

#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

test -f android/settings.gradle.kts
test -f android/fluvi-core/build.gradle.kts

if [[ "${FLUVI_FORCE_GREP:-}" != "1" ]] && command -v rg >/dev/null 2>&1; then
  search_tree() { rg -n "$@"; }
  search_stream() { rg -n "$@"; }
  search_quiet() { rg -q "$@"; }
else
  search_tree() {
    grep -R -n -E \
      --exclude-dir=.gradle \
      --exclude-dir=.kotlin \
      --exclude-dir=build \
      "$@"
  }
  search_stream() { grep -n -E "$@"; }
  search_quiet() { grep -q -E "$@"; }
fi

if search_tree \
  'dev\.flutter|io\.flutter|com\.exptv2|com\.android\.application|include\(":app"\)' \
  android .github README.md; then
  echo "Fluvi clean-room boundary violation in active build/source files." >&2
  exit 1
fi

if git ls-files | search_stream '^(lib|test|assets|web|android/app)/|^pubspec(\.lock)?\.yaml$'; then
  echo "Fluvi must not retain inherited Flutter/app source paths." >&2
  exit 1
fi

if ! search_quiet '^internal abstract class FluviDatabase' \
  android/fluvi-core/src/main/kotlin/com/fluvi/core/database/FluviDatabase.kt || \
  ! search_quiet '^internal object FluviDatabaseFactory' \
  android/fluvi-core/src/main/kotlin/com/fluvi/core/database/FluviDatabaseFactory.kt || \
  ! search_quiet '^object FluviCoreFactory' \
  android/fluvi-core/src/main/kotlin/com/fluvi/core/FluviCore.kt; then
  echo "Fluvi must expose the typed core facade, not the raw Room implementation." >&2
  exit 1
fi

echo "Clean Fluvi core boundary verified."

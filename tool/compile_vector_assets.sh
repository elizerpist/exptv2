#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dart_executable=${DART_BIN:-dart}

cd "$repo_root"

compile_directory() {
  source_directory=$1
  "$dart_executable" run vector_graphics_compiler \
    --input-dir "$source_directory" \
    --out-dir "$source_directory"
}

compile_directory assets/category_icons
compile_directory assets/fluvi/actions
compile_directory assets/fluvi/brand

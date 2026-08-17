#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dart_executable=${DART_BIN:-dart}
python_executable=${PYTHON_BIN:-python3}

cd "$repo_root"

compile_directory() {
  source_directory=$1
  "$dart_executable" run vector_graphics_compiler \
    --input-dir "$source_directory" \
    --out-dir "$source_directory"
}

"$python_executable" tool/generate_category_catalog.py --write-logbox-sources
compile_directory assets/category_icons
compile_directory assets/logbox_category_icons
compile_directory assets/fluvi/actions
compile_directory assets/fluvi/brand
compile_directory assets/fluvi/budget
"$python_executable" tool/generate_category_catalog.py

#!/usr/bin/env sh
# Generate a graph for the exact clean source checkout that invokes this file.
# This script intentionally does not commit, push, or build the application.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(git -C "$script_dir/../.." rev-parse --show-toplevel)

if ! git -C "$repo_root" diff --quiet ||
  ! git -C "$repo_root" diff --cached --quiet; then
  echo "Refusing to index tracked source changes." >&2
  exit 65
fi

source_head=$(git -C "$repo_root" rev-parse HEAD)
source_ref=$(git -C "$repo_root" branch --show-current)
if [ -z "$source_ref" ]; then
  source_ref=$source_head
fi

cd "$repo_root"
dart pub get

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "dart pub get changed tracked source files; refusing to index." >&2
  exit 65
fi

dart pub global run scip_dart ./
index_sha256=$(sha256sum index.scip | awk '{print $1}')

cd "$script_dir"
dart run bin/fluvi_codegraph.dart generate \
  --index "$repo_root/index.scip" \
  --graph "$repo_root/docs/codegraph" \
  --source-head "$source_head" \
  --source-ref "$source_ref" \
  --expected-index-sha256 "$index_sha256"

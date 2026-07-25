#!/usr/bin/env sh
set -eu

usage() {
  echo "Usage: $0 REFERENCE.png APP.png OUTPUT_PREFIX" >&2
}

if [ "$#" -ne 3 ]; then
  usage
  exit 64
fi

reference=$1
app=$2
output_prefix=$3

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick 7 ('magick') is required." >&2
  exit 69
fi

for input in "$reference" "$app"; do
  if [ ! -f "$input" ]; then
    echo "Input does not exist: $input" >&2
    exit 66
  fi
done

reference_size=$(magick identify -format '%wx%h' "$reference")
app_size=$(magick identify -format '%wx%h' "$app")
if [ "$reference_size" != "$app_size" ]; then
  echo "Input dimensions differ: reference=$reference_size app=$app_size" >&2
  exit 65
fi

output_dir=$(dirname "$output_prefix")
mkdir -p "$output_dir"

overlay="${output_prefix}-overlay-50.png"
side_by_side="${output_prefix}-side-by-side.png"

magick "$reference" "$app" -evaluate-sequence mean "$overlay"
magick "$reference" "$app" +append "$side_by_side"

compare_metric() {
  metric_name=$1
  set +e
  metric_value=$(magick compare -metric "$metric_name" \
    "$reference" "$app" null: 2>&1)
  metric_status=$?
  set -e
  if [ "$metric_status" -ne 0 ] && [ "$metric_status" -ne 1 ]; then
    echo "ImageMagick comparison failed for $metric_name." >&2
    exit "$metric_status"
  fi
  echo "$metric_value"
}

ae=$(compare_metric AE)
rmse=$(compare_metric RMSE)

echo "reference_size=$reference_size"
echo "ae=$ae"
echo "rmse=$rmse"
sha256sum "$reference" "$app" "$overlay" "$side_by_side"

#!/bin/sh
set -eu

usage() {
  echo "Usage: $0 --check <checklist-path>" >&2
  exit 2
}

if [ "$#" -ne 2 ] || [ "$1" != "--check" ]; then
  usage
fi

checklist=$2
if [ ! -f "$checklist" ]; then
  echo "Balance V3 release gate: checklist not found: $checklist" >&2
  exit 2
fi

frozen_html_sha='ff7a00a7aeae8f636b08611443bd3975aec1303828ae5c80bce253ae1d29a2ed'
failed=0
index=1

while [ "$index" -le 12 ]; do
  suffix=$(printf '%03d' "$index")
  id="BUGFIX-20260726V3-$suffix"

  row_count=$(awk -F '|' -v id="$id" '
    /^[[:space:]]*\|/ {
      field = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", field)
      if (field == id) {
        count++
      }
    }
    END { print count + 0 }
  ' "$checklist")

  if [ "$row_count" -ne 1 ]; then
    echo "Balance V3 release gate: $id must have exactly one checklist row (found $row_count)" >&2
    failed=1
    index=$((index + 1))
    continue
  fi

  status=$(awk -F '|' -v id="$id" '
    /^[[:space:]]*\|/ {
      field = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", field)
      if (field == id) {
        for (column = NF; column >= 1; column--) {
          value = $column
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
          if (value != "") {
            print value
            exit
          }
        }
      }
    }
  ' "$checklist")

  if [ "$status" != "DONE" ]; then
    echo "Balance V3 release gate: $id status must be DONE (found ${status:-missing})" >&2
    failed=1
  fi

  missing_fields=$(awk -v id="$id" -v frozen_html_sha="$frozen_html_sha" '
    $0 == "### Evidence — " id {
      in_evidence = 1
      evidence_sections++
      next
    }
    in_evidence && /^### Evidence — / {
      in_evidence = 0
    }
    in_evidence && /^[[:space:]]*-[[:space:]]+Evidence command:[[:space:]]*[^[:space:]]/ {
      commands++
    }
    in_evidence && /^[[:space:]]*-[[:space:]]+Evidence result:[[:space:]]*[^[:space:]]/ {
      results++
    }
    in_evidence && /^[[:space:]]*-[[:space:]]+Evidence SHA:[[:space:]]*[^[:space:]]/ {
      sha_value = $0
      sub(/^[[:space:]]*-[[:space:]]+Evidence SHA:[[:space:]]*/, "", sha_value)
      gsub(/[[:space:]]+$/, "", sha_value)
      shas++
      if (sha_value != frozen_html_sha && sha_value != "`" frozen_html_sha "`") {
        invalid_sha = 1
      }
    }
    function add_missing(label) {
      if (missing != "") {
        missing = missing ", "
      }
      missing = missing label
    }
    END {
      if (evidence_sections != 1) {
        add_missing("Evidence section")
      }
      if (commands != 1) {
        add_missing("Evidence command")
      }
      if (results != 1) {
        add_missing("Evidence result")
      }
      if (shas != 1) {
        add_missing("Evidence SHA")
      }
      if (invalid_sha) {
        add_missing("Evidence SHA (must equal frozen HTML SHA " frozen_html_sha ")")
      }
      if (missing != "") {
        print missing
      }
    }
  ' "$checklist")

  if [ -n "$missing_fields" ]; then
    echo "Balance V3 release gate: $id missing $missing_fields" >&2
    failed=1
  fi

  index=$((index + 1))
done

if [ "$failed" -ne 0 ]; then
  echo "Balance V3 release gate: rejected $checklist" >&2
  exit 1
fi

echo "Balance V3 release gate: accepted $checklist"

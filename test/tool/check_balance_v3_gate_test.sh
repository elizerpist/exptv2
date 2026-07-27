#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
gate="$repo_root/tool/check_balance_v3_gate.sh"
fixtures="$script_dir/fixtures"
canonical="$repo_root/docs/superpowers/checklists/bugfix20260726v3.md"
valid_fixture="$fixtures/v3-resolved-with-evidence.md"
fixture_dir=$(mktemp -d "${TMPDIR:-/tmp}/balance-v3-gate.XXXXXX")
trap 'rm -rf "$fixture_dir"' EXIT HUP INT TERM

expect_reject() {
  description=$1
  checklist=$2

  if "$gate" --check "$checklist"; then
    echo "expected gate to reject: $description" >&2
    exit 1
  fi
}

expect_reject "an unresolved V3 checklist row" "$fixtures/v3-unresolved.md"
expect_reject "a DONE row without its own Evidence SHA field" \
  "$fixtures/v3-resolved-missing-evidence.md"

blocked_fixture="$fixture_dir/v3-resolved-blocked.md"
sed 's/^| BUGFIX-20260726V3-003 | fixture | fixture | DONE |$/| BUGFIX-20260726V3-003 | fixture | fixture | BLOCKED |/' \
  "$valid_fixture" > "$blocked_fixture"
expect_reject "a BLOCKED V3 checklist row with otherwise complete evidence" \
  "$blocked_fixture"

missing_id_fixture="$fixture_dir/v3-resolved-missing-id.md"
sed '/^| BUGFIX-20260726V3-006 | fixture | fixture | DONE |$/d' \
  "$valid_fixture" > "$missing_id_fixture"
expect_reject "a missing required V3 checklist row" "$missing_id_fixture"

duplicate_id_fixture="$fixture_dir/v3-resolved-duplicate-id.md"
duplicate_row='| BUGFIX-20260726V3-007 | fixture | fixture | DONE |'
awk -v duplicate_row="$duplicate_row" '
  { print }
  $0 == duplicate_row { print }
' "$valid_fixture" > "$duplicate_id_fixture"
expect_reject "a duplicate required V3 checklist row" "$duplicate_id_fixture"

borrowed_evidence_fixture="$fixture_dir/v3-resolved-borrowed-evidence.md"
awk '
  $0 == "### Evidence — BUGFIX-20260726V3-009" {
    omit = 1
    next
  }
  omit && /^### Evidence — / {
    omit = 0
  }
  !omit { print }
' "$valid_fixture" > "$borrowed_evidence_fixture"
expect_reject "a DONE V3-009 row that tries to borrow V3-008 evidence" \
  "$borrowed_evidence_fixture"

invalid_sha_fixture="$fixture_dir/v3-resolved-invalid-sha.md"
awk '
  $0 == "### Evidence — BUGFIX-20260726V3-010" {
    in_target = 1
  }
  in_target && /^### Evidence — / && $0 != "### Evidence — BUGFIX-20260726V3-010" {
    in_target = 0
  }
  in_target && /^- Evidence SHA:/ {
    print "- Evidence SHA: `x`"
    next
  }
  { print }
' "$valid_fixture" > "$invalid_sha_fixture"
expect_reject "a non-SHA Evidence SHA value" "$invalid_sha_fixture"

"$gate" --check "$valid_fixture"
"$gate" --check "$canonical"

echo "Balance V3 gate shell tests passed"

#!/usr/bin/env bash
set -euo pipefail
# The candidate executes the same stock-compatible probe, but its oracle
# requires genuine read-ahead and green ordered application, not stock RED.
: "${FLUVI_R12_EXPECTED_APP_SHA:?set the exact candidate source SHA}"
export FLUVI_R12_ADMISSION_MODE=candidate
exec bash "$(dirname "$0")/test-keyguard-r12-admission-baseline.sh"

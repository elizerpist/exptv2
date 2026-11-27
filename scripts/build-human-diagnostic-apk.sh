#!/usr/bin/env bash
set -euo pipefail

export FLUVI_BUILD_PURPOSE=human_diagnostic
export FLUVI_SEED_DEMO="${FLUVI_HUMAN_SEED_DEMO:-false}"
export FLUVI_PHYSICAL_RAIL_DIAGNOSTICS=true
export FLUVI_ONSCREEN_DIAGNOSTICS=true
exec "$(dirname "${BASH_SOURCE[0]}")/build-r49-android.sh" profile

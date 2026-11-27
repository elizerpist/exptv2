#!/usr/bin/env python3
"""Preflight controls for the selected R50 contracts on an exact checkout."""
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
def read(path):
    return (root / path).read_text()

checks = [
    ("settings uses the Android accessibility entry",
     "Android kisegítő lehetőségek" in read("lib/features/header_orb/presentation/header_orb_setup_page.dart")
     and "openSetup" not in read("lib/features/header_orb/presentation/header_orb_setup_page.dart")),
    ("whole upstream application absent",
     not (root / "third_party/widgets-anywhere").exists()),
    ("Balance publisher independent of visible dashboard mode",
     "activeMode.committedMode" not in read("lib/app/platform/dashboard_header_widget_publisher.dart")
     and "isVisible()" not in read("lib/app/platform/dashboard_header_widget_publisher.dart")),
]
for label, ok in checks:
    print(f"{'PASS' if ok else 'FAIL'} {label}")
sys.exit(0 if all(ok for _, ok in checks) else 1)

#!/usr/bin/env python3
"""Fail on a dependency change in the shipped Flutter module."""
from pathlib import Path
import re
import sys


def packages(filename):
    body = Path(filename).read_text().split("packages:\n", 1)[1].split("\nsdks:", 1)[0]
    rows = re.split(r"(?m)^  ([a-zA-Z0-9_]+):\n", body)
    return {
        name: "\n".join(line for line in stanza.splitlines() if not line.startswith("    dependency: "))
        for name, stanza in zip(rows[1::2], rows[2::2])
    }


original, staged = map(packages, sys.argv[1:])
assert staged and set(staged) <= set(original)
assert all(staged[name] == original[name] for name in staged)
assert "integration_test" in original and "integration_test" not in staged
print("Flutter payload lock: all retained package sources, versions and content hashes match.")

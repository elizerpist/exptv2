#!/usr/bin/env python3
"""Fail closed if the R15 ref shadows stock or the declared cases drift."""
import json
import re
from pathlib import Path

workflow = Path('.github/workflows/fluvi-core.yml').read_text()
collector = Path('scripts/test-keyguard-r14-candidate.sh').read_text()
prefix = 'fluvi-r15-first-acquisition-'
assert workflow.count("startsWith(github.ref_name, '" + prefix + "')") == 3
matrix_line = next(line for line in workflow.splitlines() if 'case: ${{ fromJSON' in line)
arrays = [json.loads(value) for value in re.findall(r"'(\[[^']+\])'", matrix_line)]
assert len(arrays) == 5
historical, holder, export, r15, ordinary = arrays
assert historical == ['exclusion', 'fresh-main', 'late-only', 'real-return']
assert holder == ['r15-held-canvas']
assert r15 == ordinary + ['r15-phone-light', 'r15-phone-full', 'r15-stale-owner', 'r15-first-live']
assert export == ['r15-phone-light', 'r15-phone-full', 'r15-stale-owner', 'pressure-light', 'pressure-full',
                  'pressure-combined', 'paired-light', 'paired-full', 'deferred-light', 'deferred-full']
case_block = collector.split("<<'CASES'", 1)[1].split('\nCASES', 1)[0]
lines = [line.split(maxsplit=1) for line in case_block.strip().splitlines()]
mapping = dict(lines)
assert len(mapping) == len(lines)
assert all(case in mapping for case in r15)
assert all(case in mapping for case in export)
assert mapping['r15-held-canvas'].endswith('#r15EnteredCanvasSurvivesActualServiceWithdrawal')
assert mapping['r15-phone-light'].endswith('#r15PhoneShapeKeepsFinancialAndActualWithdrawalLight')
assert mapping['r15-phone-full'].endswith('#r15PhoneShapeKeepsFinancialAndActualWithdrawalFull')
assert "startsWith(github.ref_name, 'fluvi-r14-wiring-') && 'b6c71cfc350819e9a10a33e3e4cb6e078a4198d9' || github.sha" in workflow
assert prefix not in workflow[workflow.index('script: >-'):workflow.index('Analyze bounded production overlay trace')]
print('PASS R15 routing: 16 full, 10 export, one holder selector, historic four-case mapping and stock dispatcher negative')

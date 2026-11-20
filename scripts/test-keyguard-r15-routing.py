#!/usr/bin/env python3
"""Fail closed if the R15 ref shadows stock or the declared cases drift."""
import json
import re
from pathlib import Path

workflow = Path('.github/workflows/fluvi-core.yml').read_text()
collector = Path('scripts/test-keyguard-r14-candidate.sh').read_text()
service_collector = Path('scripts/test-keyguard-r12-candidate.sh').read_text()
service_test = Path('android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR15ServiceContractInstrumentationTest.kt').read_text()
prefix = 'fluvi-r15-first-acquisition-'
assert workflow.count("startsWith(github.ref_name, '" + prefix + "')") == 3
matrix_line = next(line for line in workflow.splitlines() if 'case: ${{ fromJSON' in line)
arrays = [json.loads(value) for value in re.findall(r"'(\[[^']+\])'", matrix_line)]
assert len(arrays) == 7
historical, comparison, motion, holder, export, r15, ordinary = arrays
assert historical == ['exclusion', 'fresh-main', 'late-only', 'real-return']
assert comparison == ['r15-ab-comparison']
assert motion == ['r15-motion-red', 'r15-combined-recovery', 'r15-held-timeout', 'r15-motion-service']
assert holder == ['r15-held-canvas']
assert r15 == ordinary + ['r15-phone-light', 'r15-phone-full', 'r15-stale-owner', 'r15-first-live', 'r15-combined-recovery']
assert export == ['r15-phone-light', 'r15-phone-full', 'r15-stale-owner', 'pressure-light', 'pressure-full',
                  'pressure-combined', 'paired-light', 'paired-full', 'deferred-light', 'deferred-full']
case_block = collector.split("<<'CASES'", 1)[1].split('\nCASES', 1)[0]
lines = [line.split(maxsplit=1) for line in case_block.strip().splitlines()]
mapping = dict(lines)
assert len(mapping) == len(lines)
assert all(case in mapping for case in r15)
assert all(case in mapping for case in export)
assert all(case in mapping for case in motion)
assert mapping['r15-motion-red'].endswith('#r15DetachedMotionOffRevokesPreparedLiveEligibility')
assert mapping['r15-combined-recovery'].endswith('#r14PairedRecoveryEdgesRemainOwnedUnderPressureAndRotation')
assert mapping['r15-held-timeout'].endswith('#r15HeldCanvasTimeoutIsIncompleteAndReleasesIndependently')
assert mapping['r15-motion-service'].endswith('#r15MotionOffInvalidatesIssuedServiceOpportunity')
assert 'fun firstCorrectServiceComposite()' in service_test
assert 'KeyguardR15ServiceContractInstrumentationTest#firstCorrectServiceComposite' in service_collector
assert 'first_composite_fixture' in service_collector and 'r12_real_service_first_composite' in service_collector
assert 'fun serviceDowngradeRevokesOldFull()' in service_test
assert 'KeyguardR15ServiceContractInstrumentationTest#serviceDowngradeRevokesOldFull' in service_collector
assert 'fun realHolderRevocationAcrossGeneration()' in service_test
assert 'KeyguardR15ServiceContractInstrumentationTest#realHolderRevocationAcrossGeneration' in service_collector
assert 'fun stableServiceMainConfirmationsDoNotDemandBitmaps()' in service_test
assert 'KeyguardR15ServiceContractInstrumentationTest#stableServiceMainConfirmationsDoNotDemandBitmaps' in service_collector
assert 'fun routeSelectionSurvivesReattachAndRestart()' in service_test
assert 'KeyguardR15ServiceContractInstrumentationTest#routeSelectionSurvivesReattachAndRestart' in service_collector
assert 'selectorPhase' in service_collector and 'PRE_FIXTURE_READ' in service_test
assert "run_test r12_ordered 'com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply'" in service_collector
assert "run_test r12_occlusion 'com.fluvi.app.lockscreen.KeyguardServiceOverlayInstrumentationTest#connectedProductionServiceRendersPortalOrbAcrossRealKeyguardCycles'" in service_collector
assert workflow.index("startsWith(github.ref_name, 'fluvi-r15-first-acquisition-motion-controls-')") < workflow.rindex("startsWith(github.ref_name, 'fluvi-r15-first-acquisition-')")
assert workflow.index("startsWith(github.ref_name, 'fluvi-r15-first-acquisition-validation-')") < workflow.rindex("startsWith(github.ref_name, 'fluvi-r15-first-acquisition-')")
assert 'bash scripts/test-keyguard-r15-comparison-device.sh' in workflow
assert mapping['r15-held-canvas'].endswith('#r15EnteredCanvasSurvivesActualServiceWithdrawal')
assert mapping['r15-phone-light'].endswith('#r15PhoneShapeKeepsFinancialAndActualWithdrawalLight')
assert mapping['r15-phone-full'].endswith('#r15PhoneShapeKeepsFinancialAndActualWithdrawalFull')
assert "startsWith(github.ref_name, 'fluvi-r14-wiring-') && 'b6c71cfc350819e9a10a33e3e4cb6e078a4198d9' || github.sha" in workflow
assert prefix not in workflow[workflow.index('script: >-'):workflow.index('Analyze bounded production overlay trace')]
print('PASS R15 routing: 17 full, 10 export, one holder selector, historic four-case mapping and stock dispatcher negative')

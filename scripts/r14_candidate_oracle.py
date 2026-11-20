#!/usr/bin/env python3
"""Fail-closed candidate verdict from one real-service specimen and export."""
import argparse
import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location('stock_oracle', Path(__file__).with_name('r14_stock_oracle.py'))
stock = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stock)


def evaluate(case, fixture, queue, root, source, run_id, raw, capture):
    errors = stock.evaluate(case, fixture, queue, root, source, run_id, raw)
    if case != 'late-only':
        stock_only = {'stock_add_or_actual_decision_missing', 'stock_generation', 'stock_red_not_observed',
                      'removal_marks_missing:successor-withdrawal-marks.txt',
                      'removal_not_correlated:successor-withdrawal-marks.txt'}
        errors = [error for error in errors if error not in stock_only]
    rows = {}
    for line in fixture.splitlines():
        row = stock.fields(line)
        if row.get('stage'):
            rows.setdefault(row['stage'], []).append(row)
    def one(stage):
        found = rows.get(stage, [])
        return found[0] if len(found) == 1 else {}
    g1, a, boundary, result = (one(x) for x in ('G1_WITHDRAWN', 'A_HELD', 'A_DECISION', 'RESULT'))
    req, pending = a.get('req'), boundary.get('pending')
    gen = stock.integer(g1.get('attach'))
    if not capture.startswith('FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n') or f'build={source}\n' not in capture:
        errors.append('capture_identity')
    if 'omittedCriticalRecordIds=none\n' not in capture:
        errors.append('capture_critical_omission')
    edges = [stock.fields(line) for line in capture.splitlines() if line.startswith(' R14_RECOVERY ')]
    deferred = [r for r in edges if r.get('phase') == 'DEFERRED' and r.get('r14DeferredA') == req]
    if case != 'late-only':
        if boundary.get('actualAttached') != 'false' or gen is None or stock.integer(boundary.get('attach')) != gen:
            errors.append('a_not_detached_at_decision')
        if len(deferred) != 1:
            errors.append('exact_deferred_edge_missing')
        else:
            edge = deferred[0]
            if not (edge.get('r14OriginalB') == edge.get('r14Pending') == pending and edge.get('r14Origin') == 'systemUi'
                    and edge.get('r14PreviousAttach') == g1.get('attach') and stock.integer(edge.get('r14PreviousHide'))
                    and edge.get('r14Physical') == 'UNOBSERVED'):
                errors.append('deferred_identity_mismatch')
            hide_id = edge.get('r14PreviousHide')
            if not any(line.startswith(' WITHDRAWAL ') and f'hideOp={hide_id} ' in line and
                       f"req={g1.get('request')} " in line and 'attachedBefore=true' in line
                       for line in capture.splitlines()):
                errors.append('previous_hide_owner_unproved')
        if any(line.startswith(' EPISODE ') and f'req={req} ' in line for line in capture.splitlines()):
            errors.append('deferred_a_created_show')
        expected_successor = 'SUCCESSOR_HIDDEN_OCCLUDED' if case == 'exclusion' else 'SUCCESSOR_SHOW_FULL'
        if not any(row.get('phase') == expected_successor and row.get('r14DeferredA') == req for row in edges):
            errors.append('successor_outcome_missing')
        final_gen = stock.integer(result.get('finalGeneration'))
        if case == 'exclusion' and (result.get('finalAttached') != 'false' or final_gen != gen):
            errors.append('candidate_excess_attachment')
        if case == 'fresh-main' and (result.get('finalAttached') != 'true' or gen is None or final_gen != gen + 1):
            errors.append('candidate_fresh_return_missing')
    else:
        if deferred:
            errors.append('late_only_a_deferred')
        late = one('LATE_WITHDRAWN')
        read_rows = {stock.integer(row.get('read')): row for row in map(stock.fields, queue.splitlines()) if row.get('read')}
        read = read_rows.get(stock.integer(late.get('request')), {})
        if not (late.get('decision') in ('HIDDEN_UNKNOWN', 'HIDDEN_OCCLUDED') and
                read.get('applied') == read.get('decision') == late.get('decision') and
                read.get('stale') == 'false' and stock.integer(read.get('start')) == stock.integer(late.get('start'))):
            errors.append('late_actual_withdrawal_unproved')
    if 'OK (1 test)' not in raw or 'FAILURES!!!' in raw:
        errors.append('instrumentation_not_passed')
    return errors


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--case', choices=('exclusion', 'fresh-main', 'late-only'), required=True)
    for name in ('fixture', 'queue', 'raw', 'capture'):
        p.add_argument('--' + name, type=Path, required=True)
    p.add_argument('--source', required=True)
    p.add_argument('--run-id', required=True)
    a = p.parse_args()
    try:
        errors = evaluate(a.case, a.fixture.read_text(), a.queue.read_text(), a.fixture.parent,
                          a.source, a.run_id, a.raw.read_text(), a.capture.read_text())
    except (OSError, UnicodeError, ValueError) as exc:
        errors = ['evidence_unavailable:' + str(exc)]
    print('VALID_CANDIDATE_CONTROL' if not errors else 'INVALID_OR_NOT_ESTABLISHED')
    for error in errors:
        print('  ' + error)
    return 1 if errors else 0

if __name__ == '__main__':
    raise SystemExit(main())

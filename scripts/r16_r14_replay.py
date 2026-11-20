#!/usr/bin/env python3
"""Typed, fail-closed replay of the five archived R14 recovery cases.

An instrumentation PASS is only an input. These checks bind actual recorded
requests, authority, capture and independent window samples. They establish
neither a current-source result nor physical ORB presentation.
"""
from __future__ import annotations
import importlib.util
import re
import struct
import uuid
import zlib
from pathlib import Path


def _module(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    obj = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(obj)
    return obj


candidate = _module('r14candidate', 'r14_candidate_oracle.py')
stock = candidate.stock
CASES = {'r14_exclusion': 'exclusion', 'r14_fresh_main': 'fresh-main',
         'r14_late_only': 'late-only', 'r14_real_occlusion': 'real-return',
         'r14_terminal_stale': 'terminal-stale'}


def number(value: object) -> int | None:
    try:
        return int(str(value))
    except (ValueError, TypeError):
        return None


def local(root: Path, name: str) -> Path:
    path = (root / name).resolve()
    if not path.is_relative_to(root.resolve()) or not path.is_file():
        raise ValueError('missing_or_external_image:' + name)
    return path


def green_witness(root: Path, witness: dict[str, str]) -> list[str]:
    errors: list[str] = []
    names = [witness.get(key, '') for key in ('before', 'reference', 'screenshot')]
    if (len(set(names)) != 3 or witness.get('kind') != 'actual_foreign_test_window'
            or witness.get('visual') != 'true' or witness.get('locked') != 'true'
            or witness.get('display') != '0' or not number(witness.get('window'))):
        errors.append('green_owner_or_paths')
    try:
        before, reference, screenshot = [stock.png_center(local(root, name)) for name in names]
        if not (reference[:2] == (32, 32) and stock.green_count(reference[2]) >= 1000
                and before[:2] == screenshot[:2]
                and stock.green_count(before[2]) < 16 and stock.green_count(screenshot[2]) >= 900):
            errors.append('green_pixels_not_established')
    except (OSError, ValueError, IndexError, struct.error, zlib.error):
        errors.append('green_image_missing_or_invalid')
    return errors


def extract(row: str, fixture: str, queue: str, capture: str, root: Path,
            source: str, run_id: str, pid: int, raw: str) -> tuple[dict, list[str], list[str]]:
    """Return result, errors, original image names. Input text must be original bytes."""
    if row not in CASES:
        raise ValueError('unsupported_r14_case')
    errors: list[str] = []
    result: dict = {'kind': 'RESULT', 'row': row, 'status': 'NOT_ESTABLISHED',
                    'meaning': 'archived_service_control_not_physical_orb'}
    images: list[str] = []
    stages: dict[str, list[dict[str, str]]] = {}
    for line in fixture.splitlines():
        item = stock.fields(line)
        if item.get('stage'):
            stages.setdefault(item['stage'], []).append(item)

    def one(stage: str) -> dict[str, str]:
        found = stages.get(stage, [])
        if len(found) != 1:
            errors.append('missing_or_duplicate_' + stage.lower())
            return {}
        return found[0]

    def require(value: object, message: str):
        if not value:
            errors.append(message)

    def entries(prefix: str) -> list[dict[str, str]]:
        return [stock.fields(line) for line in capture.splitlines() if line.startswith(prefix)]

    run = one('RUN')
    require(run.get('source') == source and run.get('run') == run_id and
            run.get('case') == CASES[row] and number(run.get('pid')) == pid and
            run.get('mode') == 'SURFACE_LIVE', 'fixture_identity')
    ids = re.findall(r'(?m)^captureId=([^\n]+)$', capture)
    try:
        valid_id = len(ids) == 1 and str(uuid.UUID(ids[0])) == ids[0]
    except ValueError:
        valid_id = False
    require(capture.startswith('FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n') and
            f'build={source}\n' in capture and 'captureState=FROZEN\n' in capture and
            f'pid={pid}\n' in capture and f'processInstance={pid}-' in capture and
            'omittedCriticalRecordIds=none\n' in capture and
            capture.rstrip().endswith('END_FLUVI_KEYGUARD_TIMING_CAPTURE_V1') and valid_id,
            'capture_identity_or_critical_coverage')
    if valid_id:
        result['capture_id'] = ids[0]
    require('CLEANUP_OK' in fixture and 'CLEANUP_FAIL' not in fixture, 'cleanup_unproved')

    episodes, withdrawals = entries(' EPISODE '), entries(' WITHDRAWAL ')
    if row in {'r14_exclusion', 'r14_fresh_main', 'r14_late_only'}:
        errors.extend(candidate.evaluate(CASES[row], fixture, queue, root, source, run_id, raw, capture))
        g1, held, decision = (one(stage) for stage in ('G1_WITHDRAWN', 'A_HELD', 'A_DECISION'))
        a, old_attach = number(held.get('req')), number(g1.get('attach'))
        prior = [r for r in withdrawals if number(r.get('attach')) == old_attach and
                 number(r.get('req')) == number(g1.get('request')) and r.get('attachedBefore') == 'true']
        require(len(prior) == 1 and number(prior[0].get('hideOp')) is not None, 'prior_withdrawal_identity')
        offers = {number(r.get('offer')): r for r in map(stock.fields, queue.splitlines()) if number(r.get('offer'))}
        reads = {number(r.get('read')): r for r in map(stock.fields, queue.splitlines()) if number(r.get('read'))}
        a_read = reads.get(a, {})
        before_a = [e for e in episodes if number(e.get('attach')) is not None and old_attach is not None
                    and number(e.get('attach')) > old_attach and number(e.get('decision')) is not None
                    and number(decision.get('at')) is not None and number(e.get('decision')) < number(decision.get('at'))]
        prior_removed = (number(g1.get('remove')) is not None and number(held.get('start')) is not None
                         and number(g1.get('remove')) <= number(held.get('start')) and not before_a)
        require(prior_removed, 'pre_a_detachment_unproved')
        result.update(a=a, a_read_start=number(held.get('start')), a_decision_at=number(decision.get('at')),
                      previous_hide=number(prior[0].get('hideOp')) if len(prior) == 1 else None,
                      initial_attach=old_attach, a_complete=(a_read.get('unavailable') == a_read.get('truncated') ==
                          a_read.get('stale') == 'false'), a_reason=a_read.get('reason'),
                      pre_a_roots=0 if prior_removed else None)
        require(a is not None and number(decision.get('a')) == a and old_attach is not None,
                'first_request_or_attachment_missing')
        if row != 'r14_late_only':
            final = one('RESULT')
            controlled = one('CONTROLLED_B')
            b = number(decision.get('pending')); successor = number(final.get('successor'))
            b_offer, b_read = offers.get(b, {}), reads.get(successor, {})
            require(b is not None and successor == b and number(final.get('b')) == b,
                    'direct_b_successor_not_established')
            require(number(controlled.get('req')) == b and controlled.get('origin') == 'controlled_framework_metadata'
                    and controlled.get('event') == b_offer.get('event') and controlled.get('callback') == b_offer.get('callback')
                    and decision.get('pendingOrigin') == 'controlled', 'controlled_b_identity')
            result.update(b=b, pending_b=number(decision.get('pending')), b_origin='CONTROLLED_SYSTEMUI_PRIMARY',
                          b_event=number(b_offer.get('event')), b_callback=number(b_offer.get('callback')),
                          b_read=successor, b_classification=b_read.get('decision'),
                          a_adds=0 if decision.get('actualAttached') == 'false' and
                              number(decision.get('attach')) == old_attach else None,
                          final_attach=number(final.get('finalGeneration')),
                          final_roots=1 if final.get('finalAttached') == 'true' else 0 if final.get('finalAttached') == 'false' else None)
            require(not any(number(e.get('req')) == a for e in episodes), 'deferred_a_episode_found')
            if row == 'r14_exclusion':
                witness = [r for r in stages.get('INDEPENDENT_EXCLUSION', []) if r.get('screenshot') == 'before-a-occluder.png']
                after = one('POST_A_WITNESS')
                require(len(witness) == 1, 'exclusion_witness_missing')
                if len(witness) == 1:
                    errors.extend(green_witness(root, witness[0]))
                    images = [witness[0].get('screenshot', ''), after.get('screenshot', '')]
                    require(len(set(images)) == 2 and all(local(root, n) for n in images), 'exclusion_image_identity')
                result['independent_exclusion'] = len(witness) == 1 and not errors
            else:
                result['total_new_adds'] = (number(final.get('finalGeneration')) - old_attach
                    if number(final.get('finalGeneration')) is not None and old_attach is not None else None)
        else:
            late = one('LATE_WITHDRAWN')
            pending = number(decision.get('pending')); pending_offer = offers.get(pending, {})
            c = number(late.get('request')); c_offer, c_read = offers.get(c, {}), reads.get(c, {})
            require(pending is not None and pending_offer.get('systemui') == 'true' and
                    pending_offer.get('display') == '0' and number(pending_offer.get('type')) not in (None, 32, 4194304),
                    'pending_nonqualifying_event_unproved')
            require(c is not None and number(c_offer.get('callback')) is not None and
                    number(decision.get('at')) is not None and number(c_offer.get('callback')) > number(decision.get('at')) and
                    c_read.get('applied') == c_read.get('decision') == late.get('decision'), 'late_request_unproved')
            witness = [r for r in stages.get('INDEPENDENT_EXCLUSION', []) if r.get('screenshot') == 'after-a-occluder.png']
            require(len(witness) == 1, 'late_witness_missing')
            if len(witness) == 1:
                errors.extend(green_witness(root, witness[0]))
                start, end, at = map(number, (witness[0].get('screenshotStart'), witness[0].get('screenshotEnd'), late.get('up')))
                require(start is not None and end is not None and at is not None and start <= end <= at,
                        'late_witness_order')
                images = [witness[0].get('before', ''), witness[0].get('screenshot', '')]
            a_episodes = [e for e in episodes if number(e.get('req')) == a and number(e.get('attach')) == number(decision.get('attach'))]
            late_withdrawals = [w for w in withdrawals if number(w.get('req')) == c and number(w.get('attach')) == number(decision.get('attach'))]
            require(len(a_episodes) == len(late_withdrawals) == 1, 'late_show_or_withdrawal_owner')
            result.update(final_attach=number(decision.get('attach')), pending_before_a=pending,
                          pending_origin='SYSTEMUI_OTHER_EVENT', pending_type=number(pending_offer.get('type')),
                          pending_event=number(pending_offer.get('event')), pending_callback=number(pending_offer.get('callback')),
                          pending_qualifies=False, a_adds=1 if len(a_episodes) == 1 else None,
                          post_c_received=c is not None, final_roots=0 if len(late_withdrawals) == 1 else None)
    elif row == 'r14_real_occlusion':
        witness, final = one('INDEPENDENT_EXCLUSION'), one('REAL_RETURN')
        errors.extend(green_witness(root, witness))
        exclusion, returned = number(final.get('exclusionReq')), number(final.get('returnReq'))
        reads = {number(r.get('req')): r for r in stages.get('READ', []) if number(r.get('req'))}
        applied = {number(r.get('req')): r for r in stages.get('APPLIED', []) if number(r.get('req'))}
        xread, xapply, rread, rapply = reads.get(exclusion, {}), applied.get(exclusion, {}), reads.get(returned, {}), applied.get(returned, {})
        require(xread.get('decision') == 'HIDDEN_OCCLUDED' and xread.get('reason') == 'FOREIGN_ABOVE' and
                xread.get('rootUnavailable') == xread.get('truncated') == xread.get('stale') == 'false' and
                xapply.get('attached') == 'false' and xapply.get('roots') == '0' and
                xapply.get('wakeGeneration') == final.get('sameWake'),
                'real_exclusion_not_applied')
        require(rread.get('decision') == 'SHOW_FULL' and rread.get('reason') == 'MAIN_CONFIRMED' and
                rread.get('rootUnavailable') == rread.get('truncated') == rread.get('stale') == 'false' and
                rapply.get('attached') == 'true' and rapply.get('roots') == '1' and
                final.get('origin') == 'framework' and final.get('sameWake') == rapply.get('wakeGeneration') and
                final.get('attach') == rapply.get('attachGeneration'), 'real_fresh_return_unproved')
        attach = number(final.get('attach'))
        previous = [w for w in withdrawals if number(w.get('attach')) == (attach - 1 if attach else None)
                    and w.get('attachedBefore') == 'true']
        require(len(previous) == 1 and number(previous[0].get('decision')) is not None and
                number(xapply.get('up')) is not None and number(previous[0].get('decision')) <= number(xapply.get('up')),
                'real_prior_withdrawal_unproved')
        times = list(map(number, (xread.get('end'), witness.get('screenshotStart'),
                                  witness.get('screenshotEnd'), final.get('up'))))
        require(all(x is not None for x in times) and times == sorted(times), 'real_witness_order')
        returned_episodes = [e for e in episodes if number(e.get('req')) == returned and number(e.get('attach')) == attach]
        require(len(returned_episodes) == 1 and len([e for e in episodes if number(e.get('attach')) == attach]) == 1,
                'real_return_episode_identity')
        images = [witness.get('screenshot', ''), final.get('screenshot', '')]
        require(len(set(images)) == 2 and all(local(root, n) for n in images), 'real_return_image_identity')
        try:
            require(stock.green_count(stock.png_center(local(root, images[1]))[2]) < 16,
                    'real_return_occluder_still_visible')
        except (OSError, ValueError, IndexError, struct.error, zlib.error):
            errors.append('real_return_image_invalid')
        result.update(real_occluder=True, independent_window_identity=True, withdrawn_while_locked=True,
                      fresh_main_return_once=len(returned_episodes) == 1,
                      exclusion_request=exclusion, return_request=returned, return_visual=final.get('visualOrb', 'UNOBSERVED'))
    else:
        armed, terminal = one('TERMINAL_ARMED'), one('TERMINAL_STALE')
        a, b = number(armed.get('a')), number(armed.get('b'))
        reads = [r for r in stages.get('READ', []) if number(r.get('req')) == a]
        offers = [r for r in stages.get('INGRESS_OFFER', []) if number(r.get('req')) == b]
        applied = [r for r in stages.get('APPLIED', []) if number(r.get('req')) == a]
        prior = [w for w in withdrawals if w.get('attachedBefore') == 'true' and number(w.get('attach')) == number(armed.get('attachGeneration'))]
        require(a is not None and b is not None and a != b and number(terminal.get('a')) == a and number(terminal.get('b')) == b,
                'terminal_request_identity')
        require(len(reads) == len(offers) == len(applied) == len(prior) == 1, 'terminal_records_missing')
        if len(reads) == len(offers) == len(applied) == len(prior) == 1:
            read, offer, apply, hide = reads[0], offers[0], applied[0], prior[0]
            times = list(map(number, (read.get('start'), offer.get('up'), armed.get('up'), hide.get('decision'), apply.get('up'), terminal.get('up'))))
            require(all(x is not None for x in times) and times == sorted(times), 'terminal_order')
            require(read.get('decision') == 'SHOW_FULL' and read.get('reason') == 'MAIN_CONFIRMED' and
                    read.get('rootUnavailable') == read.get('truncated') == read.get('stale') == 'false' and
                    offer.get('after') == str(b) and offer.get('started') == 'false', 'terminal_pending_b_unproved')
            require(apply.get('attached') == 'false' and apply.get('roots') == '0' and apply.get('pending') == 'none' and
                    terminal.get('locked') == 'false' and terminal.get('roots') == '0' and
                    terminal.get('oldAuthority') == 'false' and terminal.get('wake') == 'none' and
                    armed.get('serviceSession') == apply.get('serviceSession') and
                    armed.get('wakeGeneration') != apply.get('wakeGeneration'), 'terminal_stale_applied')
            require(not any(number(e.get('attach')) and number(e.get('attach')) > number(armed.get('attachGeneration'))
                            for e in episodes), 'terminal_late_episode')
        result.update(pending_stale_work=not errors, terminal_state_observed=not errors, late_adds=0 if not errors else None,
                      a=a, b=b)
    if images:
        try:
            require(len(set(images)) == len(images) and all(local(root, name) for name in images), 'visual_file_identity')
        except ValueError:
            errors.append('visual_file_missing')
    if not errors:
        result['status'] = 'PASS'
    else:
        result['errors'] = sorted(set(errors))
    return result, sorted(set(errors)), images

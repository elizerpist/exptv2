#!/usr/bin/env python3
"""Fail-closed evaluation of a single R14 stock service specimen.

The green window is checked independently from fixture claims. An accepted
stock RED does not establish physical ORB pixels or phone causality.
"""
from __future__ import annotations
import argparse
import re
import struct
import zlib
from pathlib import Path

TOKEN = re.compile(r'([A-Za-z][A-Za-z0-9_]*)=([^\s,()]+)')


def fields(line: str) -> dict[str, str]:
    return dict(TOKEN.findall(line))


def integer(value: str | None) -> int | None:
    try:
        return int(value or '')
    except ValueError:
        return None


def png_center(path: Path) -> tuple[int, int, list[tuple[int, int, int]]]:
    data = path.read_bytes()
    if not data.startswith(b'\x89PNG\r\n\x1a\n'):
        raise ValueError('not_png')
    offset, header, compressed, ended = 8, None, bytearray(), False
    while offset + 12 <= len(data):
        size = struct.unpack_from('>I', data, offset)[0]
        tag = data[offset + 4:offset + 8]
        end = offset + 12 + size
        if end > len(data) or zlib.crc32(data[offset + 4:offset + 8 + size]) & 0xffffffff != struct.unpack_from('>I', data, offset + 8 + size)[0]:
            raise ValueError('png_crc')
        payload = data[offset + 8:offset + 8 + size]
        if tag == b'IHDR':
            header = struct.unpack('>IIBBBBB', payload)
        elif tag == b'IDAT':
            compressed.extend(payload)
        elif tag == b'IEND':
            ended = end == len(data)
            break
        offset = end
    if not ended or header is None:
        raise ValueError('png_incomplete')
    width, height, depth, color, compression, filtering, interlace = header
    channels = {2: 3, 6: 4}.get(color)
    if not (32 <= width <= 4096 and 32 <= height <= 4096 and depth == 8 and channels and
            compression == filtering == interlace == 0):
        raise ValueError('png_format')
    stride = width * channels
    expected = (stride + 1) * height
    decoder = zlib.decompressobj()
    raw = decoder.decompress(bytes(compressed), expected + 1)
    if len(raw) != expected or not decoder.eof or decoder.unused_data:
        raise ValueError('png_payload')
    previous = bytearray(stride)
    samples: list[tuple[int, int, int]] = []
    first, last = height // 2 - 16, height // 2 + 16
    for y in range(last):
        start = y * (stride + 1)
        mode = raw[start]
        if mode > 4:
            raise ValueError('png_filter')
        row = bytearray(raw[start + 1:start + 1 + stride])
        for x in range(stride):
            left = row[x - channels] if x >= channels else 0
            above = previous[x]
            upper = previous[x - channels] if x >= channels else 0
            if mode == 1:
                predictor = left
            elif mode == 2:
                predictor = above
            elif mode == 3:
                predictor = (left + above) // 2
            elif mode == 4:
                p = left + above - upper
                distances = (abs(p - left), abs(p - above), abs(p - upper))
                predictor = (left, above, upper)[distances.index(min(distances))]
            else:
                predictor = 0
            row[x] = (row[x] + predictor) & 255
        if y >= first:
            for x in range(width // 2 - 16, width // 2 + 16):
                pos = x * channels
                samples.append(tuple(row[pos:pos + 3]))
        previous = row
    return width, height, samples


def green_count(samples: list[tuple[int, int, int]]) -> int:
    return sum(abs(r - 20) <= 30 and abs(g - 180) <= 30 and abs(b - 74) <= 30 for r, g, b in samples)


def verify_green(root: Path, witness: dict[str, str], after: dict[str, str], decision_at: int) -> list[str]:
    errors = []
    if not (witness.get('visual') == 'true' and witness.get('locked') == 'true' and
            witness.get('display') == after.get('display') == '0' and
            witness.get('window') == after.get('window') and integer(witness.get('window')) is not None and
            (integer(witness.get('screenshotEnd')) or decision_at + 1) <= decision_at <= (integer(after.get('start')) or -1)):
        errors.append('green_owner_or_interval')
    try:
        def image(key: str, source: dict[str, str]):
            value = source.get(key, '')
            path = (root / value).resolve()
            if not path.is_relative_to(root.resolve()) or not path.is_file():
                raise ValueError('missing_image')
            return png_center(path)
        ref = image('reference', witness)
        before = image('before', witness)
        during = image('screenshot', witness)
        post = image('screenshot', after)
        if (ref[0:2] != (32, 32) or green_count(ref[2]) < 1000 or
                before[0:2] != during[0:2] or during[0:2] != post[0:2] or
                green_count(before[2]) >= 16 or green_count(during[2]) < 900 or green_count(post[2]) < 900):
            errors.append('green_pixels_not_established')
    except (OSError, ValueError, struct.error, zlib.error):
        errors.append('green_image_missing_or_invalid')
    return errors


def verify_forensic(has_precleanup_stack: bool, trace_body: bytes | None) -> list[str]:
    return [] if has_precleanup_stack or bool(trace_body and len(trace_body) > 64) else ['generated_only_anr_path']


def verify_removal(root: Path, name: str, request: int | None, attach: int | None) -> list[str]:
    try:
        rows = [fields(line) for line in (root / name).read_text().splitlines()]
    except (OSError, UnicodeError):
        return ['removal_marks_missing:' + name]
    for hide in rows:
        if integer(hide.get('stage')) != 8 or integer(hide.get('request')) != request or request is None:
            continue
        for removal in rows:
            if (integer(removal.get('stage')) == 13 and integer(removal.get('attachment')) == attach
                    and attach is not None and removal.get('extra') == '1'
                    and (integer(removal.get('sequence')) or -1) > (integer(hide.get('sequence')) or 0)):
                return []
    return ['removal_not_correlated:' + name]


def verify_orb_frame(sample: dict) -> list[str]:
    needed = ('actual_service', 'same_owner', 'full_reference', 'discreet_reference', 'background_reference',
              'sample_before_attach', 'first_correct_observed', 'sampling_complete')
    return [] if all(sample.get(key) is True for key in needed) and sample.get('visual_paths') else ['calibrated_orb_frame_missing']


def evaluate(case: str, fixture: str, queue: str, root: Path, source: str, run_id: str, raw: str) -> list[str]:
    errors: list[str] = []
    stages: dict[str, list[dict[str, str]]] = {}
    for line in fixture.splitlines():
        row = fields(line)
        if row.get('stage'):
            stages.setdefault(row['stage'], []).append(row)
    def one(stage: str) -> dict[str, str]:
        rows = stages.get(stage, [])
        if len(rows) != 1:
            errors.append('missing_or_duplicate_' + stage.lower())
            return {}
        return rows[0]
    run, live, g1, armed, held, decision = (one(x) for x in ('RUN', 'G1_LIVE', 'G1_WITHDRAWN', 'RETURN_ARMED', 'A_HELD', 'A_DECISION'))
    if run.get('run') != run_id or run.get('source') != source or run.get('case') != case or not integer(run.get('pid')):
        errors.append('run_identity')
    a = integer(held.get('req')); read_start = integer(held.get('start')); at = integer(decision.get('at'))
    if not (a and a == integer(decision.get('a')) and held.get('decision') == 'SHOW_FULL' and
            held.get('reason') == 'MAIN_CONFIRMED' and read_start is not None and at is not None and
            read_start >= (integer(armed.get('closeRequested')) or at + 1) and g1.get('wake') not in (None, 'none')):
        errors.append('a_identity_or_order')
    if not (integer(live.get('firstPost')) and (integer(live.get('submissions')) or 0) > 0 and
            live.get('session') == g1.get('session') == held.get('session') and
            live.get('wake') == g1.get('wake') == held.get('wake') and
            live.get('attach') == g1.get('attach') == held.get('attach') and integer(g1.get('remove'))):
        errors.append('prior_live_withdrawal_missing')
    offers: dict[int, dict[str, str]] = {}
    reads: dict[int, dict[str, str]] = {}
    for line in queue.splitlines():
        row = fields(line)
        if integer(row.get('offer')) is not None:
            offers[int(row['offer'])] = row
        if integer(row.get('read')) is not None:
            reads[int(row['read'])] = row
    headers = fields(queue.splitlines()[0]) if queue.splitlines() else {}
    if headers.get('run') != run_id or integer(headers.get('offerOverflow')) != 0 or integer(headers.get('readOverflow')) != 0:
        errors.append('queue_identity_or_overflow')
    a_read = reads.get(a or -1, {})
    if not (a_read.get('decision') == 'SHOW_FULL' and a_read.get('reason') == 'MAIN_CONFIRMED' and
            a_read.get('unavailable') == a_read.get('truncated') == a_read.get('stale') == 'false' and
            integer(a_read.get('start')) == read_start):
        errors.append('a_incomplete')
    g1_request = integer(g1.get('request'))
    if g1_request not in reads or reads[g1_request].get('applied') not in ('HIDDEN_UNKNOWN', 'HIDDEN_OCCLUDED'):
        errors.append('g1_cause_not_applied')
    errors.extend(verify_removal(root, 'g1-withdrawal-marks.txt', g1_request, integer(g1.get('attach'))))
    a_offer = offers.get(a or -1, {})
    for key in ('session', 'visibility', 'wake', 'interaction', 'attach'):
        decision_key = 'authorityAttach' if key == 'attach' else key
        if not held.get(key) or held.get(key) != a_offer.get(key) or held.get(key) != decision.get(decision_key):
            errors.append('a_authority_' + key)
    fw = one('FRAMEWORK_EQUIVALENCE')
    fw_row = offers.get(integer(fw.get('req')) or -1, {})
    if not (fw.get('framework') == fw_row.get('framework') == 'true' and fw_row.get('systemui') == 'true' and
            fw_row.get('type') == '32' and fw_row.get('display') == '0' and fw_row.get('trigger') == 'window'):
        errors.append('framework_equivalence')
    pending = integer(decision.get('pending'))
    def qualifies(row: dict[str, str]) -> bool:
        ev, callback = integer(row.get('event')), integer(row.get('callback'))
        window = integer(row.get('window'))
        return bool(row.get('trigger') == 'window' and row.get('systemui') == 'true' and row.get('display') == '0'
                    and row.get('type') in ('32', '4194304') and window is not None and window >= 0
                    and all(row.get(key) == held.get(key) for key in ('session', 'visibility', 'wake', 'interaction', 'attach'))
                    and ev is not None and callback is not None and read_start is not None and at is not None
                    and 0 < ev <= callback <= at and ev >= read_start and callback > read_start)
    if case == 'late-only':
        if pending is not None and pending not in offers:
            errors.append('pending_origin_unknown')
        if pending is not None and qualifies(offers.get(pending, {})):
            errors.append('late_qualifying_pending')
    elif pending is None or pending == a or not qualifies(offers.get(pending, {})):
        errors.append('qualifying_pending_missing')
    if decision.get('decision') != 'SHOW_FULL' or decision.get('actualAttached') != 'true':
        errors.append('stock_add_or_actual_decision_missing')
    expected_gen = integer(g1.get('attach'))
    if expected_gen is None or integer(decision.get('attach')) != expected_gen + 1:
        errors.append('stock_generation')
    if case == 'exclusion':
        witnesses = [r for r in stages.get('INDEPENDENT_EXCLUSION', []) if r.get('screenshot') == 'before-a-occluder.png']
        after = stages.get('POST_A_WITNESS', [])
        if len(witnesses) != 1 or len(after) != 1 or at is None:
            errors.append('green_witness_missing')
        else:
            errors.extend(verify_green(root, witnesses[0], after[0], at))
    if case in ('exclusion', 'fresh-main'):
        result = one('RESULT')
        successor = integer(result.get('successor'))
        if not (successor and integer(result.get('a')) == a and integer(result.get('b')) == pending and result.get('lineage') == 'true'):
            errors.append('successor_identity')
        cursor, seen = successor, set()
        while cursor is not None and cursor != pending and cursor not in seen:
            seen.add(cursor)
            cursor = integer(offers.get(cursor, {}).get('parent'))
        if cursor != pending:
            errors.append('successor_lineage_unproved')
        read = reads.get(successor or -1, {})
        expected_decision = 'HIDDEN_OCCLUDED' if case == 'exclusion' else 'SHOW_FULL'
        expected_reason = 'FOREIGN_ABOVE' if case == 'exclusion' else 'MAIN_CONFIRMED'
        if not (read.get('applied') == read.get('decision') == result.get('successorDecision') == expected_decision and
                read.get('reason') == result.get('successorReason') == expected_reason and read.get('stale') == 'false'):
            errors.append('successor_read_missing')
        if case == 'exclusion' and (result.get('finalAttached') != 'false' or
                'R14 candidate assertion: pending B must suppress the excess A add' not in raw):
            errors.append('stock_red_not_observed')
        if case == 'exclusion':
            errors.extend(verify_removal(root, 'successor-withdrawal-marks.txt', successor, integer(decision.get('attach'))))
            final_witness = stages.get('POST_SUCCESSOR_WITNESS', [])
            if len(final_witness) != 1 or len(witnesses) != 1 or at is None:
                errors.append('successor_green_witness_missing')
            else:
                final = final_witness[0]
                if final.get('locked') != 'true' or integer(final.get('successor')) != successor:
                    errors.append('successor_green_identity')
                errors.extend(verify_green(root, witnesses[0], final, at))
                if (integer(final.get('start')) or -1) < (integer(read.get('end')) or 0):
                    errors.append('successor_green_order')
        if case == 'fresh-main' and result.get('finalAttached') != 'true':
            errors.append('fresh_return_missing')
    else:
        late = one('LATE_WITHDRAWN')
        if not integer(late.get('request')) or integer(late.get('request')) not in reads:
            errors.append('late_read_missing')
    return errors


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument('--case', choices=('exclusion', 'fresh-main', 'late-only'), required=True)
    p.add_argument('--fixture', type=Path, required=True)
    p.add_argument('--queue', type=Path, required=True)
    p.add_argument('--raw', type=Path, required=True)
    p.add_argument('--source', required=True)
    p.add_argument('--run-id', required=True)
    a = p.parse_args()
    try:
        errors = evaluate(a.case, a.fixture.read_text(), a.queue.read_text(), a.fixture.parent, a.source, a.run_id, a.raw.read_text())
    except (OSError, UnicodeError, ValueError) as exc:
        errors = ['evidence_unavailable:' + str(exc)]
    print(('VALID_STOCK_RED' if a.case == 'exclusion' else 'VALID_CONTROL') if not errors else 'INVALID_OR_NOT_ESTABLISHED')
    for error in errors:
        print('  ' + error)
    return int(bool(errors))


if __name__ == '__main__':
    raise SystemExit(main())

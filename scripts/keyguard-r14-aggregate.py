#!/usr/bin/env python3
"""Fail-closed aggregation of independently archived R14 Android evidence.

A status file or a producer callback is never a compositor/privacy proof. Each
case must provide its AndroidJUnit transcript, immutable source/installed-APK
identity, process-qualified JSONL and any referenced visual evidence. Missing
rows remain NOT_ESTABLISHED; this command does not synthesize fixture results.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import struct
import sys
import uuid
import zlib
from pathlib import Path

ROUTES = ("SURFACE_LIVE", "SURFACE_STATIC", "LEGACY_R11")
REQUIRED = {
    ("r14_exclusion", "SURFACE_LIVE"): "supersededExternalEventSuppressesOnlyTheRecoveryAdd",
    ("r14_fresh_main", "SURFACE_LIVE"): "freshMainSuccessorRestoresExactlyOnce",
    ("r14_late_only", "SURFACE_LIVE"): "postAttachOnlyExclusionNeverDefersPriorAdmission",
    ("r14_pressure", "LIGHT"): "r14PairedRecoveryEdgesRemainOwnedUnderPressureAndRotation",
    ("r14_pressure", "FULL"): "r14PairedRecoveryEdgesRemainOwnedUnderPressureAndRotation",
    ("r12_pressure", "LIGHT_FULL"): "lightAndFullPressureRetainEverySelectedEpisodeCauseAndFitTheWholeUtf8Budget",
    # These two historical service methods explicitly set LEGACY_R11 in
    # @Before; their source and runner arguments cannot relabel them LIVE.
    ("r12_ordered", "LEGACY_R11"): "r12DetachedNegativeCanReadOneSuccessorBeforeOrderedApply",
    ("r12_occlusion", "LEGACY_R11"): "connectedProductionServiceRendersPortalOrbAcrossRealKeyguardCycles",
    ("r14_real_occlusion", "SURFACE_LIVE"): "temporaryRealOcclusionReturnsToMain",
    ("r14_terminal_stale", "SURFACE_LIVE"): "terminalWithdrawalDiscardsPendingWork",
}
for route in ROUTES:
    REQUIRED.update({
        ("r12_real_service_first_composite", route): "firstCorrectServiceComposite",
        ("r12_real_service_privacy_downgrade", route): "serviceDowngradeRevokesOldFull",
        ("r12_holder_lifecycle_races", route): "realHolderRevocationAcrossGeneration",
        ("r12_selector_persistence", route): "routeSelectionSurvivesReattachAndRestart",
        ("r13_service_demand_burst", route): "stableServiceMainConfirmationsDoNotDemandBitmaps",
        ("r12_natural_timing", route): "fourRealWakeCyclesUseRequestedRoute",
    })


def read_local(root: Path, name: object) -> bytes:
    if not isinstance(name, str) or not name:
        raise ValueError("missing evidence path")
    root = root.resolve()
    path = (root / name).resolve()
    if not path.is_relative_to(root) or not path.is_file():
        raise ValueError("missing or external evidence file")
    return path.read_bytes()


def expected_class(row: str) -> str:
    if row in {"r14_pressure", "r12_pressure"}:
        name = "KeyguardCardDiagnosticsInstrumentationTest"
    elif row in {"r12_ordered", "r12_occlusion"}:
        name = "KeyguardServiceOverlayInstrumentationTest"
    elif row == "r12_natural_timing":
        name = "KeyguardR12ServiceTimingInstrumentationTest"
    elif row.startswith("r14_"):
        name = "KeyguardRecoveryAdmissionInstrumentationTest"
    else:
        name = "KeyguardR15ServiceContractInstrumentationTest"
    return "com.fluvi.app.lockscreen." + name


def instrumented(raw: str, method: str, class_name: str) -> bool:
    return (raw.count("INSTRUMENTATION_STATUS: test=" + method + "\n") == 2
            and raw.count("INSTRUMENTATION_STATUS: class=" + class_name + "\n") == 2
            and "INSTRUMENTATION_STATUS: numtests=1" in raw
            and "INSTRUMENTATION_STATUS_CODE: 1" in raw
            and "INSTRUMENTATION_STATUS_CODE: 0" in raw
            and "INSTRUMENTATION_CODE: -1" in raw
            and bool(re.search(r"(?m)^OK \(1 test\)\s*$", raw))
            and not re.search(r"FAILURES!!!|INSTRUMENTATION_FAILED|INSTRUMENTATION_STATUS_CODE: -[1234]", raw))


def visual_file(root: Path, sample: dict) -> bool:
    try:
        data = read_local(root, sample.get("path"))
        digest = hashlib.sha256(data).hexdigest()
        if not data.startswith(b"\x89PNG\r\n\x1a\n") or digest != sample.get("sha256"):
            return False
        offset, header, compressed, ended = 8, None, bytearray(), False
        while offset + 12 <= len(data):
            length = struct.unpack_from(">I", data, offset)[0]
            kind = data[offset + 4:offset + 8]
            end = offset + 12 + length
            if end > len(data) or zlib.crc32(data[offset + 4:offset + 8 + length]) & 0xffffffff != struct.unpack_from(">I", data, offset + 8 + length)[0]:
                return False
            payload = data[offset + 8:offset + 8 + length]
            if kind == b"IHDR":
                if header is not None or len(payload) != 13:
                    return False
                header = struct.unpack(">IIBBBBB", payload)
            elif kind == b"IDAT":
                compressed.extend(payload)
            elif kind == b"IEND":
                ended = end == len(data)
                break
            offset = end
        if not ended or header is None:
            return False
        width, height, depth, color, compression, filtering, interlace = header
        channels = {0: 1, 2: 3, 4: 2, 6: 4}.get(color)
        if not (0 < width <= 4096 and 0 < height <= 4096 and depth == 8 and channels
                and compression == 0 and filtering == 0 and interlace == 0):
            return False
        stride = width * channels
        expected = (stride + 1) * height
        decoder = zlib.decompressobj()
        decoded = decoder.decompress(bytes(compressed), expected + 1)
        if len(decoded) != expected or not decoder.eof or decoder.unused_data:
            return False
        previous = bytearray(stride)
        all_white = True
        for row in range(height):
            start = row * (stride + 1)
            mode = decoded[start]
            if mode > 4:
                return False
            current = bytearray(decoded[start + 1:start + 1 + stride])
            for index in range(stride):
                left = current[index - channels] if index >= channels else 0
                above = previous[index]
                upper_left = previous[index - channels] if index >= channels else 0
                if mode == 1:
                    predictor = left
                elif mode == 2:
                    predictor = above
                elif mode == 3:
                    predictor = (left + above) // 2
                elif mode == 4:
                    p = left + above - upper_left
                    distances = (abs(p - left), abs(p - above), abs(p - upper_left))
                    predictor = (left, above, upper_left)[distances.index(min(distances))]
                else:
                    predictor = 0
                current[index] = (current[index] + predictor) & 255
            if color in (0, 4):
                all_white &= all(current[x] == 255 for x in range(0, stride, channels))
            else:
                all_white &= all(current[x:x + 3] == b"\xff\xff\xff" for x in range(0, stride, channels))
            previous = current
        return not all_white
    except (ValueError, OSError, struct.error, TypeError, zlib.error):
        return False


def recovery_pressure_owned(report: str) -> bool:
    """Validate a paired recovery from one report, never from merged captures."""
    def fields(line: str) -> dict[str, str] | None:
        values: dict[str, str] = {}
        for item in line.split()[1:]:
            if "=" not in item:
                continue
            key, value = item.split("=", 1)
            if key in values:
                return None
            values[key] = value
        return values

    rows = report.splitlines()
    episodes = [fields(line) for line in rows if line.startswith(" EPISODE ")]
    withdrawals = [fields(line) for line in rows if line.startswith(" WITHDRAWAL ")]
    recoveries = [fields(line) for line in rows if line.startswith(" R14_RECOVERY ")]
    financial = [fields(line) for line in rows if line.startswith(" R13_FINANCIAL ")]
    if any(row is None for row in episodes + withdrawals + recoveries + financial):
        return False
    for initial in recoveries:
        if initial.get("phase") != "DEFERRED":
            continue
        keys = ("attempt", "r14Recovery", "r14PreviousHide", "r14PreviousAttach",
                "r14DeferredA", "r14OriginalB", "r14Pending", "seq", "up")
        if not all(str(initial.get(key, "")).isdigit() and int(initial[key]) > 0 for key in keys):
            continue
        if initial["r14Pending"] != initial["r14OriginalB"]:
            continue
        same_attempt = [e for e in episodes if e.get("attempt") == initial["attempt"]]
        owner_episode = [e for e in same_attempt if e.get("attach") == initial["r14PreviousAttach"]
                         and e.get("withdrawal") == initial["r14PreviousHide"]]
        owner_hide = [h for h in withdrawals if h.get("hideOp") == initial["r14PreviousHide"]
                      and h.get("attach") == initial["r14PreviousAttach"] and h.get("attachedBefore") == "true"]
        if (len(owner_episode) != 1 or len(owner_hide) != 1 or len(same_attempt) < 2
                or len({e.get("attach") for e in same_attempt}) < 2
                or len({e.get("showOp") for e in same_attempt}) < 2
                or not any(f.get("attempt") == initial["attempt"] and f.get("coverage") == "keyguardScopesOnly"
                           and f.get("scopes", "0").isdigit() and int(f["scopes"]) > 0
                           and f.get("invalid") == "0" for f in financial)):
            continue
        immutable = ("attempt", "r14Recovery", "r14PreviousHide", "r14PreviousAttach", "r14DeferredA", "r14OriginalB")
        for replacement in recoveries:
            if replacement.get("phase") != "REPLACED" or any(replacement.get(k) != initial[k] for k in immutable):
                continue
            if (replacement.get("r14Displaced") == initial["r14Pending"]
                    and replacement.get("r14Pending", "").isdigit()
                    and int(replacement["r14Pending"]) > 0
                    and replacement["r14Pending"] != initial["r14Pending"]
                    and replacement.get("seq", "").isdigit() and int(replacement["seq"]) > int(initial["seq"])
                    and replacement.get("up", "").isdigit() and int(replacement["up"]) >= int(initial["up"])):
                return True
    return False


def restart_lineage_valid(first: object, second: object, owner: dict) -> bool:
    """The selected-route read must precede any phase-two fixture write."""
    if not isinstance(first, list) or not isinstance(second, list) or len(first) < 3 or len(second) < 3:
        return False
    if not all(isinstance(row, dict) for row in first + second):
        return False
    p1, p2 = first[0], second[0]
    if not (p1.get("kind") == p2.get("kind") == "PROCESS" and p1.get("phase") == 1 and p2.get("phase") == 2
            and all(p1.get(k) == p2.get(k) == owner.get(k) for k in ("source", "run_uuid", "row", "route"))
            and all(isinstance(p.get(k), int) and p[k] > 0 for p in (p1, p2) for k in ("pid", "process_start"))
            and p1["pid"] != p2["pid"] and p2["process_start"] > p1["process_start"]):
        return False
    return (first[1].get("kind") == "SELECTOR_WRITE" and first[1].get("route") == owner.get("route")
            and first[-1].get("kind") == "PHASE_COMPLETE"
            and second[1].get("kind") == "RESTORED_BEFORE_FIXTURE" and second[1].get("route") == owner.get("route")
            and sum(row.get("kind") == "RESTORED_BEFORE_FIXTURE" for row in second) == 1)


def holder_timeline_valid(timeline: object, barrier_timed_out: object) -> bool:
    """A held G1 and positive G2 must belong to distinct real identities."""
    stages = ("G1_LOCKED", "G1_REVOKED", "G1_BARRIER_RELEASED", "G1_OPERATION_FINISHED",
              "G1_DESTROY_RETURN", "G2_CREATED", "G2_POSTED", "G2_REDRAW_COMPLETED")
    if barrier_timed_out is not False or not isinstance(timeline, list) or not all(isinstance(e, dict) for e in timeline):
        return False
    selected = []
    for stage in stages:
        matching = [e for e in timeline if e.get("stage") == stage]
        if len(matching) != 1:
            return False
        selected.append(matching[0])
    if not all(isinstance(e.get("uptime"), int) and e["uptime"] > 0 for e in selected):
        return False
    if any(a["uptime"] > b["uptime"] for a, b in zip(selected, selected[1:])):
        return False
    def identity(event):
        value = tuple(event.get(k) for k in ("generation", "holder", "operation"))
        return value if all(isinstance(v, int) and v > 0 for v in value) else None
    g1, g2 = identity(selected[0]), identity(selected[5])
    if not g1 or not g2 or g1[0] == g2[0] or g1[1] == g2[1]:
        return False
    if any(identity(e) != g1 for e in selected[:5]) or any(identity(e) != g2 for e in selected[5:]):
        return False
    return not any(identity(e) == g1 and isinstance(e.get("uptime"), int)
                   and e["uptime"] > selected[4]["uptime"] for e in timeline)


def check_specific(row: str, route: str, result: dict, root: Path) -> list[str]:
    errors: list[str] = []
    if result.get("status") != "PASS":
        errors.append("fixture_not_pass")
    if row in {"r14_exclusion", "r14_fresh_main", "r14_late_only"}:
        fields = ("a", "a_read_start", "a_decision_at", "previous_hide", "initial_attach", "final_attach")
        if any(not isinstance(result.get(key), int) or result[key] <= 0 for key in fields):
            errors.append("r14_identity_or_timing_missing")
        if result.get("a_complete") is not True or result.get("a_reason") != "MAIN_CONFIRMED" or result.get("pre_a_roots") != 0:
            errors.append("r14_a_precondition")
        if row != "r14_late_only":
            if not (isinstance(result.get("b"), int) and result.get("b") != result.get("a")
                    and result.get("pending_b") == result.get("b") and result.get("b_origin") == "CONTROLLED_SYSTEMUI_PRIMARY"
                    and isinstance(result.get("b_event"), int) and isinstance(result.get("b_callback"), int)
                    and result.get("a_read_start", 0) <= result["b_event"] <= result["b_callback"] <= result.get("a_decision_at", -1)
                    and result["b_callback"] > result.get("a_read_start", 0)):
                errors.append("r14_b_origin_or_order")
        if row == "r14_exclusion":
            if not (result.get("a_adds") == 0 and result.get("b_read") == result.get("b")
                    and result.get("b_classification") in ("HIDDEN_SHADE", "HIDDEN_OCCLUDED")
                    and result.get("final_roots") == 0 and result.get("independent_exclusion") is True):
                errors.append("r14_exclusion_contract")
        elif row == "r14_fresh_main":
            if not (result.get("a_adds") == 0 and result.get("b_read") == result.get("b")
                    and result.get("b_classification") in ("SHOW_FULL", "SHOW_DISCREET")
                    and result.get("total_new_adds") == 1 and result.get("final_roots") == 1):
                errors.append("r14_fresh_recovery")
        else:
            no_qualifying_pending = (result.get("pending_before_a") is None or
                result.get("pending_origin") in {"OWN", "AMBIGUOUS", "SYNTHETIC", "NON_PRIMARY"})
            if not (no_qualifying_pending and result.get("pending_qualifies") is False and result.get("a_adds") == 1
                    and result.get("post_c_received") is True and result.get("final_roots") == 0):
                errors.append("r14_late_only")
    if row in {"r14_exclusion", "r14_late_only", "r12_real_service_first_composite", "r12_real_service_privacy_downgrade"}:
        samples = result.get("visual_samples")
        if not isinstance(samples, list) or len(samples) < 2 or not all(isinstance(s, dict) and visual_file(root, s) for s in samples):
            errors.append("visual_files_missing_or_corrupt")
    if row == "r14_real_occlusion":
        if not (result.get("real_occluder") is True and result.get("independent_window_identity") is True
                and result.get("withdrawn_while_locked") is True and result.get("fresh_main_return_once") is True
                and isinstance(result.get("visual_samples"), list)
                and len(result["visual_samples"]) >= 2 and all(isinstance(s, dict) and visual_file(root, s) for s in result["visual_samples"])
                and len({s.get("sha256") for s in result["visual_samples"]}) >= 2):
            errors.append("real_occlusion_return_not_established")
    if row == "r14_terminal_stale" and not (result.get("pending_stale_work") is True
            and result.get("terminal_state_observed") is True and result.get("late_adds") == 0):
        errors.append("terminal_stale_not_established")
    if row in {"r12_real_service_first_composite", "r12_real_service_privacy_downgrade"}:
        if not (result.get("actual_service") is True and result.get("same_owner") is True
                and isinstance(result.get("window_id"), int) and result.get("display_id") == 0
                and isinstance(result.get("roi"), list) and len(result["roi"]) == 4
                and result.get("full_reference") is True and result.get("discreet_reference") is True
                and result.get("background_reference") is True and result.get("sampling_complete") is True):
            errors.append("visual_owner_or_calibration_missing")
        if row.endswith("first_composite") and not (result.get("first_correct_observed") is True
                and result.get("sample_before_attach") is True and isinstance(result.get("first_interval_ms"), list)
                and len(result["first_interval_ms"]) == 2):
            errors.append("first_composite_not_established")
        if row.endswith("privacy_downgrade") and not (result.get("full_to_discreet") is True
                and result.get("stale_older_work_queued") is True and result.get("revoked_generation_observed") is True
                and result.get("forbidden_pixels_observed") is False):
            errors.append("privacy_transition_not_established")
    if row == "r12_holder_lifecycle_races":
        if route == "LEGACY_R11":
            if result.get("actual_surface_holders") != 0 or result.get("actual_legacy_material") is not True:
                errors.append("legacy_holder_count")
        elif not (result.get("actual_holder") is True and result.get("created_changed_destroyed") is True
                  and result.get("resize_recreate") is True and result.get("inflight_at_revocation") is True
                  and result.get("stale_post_after_destroy") is False and result.get("redraw_completion_exactly_once") is True
                  and result.get("repeat_hide_disconnect") is True
                  and holder_timeline_valid(result.get("holder_timeline"), result.get("barrier_timed_out"))):
            errors.append("holder_race_not_established")
    if row == "r12_selector_persistence":
        pids = result.get("process_ids")
        if not (result.get("real_store_write") is True and result.get("attached_pending_boundary") is True
                and result.get("configured") == route and result.get("effective_after_fresh_attach") == route
                and isinstance(pids, list) and len(pids) == 2 and len(set(pids)) == 2
                and result.get("second_process_restored") is True and result.get("unsupported_fallback_checked") is True):
            errors.append("selector_persistence_not_established")
    if row == "r13_service_demand_burst":
        if not (result.get("distinct_completed_inspections") == 32 and result.get("first_attach") is True
                and result.get("geometry_only") is True and result.get("content_change") is True):
            errors.append("service_burst_not_established")
        if route == "LEGACY_R11":
            if not (result.get("actual_paints", 0) > 0 and result.get("actual_legacy_binds", 0) > 0):
                errors.append("legacy_positive_demand_missing")
        elif result.get("actual_paints") != 0 or result.get("actual_legacy_binds") != 0:
            errors.append("surface_eager_demand")
    if row in {"r14_pressure", "r12_pressure"}:
        try:
            report = read_local(root, result.get("report")).decode("utf-8")
            byte_count = len(report.encode("utf-8"))
            if (byte_count > 32_768 or f"exportBytes={byte_count}\n" not in report
                    or not report.endswith("END_FLUVI_KEYGUARD_TIMING_CAPTURE_V1\n")
                    or "omittedCriticalRecordIds=none" not in report):
                errors.append("pressure_budget_or_critical_omission")
            if row == "r14_pressure" and not recovery_pressure_owned(report):
                errors.append("recovery_edges_missing")
        except (ValueError, OSError, UnicodeError):
            errors.append("pressure_report_missing")
    return errors


def verify_case(root: Path, case: dict, source: str) -> list[str]:
    errors: list[str] = []
    row, route = case.get("row"), case.get("route")
    method = REQUIRED.get((row, route))
    if method is None or case.get("method") != method:
        errors.append("unexpected_row_or_method")
    if str(row).startswith("r14_") or row == "r12_pressure":
        expected_scope = "r14_recovery_candidate"
    elif row in {"r12_ordered", "r12_occlusion", "r12_selector_persistence", "r13_service_demand_burst"}:
        expected_scope = "r12_contract"
    else:
        expected_scope = {"SURFACE_LIVE": "r12_live", "SURFACE_STATIC": "r12_static", "LEGACY_R11": "r12_legacy"}.get(route)
    if case.get("scope") != expected_scope:
        errors.append("scope_mismatch")
    if case.get("source") != source:
        errors.append("source_mismatch")
    for name in ("run_id", "job_id", "pid"):
        if not isinstance(case.get(name), int) or case[name] <= 0:
            errors.append(name + "_invalid")
    try:
        if str(uuid.UUID(case.get("run_uuid", ""))) != case.get("run_uuid"):
            raise ValueError()
    except (ValueError, AttributeError, TypeError):
        errors.append("run_uuid_invalid")
    for key in ("app_sha256", "test_sha256"):
        if not re.fullmatch(r"[0-9a-f]{64}", str(case.get(key, ""))):
            errors.append(key + "_invalid")
    if case.get("installed_app_sha256") != case.get("app_sha256") or case.get("installed_test_sha256") != case.get("test_sha256"):
        errors.append("installed_apk_mismatch")
    try:
        raw = read_local(root, case.get("transcript")).decode("utf-8").replace("\r\n", "\n")
        records = [json.loads(line) for line in read_local(root, case.get("records")).decode("utf-8").splitlines() if line.strip()]
        app_receipt = read_local(root, case.get("app_receipt")).decode("utf-8")
        test_receipt = read_local(root, case.get("test_receipt")).decode("utf-8")
        run_metadata = json.loads(read_local(root, case.get("run_metadata")).decode("utf-8"))
        if not method or not instrumented(raw, method, expected_class(str(row))):
            errors.append("unexecuted_or_failed_test")
        for content, digest, label in ((app_receipt, case.get("app_sha256"), "app"), (test_receipt, case.get("test_sha256"), "test")):
            if f"expected={digest} installed={digest}" not in content:
                errors.append(label + "_receipt_mismatch")
        process = [r for r in records if r.get("kind") == "PROCESS"]
        if len(process) != 1 or any(process[0].get(k) != case.get(k) for k in ("source", "run_uuid", "pid", "process_start", "route", "row")):
            errors.append("process_mismatch")
        if row == "r12_selector_persistence":
            phase_one = [json.loads(line) for line in read_local(root, case.get("phase_one_records")).decode("utf-8").splitlines() if line.strip()]
            phase_one_raw = read_local(root, case.get("phase_one_transcript")).decode("utf-8").replace("\r\n", "\n")
            if not restart_lineage_valid(phase_one, records, case) or not instrumented(phase_one_raw, method, expected_class(str(row))):
                errors.append("selector_restart_lineage_mismatch")
            for key, digest in (("phase_one_app_receipt", case.get("app_sha256")), ("phase_one_test_receipt", case.get("test_sha256")),
                                ("phase_one_app_after_receipt", case.get("app_sha256")), ("phase_one_test_after_receipt", case.get("test_sha256"))):
                if f"expected={digest} installed={digest}" not in read_local(root, case.get(key)).decode("utf-8"):
                    errors.append("selector_phase_one_receipt_mismatch")
        jobs = run_metadata.get("jobs") or []
        if not (run_metadata.get("databaseId") == case.get("run_id") and run_metadata.get("headSha") == source
                and run_metadata.get("event") == "workflow_dispatch"
                and any(job.get("databaseId") == case.get("job_id") for job in jobs)):
            errors.append("run_or_job_provenance_mismatch")
        result = [r for r in records if r.get("kind") == "RESULT"]
        if len(result) != 1 or result[0].get("row") != row:
            errors.append("result_missing_or_duplicate")
        else:
            errors.extend(check_specific(str(row), str(route), result[0], root))
            if row == "r14_pressure":
                report = read_local(root, result[0].get("report")).decode("utf-8")
                if not case.get("capture_id") or not all(token in report for token in (
                        f"captureId={case['capture_id']}\n", f"captureMode={route}\n", f"build={source}\n")):
                    errors.append("capture_identity_mismatch")
    except (ValueError, OSError, UnicodeError, json.JSONDecodeError, TypeError) as exc:
        errors.append("raw_evidence_invalid:" + str(exc))
    return errors


def aggregate(source: str, evidence: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    lines: list[str] = []
    if not re.fullmatch(r"[0-9a-f]{40}", source):
        return ["source_invalid"], []
    if not evidence.is_dir():
        return ["evidence_directory_missing"], []
    found: dict[tuple[str, str], tuple[Path, dict]] = {}
    process_keys: dict[tuple[object, object, object], dict] = {}
    run_uuids: dict[str, dict] = {}
    def same_pressure_invocation(first: dict, second: dict) -> bool:
        return (first.get("row") == second.get("row") == "r14_pressure"
                and {first.get("route"), second.get("route")} == {"LIGHT", "FULL"}
                and first.get("method") == second.get("method")
                and first.get("capture_id") and second.get("capture_id")
                and first.get("capture_id") != second.get("capture_id"))
    for path in sorted(evidence.rglob("r14-case.json")):
        try:
            case = json.loads(path.read_text())
            key = (case.get("row"), case.get("route"))
            if key in found:
                errors.append(f"duplicate_or_contradictory_case:{key}")
                continue
            found[key] = (path.parent, case)
            process = (case.get("run_id"), case.get("pid"), case.get("process_start"))
            previous_process = process_keys.get(process)
            if not case.get("process_start") or (previous_process is not None and not same_pressure_invocation(previous_process, case)):
                errors.append(f"reused_or_unidentified_process:{key}")
            process_keys[process] = case
            run_uuid = case.get("run_uuid")
            previous_uuid = run_uuids.get(run_uuid)
            if previous_uuid is not None and not same_pressure_invocation(previous_uuid, case):
                errors.append(f"reused_specimen:{key}")
            run_uuids[run_uuid] = case
        except (OSError, UnicodeError, json.JSONDecodeError, TypeError) as exc:
            errors.append(f"bad_case_manifest:{path}:{exc}")
    for key in REQUIRED:
        if key not in found:
            lines.append(f"{key[0]}[{key[1]}]=NOT_ESTABLISHED")
            errors.append(f"missing:{key[0]}:{key[1]}")
            continue
        root, case = found[key]
        case_errors = verify_case(root, case, source)
        if case_errors:
            lines.append(f"{key[0]}[{key[1]}]=FAIL:" + ",".join(case_errors))
            errors.extend(f"{key[0]}:{key[1]}:{error}" for error in case_errors)
        else:
            lines.append(f"{key[0]}[{key[1]}]=PASS")
    for key in found.keys() - REQUIRED.keys():
        errors.append(f"unexpected_case:{key}")
    return errors, lines


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True)
    parser.add_argument("--evidence-dir", required=True, type=Path)
    args = parser.parse_args()
    errors, lines = aggregate(args.source, args.evidence_dir)
    for line in lines:
        print(line)
    print("R14_AGGREGATE=" + ("FAIL_INCOMPLETE" if errors else "PASS"))
    for error in errors:
        print("  " + error)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())

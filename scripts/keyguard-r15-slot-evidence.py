#!/usr/bin/env python3
"""Extract all 16 natural slots without inventing visual or missing readings."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ORDER = ((1, "stock"), (1, "candidate"), (2, "candidate"), (2, "stock"))
POSITIONS = ("cold", "warm1", "warm2", "warm3")


def values(text: str) -> dict[str, str]:
    return dict(line.split("=", 1) for line in text.splitlines() if "=" in line)


def read_jsonl(path: Path, errors: list[str]) -> list[dict]:
    if not path.is_file():
        errors.append("missing_jsonl:" + path.name)
        return []
    result = []
    for index, line in enumerate(path.read_text().splitlines(), 1):
        if not line.strip():
            continue
        try:
            value = json.loads(line)
            if not isinstance(value, dict):
                raise ValueError("not_object")
            result.append(value)
        except (json.JSONDecodeError, ValueError):
            errors.append(f"invalid_jsonl:{path.name}:{index}")
    return result


def extract(directory: Path, block: int, arm: str, source: str) -> tuple[list[dict], list[str]]:
    errors: list[str] = []
    identity = values((directory / "identity.txt").read_text()) if (directory / "identity.txt").is_file() else {}
    run_id = identity.get("run_uuid", "")
    if identity.get("source") != source or identity.get("arm") != arm or identity.get("block") != str(block):
        errors.append("source_arm_or_block_mismatch")
    apk_hashes: dict[str, str | None] = {}
    for label in ("app", "test"):
        receipts = []
        for phase in ("before", "after"):
            path = directory / f"installed-{label}-{phase}-sha256.txt"
            match = re.fullmatch(r"expected=([0-9a-f]{64}) installed=([0-9a-f]{64})\s*", path.read_text()) if path.is_file() else None
            receipts.append(match[1] if match and match[1] == match[2] else None)
        apk_hashes[label] = receipts[0] if receipts[0] is not None and receipts[0] == receipts[1] else None
        if apk_hashes[label] is None:
            errors.append(f"{label}_installed_bytes_unverified")
    probe = directory / "probe/files/keyguard-service-probe"
    fixture_path = probe / "r12-timing" / run_id / "fixture.txt"
    fixture = fixture_path.read_text() if fixture_path.is_file() else ""
    capture_path = probe / "r12-timing" / run_id / "capture.txt"
    capture = capture_path.read_text() if capture_path.is_file() else ""
    process = re.findall(r"(?m)^PROCESS up=\d+ source=(\S+) run=(\S+) capture=(\S+) mode=(\S+) pid=(\d+) startTicks=(\d+)$", fixture)
    if len(process) != 1 or process[0][:2] != (source, run_id) or process[0][3] != "SURFACE_LIVE":
        errors.append("process_or_capture_unobserved")
    wake_rows = {name: int(wake) for name, wake in re.findall(r"(?m)^WAKE_TRIGGER up=\d+ name=(cold|warm[123]) wake=(\d+)", fixture)}
    if not wake_rows:
        wake_rows = {name: int(wake) for name, wake in re.findall(r"(?m)^WAKE up=\d+ name=(cold|warm[123]) wake=(\d+)", fixture)}
    hide_rows = {name: (int(trigger), int(detached)) for name, trigger, detached in
                 re.findall(r"(?m)^WITHDRAWN up=\d+ name=(cold|warm[123]) trigger=(\d+) detached=(\d+)", fixture)}
    acquisition = probe / "r15" / run_id / "acquisition"
    firsts = read_jsonl(acquisition / f"{arm}-block{block}-first-inspections.jsonl", errors)
    reads = read_jsonl(acquisition / f"{arm}-block{block}.jsonl", errors)
    overflow_path = acquisition / f"{arm}-block{block}-overflow.txt"
    if not overflow_path.is_file() or overflow_path.read_text().strip() != "0":
        errors.append("acquisition_overflow_or_missing")
    if not capture or f"build={source}" not in capture:
        errors.append("capture_unobserved_or_wrong_source")
    result: list[dict] = []
    for index, name in enumerate(POSITIONS):
        wake_at = wake_rows.get(name)
        next_wake = wake_rows.get(POSITIONS[index + 1]) if index + 1 < len(POSITIONS) else None
        available = [row for row in firsts if isinstance(row.get("start"), int) and wake_at is not None
                     and row["start"] >= wake_at and (next_wake is None or row["start"] < next_wake)]
        first = min(available, key=lambda row: row["start"]) if available else None
        exact = [row for row in reads if first and row.get("request") == first.get("request")
                 and row.get("session") == first.get("session") and row.get("wake") == first.get("wake")]
        read = exact[0] if len(exact) == 1 else None
        if len(exact) > 1:
            errors.append(f"{name}:duplicate_first_read")
        shape = None
        if read and isinstance(read.get("windows"), list):
            shape = json.dumps({"windows": [{key: window.get(key) for key in ("type", "display", "own")}
                                            for window in read["windows"]], "visited": read.get("visited")}, sort_keys=True)
        decision_at, decision_stage = None, None
        if first and wake_at is not None:
            request = first.get("request")
            for line in capture.splitlines():
                if (re.search(rf"(?:^| )req={request}(?: |$)", line)
                        and any(f"stage={stage}" in line for stage in ("SHOW_FOR_ATTACH", "HIDE_DECIDED", "AWAITING_MAIN_SURFACE"))):
                    time = re.search(r"(?:^| )up=(\d+)(?: |$)", line)
                    stage = re.search(r"(?:^| )stage=([^ ]+)", line)
                    if time and stage and int(time[1]) >= wake_at and (decision_at is None or int(time[1]) < decision_at):
                        decision_at, decision_stage = int(time[1]), stage[1]
        row = {"block": block, "arm": arm, "position": name, "run_uuid": run_id,
               "pid": int(process[0][4]) if len(process) == 1 else None,
               "process_start": int(process[0][5]) if len(process) == 1 else None,
               "capture": process[0][2] if len(process) == 1 else None,
               "wake_uptime_ms": wake_at, "request": first.get("request") if first else None,
               "session": first.get("session") if first else None, "wake": first.get("wake") if first else None,
               "first_classification": first.get("decision") if first else None,
               "first_reason": first.get("reason") if first else None,
               "complete": (all(first[key] is False for key in ("rootUnavailable", "walkTruncated", "abortedStale"))
                            if first and all(isinstance(first.get(key), bool) for key in ("rootUnavailable", "walkTruncated", "abortedStale")) else None),
               "app_sha256": apk_hashes["app"], "test_sha256": apk_hashes["test"],
               "eligible": read.get("eligible") if read else None,
               "root_called": read.get("rootCalled") if read else None,
               "root_flags": read.get("rootFlags") if read else None,
               "root_accepted": read.get("rootAccepted") if read else None,
               "active_root_ms": read.get("activeRootMs") if read else None,
               "child_calls": read.get("childCalls") if read else None,
               "first_child_flags": read.get("firstChildFlags") if read else None,
               "first_child_ms": read.get("firstChildMs") if read else None,
               "child_total_ms": read.get("childMs") if read else None,
               "total_read_ms": (read["inspectionEnd"] - read["inspectionStart"]) if read and isinstance(read.get("inspectionEnd"), int) and isinstance(read.get("inspectionStart"), int) else None,
               "fallback": read.get("fallback") if read else None, "shape": shape,
               "wake_to_decision_ms": decision_at - wake_at if decision_at is not None and wake_at is not None else None,
               "decision_stage": decision_stage, "first_composite_interval_ms": None,
               "withdrawal_callback_ms": hide_rows.get(name, (None, None))[0],
               "local_withdrawn_ms": hide_rows.get(name, (None, None))[1],
               "physical_presentation": "UNOBSERVED", "visual_class": "UNCLASSIFIED"}
        result.append(row)
    return result, errors


def build(root: Path, source: str) -> dict:
    rows, errors = [], []
    for block, arm in ORDER:
        directory = root / f"block-{block}-{arm}"
        if not directory.is_dir():
            errors.append(f"{block}:{arm}:process_missing")
            rows.extend({"block": block, "arm": arm, "position": name, "visual_class": "UNCLASSIFIED",
                         "physical_presentation": "UNOBSERVED"} for name in POSITIONS)
            continue
        found, failures = extract(directory, block, arm, source)
        rows.extend(found)
        errors.extend(f"{block}:{arm}:{failure}" for failure in failures)
    comparisons = []
    for label in ("app_sha256", "test_sha256"):
        identities = {row.get(label) for row in rows}
        if None in identities or len(identities) != 1:
            errors.append(f"{label}_differs_across_processes")
    for block in (1, 2):
        for position in POSITIONS[1:]:
            stock = next(row for row in rows if row["block"] == block and row["arm"] == "stock" and row["position"] == position)
            candidate = next(row for row in rows if row["block"] == block and row["arm"] == "candidate" and row["position"] == position)
            reasons = []
            if not all(row.get("eligible") is True and row.get("root_called") is True and row.get("root_accepted") is True for row in (stock, candidate)):
                reasons.append("first_eligible_accepted_opportunity_missing")
            if not all(row.get("complete") is True for row in (stock, candidate)):
                reasons.append("incomplete_first_read")
            if not stock.get("shape") or any(stock.get(key) != candidate.get(key) for key in ("shape", "first_classification", "first_reason")):
                reasons.append("classification_or_tree_shape_mismatch")
            read_delta = None
            if not reasons and all(isinstance(row.get("total_read_ms"), int) for row in (stock, candidate)):
                read_delta = candidate["total_read_ms"] - stock["total_read_ms"]
            reasons.append("independent_first_composite_unclassified")
            comparisons.append(dict(block=block, position=position, total_read_delta_ms=read_delta,
                                    onset_delta_interval_ms=None, excluded_reasons=reasons))
    return dict(source=source, slots=rows, warm_comparisons=comparisons, errors=errors,
                result="NOT_ESTABLISHED", reason="independent_compositor_calibration_not_proven")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--source", required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if not re.fullmatch(r"[0-9a-f]{40}", args.source):
        parser.error("source must be an exact SHA")
    result = build(args.evidence, args.source)
    args.out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(f"slots={len(result['slots'])} errors={len(result['errors'])} result={result['result']}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())

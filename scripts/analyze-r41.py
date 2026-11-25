#!/usr/bin/env python3
"""Analyze bounded R41 timing rows without inferring pixels or missing work.

Durations are nanoseconds on the in-process monotonic clock. The producer must
identify the eventual winner and the owner of its successful authorization;
a first, later-revoked grant is not automatically an effective grant.
"""
import argparse
import json
import math
from pathlib import Path
import statistics
import sys

LIMIT_NS = 300_000_000
BOUNDARIES = ("wakeNs", "offerNs", "workerNs", "readStartNs", "readEndNs", "dispatchNs", "mainNs", "grantNs")
SEGMENTS = ("ingress_to_offer", "inspection_queue", "worker_entry_to_read", "framework_read_and_classification",
            "read_end_to_dispatch", "dispatch_call_to_runnable_start", "main_entry_to_grant")


def parse_records(report, marker):
    rows = []
    for line in report.splitlines():
        if not line.startswith(" " + marker + " "):
            continue
        row = {}
        duplicate = False
        for field in line.strip().split()[1:]:
            if "=" not in field:
                continue
            key, value = field.split("=", 1)
            duplicate |= key in row
            row[key] = value
        if duplicate:
            row["parseError"] = "duplicate_field"
        rows.append(row)
    return rows


def parse_report(report):
    return parse_records(report, "R41_CORE")


def number(row, key):
    try:
        result = int(row[key])
        return result if result != -(1 << 63) else None
    except (KeyError, TypeError, ValueError):
        return None


def analyze(row):
    result = {"attempt": row.get("attempt", "UNOBSERVED"), "session": row.get("session", "UNOBSERVED"),
              "coverage": "INCOMPLETE",
              "eligibility": row.get("eligible", "UNOBSERVED"),
              "outcome": row.get("outcome", "UNOBSERVED"), "owner": row.get("owner", "UNOBSERVED"),
              "missing": [], "invalid": [], "segments_ns": {}, "total_ns": None,
              "observed_total_ns": None,
              "fallback_observation": None,
              "screen_to_grant_ns": None, "under_300ms": None,
              "clock": "in_process_monotonic_ns", "physical_pixel": "UNOBSERVED"}
    if row.get("eligible") == "false":
        if row.get("outcome") == "SUCCESS":
            result["invalid"].append("denied_attempt_has_successful_winner")
        elif row.get("outcome") == "DENIED" and row.get("coverage") == "COMPLETE" and row.get("dropped") == "0" and "parseError" not in row:
            result["coverage"] = "DENIED"
        else:
            result["missing"].append("complete_loss_free_denial")
        return result
    if row.get("eligible") != "true":
        result["missing"].append("eligible")
    if row.get("outcome") != "SUCCESS":
        result["missing"].append("successful_winner")
    owner = row.get("owner")
    if not owner or owner == "UNOBSERVED" or any(
        row.get(key) != owner for key in ("readOwner", "dispatchOwner", "grantOwner")
    ):
        result["missing"].append("matching_winner_read_dispatch_and_grant_owner")
    if row.get("dropped") != "0":
        result["missing"].append("loss_free_capture")
    if row.get("coverage") != "COMPLETE":
        result["missing"].append("producer_coverage")
    if "parseError" in row:
        result["invalid"].append(row["parseError"])
    values = {key: number(row, key) for key in BOUNDARIES}
    result["missing"].extend(key for key, value in values.items() if value is None)
    for name, left, right in zip(SEGMENTS, BOUNDARIES, BOUNDARIES[1:]):
        start, end = values[left], values[right]
        if start is None or end is None:
            continue
        if end < start:
            result["invalid"].append(f"{left}>{right}")
        else:
            result["segments_ns"][name] = end - start
    screen, grant = number(row, "screenNs"), values["grantNs"]
    if screen is not None and grant is not None:
        result["screen_to_grant_ns"] = grant - screen
    fallback = row.get("fallbackCandidateAndPostReceipt", "UNOBSERVED")
    if fallback != "UNOBSERVED":
        try:
            request, show, attachment, generation, candidate_ns, post_ns = (int(value) for value in fallback.split("/"))
            if min(request, show, attachment, generation) <= 0 or post_ns < candidate_ns:
                raise ValueError("invalid fallback identity or order")
            result["fallback_observation"] = {"request": request, "show": show, "attachment": attachment,
                "generation": generation, "candidate_ns": candidate_ns, "post_callback_receipt_ns": post_ns,
                "candidate_to_post_callback_ns": post_ns - candidate_ns, "effective_grant": "UNOBSERVED",
                "physical_presentation": "UNOBSERVED"}
        except ValueError:
            result["invalid"].append("invalid_fallback_observation")
    if (values["wakeNs"] is not None and grant is not None and grant >= values["wakeNs"]
            and row.get("outcome") == "SUCCESS" and owner and owner != "UNOBSERVED"
            and row.get("grantOwner") == owner):
        # This is a retained app-side observation, not a qualified complete
        # partition, an optical measurement or a per-device budget verdict.
        result["observed_total_ns"] = grant - values["wakeNs"]
    if not result["missing"] and not result["invalid"]:
        total = values["grantNs"] - values["wakeNs"]
        if sum(result["segments_ns"].values()) != total:
            result["invalid"].append("partition_does_not_reconcile")
        else:
            result["coverage"] = "COMPLETE"
            result["total_ns"] = total
            result["under_300ms"] = total < LIMIT_NS
    return result


def analyze_sampler(row):
    names = ("offer", "replaced", "submit", "worker", "read_start", "read_end", "dispatch", "main", "deliver", "reject")
    raw_times = row.get("times", "").split("/")
    raw_tids = row.get("tids", "").split("/")
    invalid = []
    if len(raw_times) != len(names) or len(raw_tids) != len(names) or "parseError" in row:
        invalid.append("malformed_sampler_row")
    if row.get("invalid", "0") != "0":
        invalid.append("sampler_producer_reported_invalid")
    times = {name: number({name: value}, name) for name, value in zip(names, raw_times)}
    tids = {name: number({name: value}, name) for name, value in zip(names, raw_tids)}
    intervals = {}
    for left, right in (("offer", "submit"), ("submit", "worker"), ("worker", "read_start"),
                        ("read_start", "read_end"), ("read_end", "dispatch"), ("dispatch", "main")):
        start, end = times.get(left), times.get(right)
        if start is not None and end is not None:
            if end < start:
                invalid.append(f"{left}>{right}")
            else:
                intervals[left + "_to_" + right] = end - start
    return {"sample": row.get("sample", "UNOBSERVED"), "receipt": row.get("receipt", "UNOBSERVED"),
            "times_ns": times, "tids": tids, "intervals_ns": intervals,
            "state_flags": row.get("stateFlags", "UNOBSERVED") if times.get("read_end") is not None else "UNOBSERVED",
            "replacement": row.get("replacement", "UNOBSERVED"), "reject": row.get("reject", "UNOBSERVED"),
            "invalid": invalid, "coverage": "OBSERVED_BRACKETS_ONLY"}


def summarize(results):
    counts = {}
    for result in results:
        counts[result["coverage"]] = counts.get(result["coverage"], 0) + 1
    duplicate_ids = sorted({result["attempt"] for result in results
                            if sum(other["attempt"] == result["attempt"] for other in results) > 1})
    samples = [result["total_ns"] for result in results if result["coverage"] == "COMPLETE"]
    qualifying = [r for r in results if r["eligibility"] == "true"]
    strict_verdict = "INCOMPLETE"
    if any(r["under_300ms"] is False or (r["eligibility"] == "true" and r["outcome"] == "MISS") for r in results):
        strict_verdict = "FAIL"
    elif qualifying and not duplicate_ids and all(r["coverage"] in ("COMPLETE", "DENIED") for r in results):
        strict_verdict = "PASS"
    return {"attempts": len(results), "coverage_counts": counts, "duplicate_attempt_ids": duplicate_ids,
               "strict_verdict": strict_verdict,
               "under_300ms": sum(value < LIMIT_NS for value in samples),
               "at_or_above_300ms": sum(value >= LIMIT_NS for value in samples),
               "maximum_ns": max(samples) if samples else None,
               "median_ns": statistics.median(samples) if samples else None,
               "p95_ns_nearest_rank": sorted(samples)[math.ceil(.95 * len(samples)) - 1] if len(samples) >= 20 else None,
               "sample_size": len(samples), "p95_method": "nearest_rank_n>=20"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    args = parser.parse_args()
    report = args.report.read_text(encoding="utf-8-sig")
    rows = parse_report(report)
    results = [analyze(row) for row in rows]
    unattributed = []
    for sample in parse_records(report, "R41_SAMPLE"):
        matches = [result for result in results if result["attempt"] == sample.get("attempt") and
                   result["session"] == sample.get("session")]
        lane = analyze_sampler(sample)
        if len(matches) == 1:
            matches[0].setdefault("sampler_lanes", []).append(lane)
            if lane["invalid"]:
                matches[0]["invalid"].extend("sampler:" + issue for issue in lane["invalid"])
                matches[0]["coverage"] = "INCOMPLETE"
                matches[0]["total_ns"] = None
                matches[0]["under_300ms"] = None
        else:
            unattributed.append(lane)
    summary = summarize(results)
    summary["unattributed_sampler_rows"] = len(unattributed)
    print(json.dumps({"summary": summary, "attempts": results, "unattributed_sampler_rows": unattributed}, indent=2))
    return 0 if summary["strict_verdict"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())

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


def parse_report(report):
    rows = []
    for line in report.splitlines():
        if not line.startswith(" R41_CORE "):
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


def number(row, key):
    try:
        result = int(row[key])
        return result if result != -(1 << 63) else None
    except (KeyError, TypeError, ValueError):
        return None


def analyze(row):
    result = {"attempt": row.get("attempt", "UNOBSERVED"), "coverage": "INCOMPLETE",
              "eligibility": row.get("eligible", "UNOBSERVED"),
              "outcome": row.get("outcome", "UNOBSERVED"), "owner": row.get("owner", "UNOBSERVED"),
              "missing": [], "invalid": [], "segments_ns": {}, "total_ns": None,
              "observed_total_ns": None,
              "screen_to_grant_ns": None, "under_300ms": None,
              "clock": "in_process_monotonic_ns", "physical_pixel": "UNOBSERVED"}
    if row.get("eligible") == "false":
        if row.get("outcome") == "SUCCESS":
            result["invalid"].append("denied_attempt_has_successful_winner")
        else:
            result["coverage"] = "DENIED"
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
    rows = parse_report(args.report.read_text(encoding="utf-8-sig"))
    results = [analyze(row) for row in rows]
    summary = summarize(results)
    print(json.dumps({"summary": summary, "attempts": results}, indent=2))
    return 0 if summary["strict_verdict"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())

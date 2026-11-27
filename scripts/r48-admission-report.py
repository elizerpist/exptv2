#!/usr/bin/env python3
"""Inspect a sealed R46-format capture locally. No network, screen content or APK changes."""
import argparse
from collections import defaultdict
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import re
import sys

UNKNOWN = "UNOBSERVED"
SOURCE = "af20365a5ec96ff92b35321a03c0a2679ee7d2fd"
ROUTES = {"FLUVI_STREAM", "WIDGETS_ANYWHERE"}
SCENES = {"MAIN", "PIN", "SHADE", "FOREIGN", "UNLOCKED", "OFF"}
FOOTER = re.compile(rb"(?m)^bodyBytes=([0-9]+) bodySha256=([0-9a-f]{64})\nEND_FLUVI_R46_RECORDING_V1\n\Z")
FIELD = re.compile(r"\b([A-Za-z][A-Za-z0-9_]*)=([A-Za-z0-9_./:+-]{1,160})(?=[ ),]|$)")
WINDOW_FIELD = re.compile(r"\b([A-Za-z][A-Za-z0-9_]*)=([^ ]+)")
SCENE_WINDOW = re.compile(r" +(?=R43_WINDOW )")
STRUCTURE = {
    "legacy_window_root", "keyguard_root_view", "keyguard_status_view", "keyguard_clock_switch",
    "keyguard_carrier_text", "keyguard_indication_text_bottom", "left_button", "camera_button",
    "lockscreen_clock_view", "lockscreen_clock_view_small", "lockscreen_clock_view_large",
    "device_entry_icon_view", "device_entry_icon", "keyguard_security_container",
    "password_entry", "pinEntry", "qs_frame", "quick_settings_panel", "quick_qs_panel",
}
OWNER = ("arm", "routeGeneration", "materialGeneration")
READ_STATE = ("start", "end", "scene", "legacy", "legacyReason", "verdict", "reason", "stale",
              "unavailable", "truncated", "readerComplete", "lookupStatus", "rawHost", "rawClock",
              "rawEntry", "rejectedHidden", "rejectedAncestry", "hostVerified", "hostWindow",
              "hostLayer", "epoch")
ADMISSION = ("domain", "normalSurface", "normalReason", "eligibility", "authority", "decision",
             "reason", "readStart", "readEnd", "credential", "shade", "foreign", "power",
             "available", "primaryDisplay", "interactive", "displayOn", "displayOff", "locked",
             "userUnlocked", "materialCurrent", "screenOn", "evidenceAt")
LIFECYCLE = {
    "INSPECTION_QUEUED", "INSPECTION_STARTED", "INSPECTION_FINISHED",
    "INSPECTION_AUTHORITY_REJECTED", "INSPECTION_REJECTED", "INSPECTION_QUEUE_REPLACED",
}


def scalar(value):
    return UNKNOWN if value in (None, "null", "NA", "missing", "OBSERVER") else value


def fields(line, pattern=FIELD):
    result = {}
    for key, value in pattern.findall(line):
        result.setdefault(key, scalar(value))
    return result


def number(s):
    return int(s) if isinstance(s, str) and s.isascii() and s.isdecimal() else None


def known(row, keys):
    return {key: row[key] for key in keys if row.get(key, UNKNOWN) != UNKNOWN}


def section(lines, begin, end):
    if lines.count(begin) != 1 or lines.count(end) != 1:
        raise ValueError(f"missing or ambiguous {begin} section")
    a, b = lines.index(begin), lines.index(end)
    if b <= a:
        raise ValueError(f"out of order {begin} section")
    return a, b


def envelope(path):
    with Path(path).open("rb") as file:
        raw = file.read(32 * 1024 * 1024 + 1)
    if len(raw) > 32 * 1024 * 1024:
        raise ValueError("file exceeds the 32 MiB offline input limit")
    footer = FOOTER.search(raw)
    if not footer:
        raise ValueError("sealed recording footer missing or malformed")
    body = raw[:footer.start()]
    digest = hashlib.sha256(body).hexdigest()
    if len(body) != int(footer[1]) or digest != footer[2].decode("ascii"):
        raise ValueError("sealed body byte count or SHA-256 mismatch")
    lines = body.decode("utf-8").split("\n")
    if lines[0] != "FLUVI_R46_RECORDING_V1" or len(lines) < 7:
        raise ValueError("unsupported recording")
    header = fields(lines[2])
    capture, route = header.get("captureId"), header.get("route")
    if not re.fullmatch(r"[a-f0-9-]{36}", capture or "") or route not in ROUTES:
        raise ValueError("missing capture or route identity")
    summary = section(lines, "SUMMARY_BEGIN", "SUMMARY_END")
    spool = section(lines, "DETAILED_RECORDS_BEGIN", "DETAILED_RECORDS_END")
    if summary[1] >= spool[0]:
        raise ValueError("summary and spool overlap")
    native = fields(" ".join(lines[summary[0] + 1:summary[1]]))
    if native.get("captureId", capture) != capture:
        raise ValueError("capture identity differs between envelope and summary")
    if native.get("build") not in (SOURCE, None):
        raise ValueError("capture build is not the R47 application under study")
    loss = fields(" ".join(lines[spool[1] + 1:]))
    loss.update(known(native, ("eventsRecorded", "eventsRetained", "eventsEvicted", "eventsCoalesced",
                              "exportTruncated", "r43Samples", "r43SampleEvicted", "r43SamplesEvicted",
                              "r41SamplesEvicted", "r44Dropped", "diagnosticDroppedRecords",
                              "diagnosticQueueOverflow", "diagnosticProducerTotalNs", "diagnosticProducerMaxNs",
                              "mailboxOfferWallTotalNs", "mailboxOfferWallMaxNs")))
    accounting = next((fields(line) for line in lines[summary[0] + 1:summary[1]]
                       if line.startswith("R41_ACCOUNTING ")), {})
    loss["rawSampleEviction"] = ({"state": "EVICTED", "count": accounting["sampleEvicted"]}
                                 if number(accounting.get("sampleEvicted")) else
                                 {"state": UNKNOWN, "count": accounting.get("sampleEvicted", UNKNOWN)})
    return header, native, loss, lines, summary, spool, len(body), digest, hashlib.sha256(raw).hexdigest()


@dataclass
class Observation:
    wake: int
    session: int | None
    read: str
    stage: str
    values: dict
    origin: str
    line: int

    def evidence(self):
        return f"{self.origin}:{self.line}"


def completion(row):
    if row.get("truncated") == "true":
        return "TRUNCATED"
    if row.get("unavailable") == "true":
        return "UNAVAILABLE"
    if row.get("stale") == "true":
        return "ABORTED_STALE"
    if all(row.get(key) == "false" for key in ("truncated", "unavailable", "stale")):
        return "COMPLETE"
    return UNKNOWN


def normalize(tag, payload, output=False):
    row = fields(payload)
    wake = number(row.get("originWakeEpoch") or row.get("wake"))
    session = number(row.get("serviceSession") or row.get("session"))
    request = number(row.get("request") or row.get("req"))
    revision = number(row.get("restrictionRevision") or row.get("revision"))
    read = f"req:{request}" if request else ""
    if tag == "R446_OUTPUT" and number(row.get("armGeneration")):
        row["arm"] = row["armGeneration"]
    values = known(row, OWNER)
    if tag == "R44_WAKE":
        return wake, session, "", "WAKE", known(row, ("screenOn", "showRequest", "firstPostRead", "omitted"))
    if tag == "R44_READ" and read:
        row["readerComplete"] = completion(row)
        return wake, session, read, "READ", known(row, READ_STATE)
    if tag in {"R449_ADMISSION", "R44_9_ADMISSION"} and revision is not None:
        read = f"revision:{revision}"
        row["screenOn"] = row.get("screenAt", row.get("screenOn", UNKNOWN))
        row["power"] = row.get("powerMenu", row.get("power", UNKNOWN))
        row["locked"] = row.get("keyguardLocked", row.get("locked", UNKNOWN))
        row["authority"] = "APPLIED_TO_WAKE"
        if row.get("reason") == "CLEAR":
            row["readerComplete"] = "COMPLETE_EXCLUSIONS"
        elif row.get("reason") in {"TRUNCATED", "ROOT_UNAVAILABLE", "INCOMPLETE"}:
            row["readerComplete"] = row["reason"]
        values.update(known(row, ADMISSION + ("readerComplete",)))
        # An issue carried in a later admission is a wake-level receipt, not this revision's issue.
        return wake, session, read, "ADMISSION", values
    if tag == "R45_EVENT":
        stage = row.get("stage", "INGRESS")
        if stage == "MATERIAL_DENIED" and revision is not None:
            # This line may retain the classification even when the admission row is lost.
            # Keep the stage separate so a fragment cannot stand in for an admission.
            return wake, session, f"revision:{revision}", "MATERIAL_DENIED", known(row, ADMISSION)
        if stage == "TERMINAL":
            return wake, session, "", "TERMINAL", {"reason": row.get("detail", UNKNOWN), "at": row.get("at", UNKNOWN)}
        if stage == "INTENT":
            return wake, session, "", "INTENT", known(row, ("at",))
        seq = number(row.get("sequence") or row.get("seq"))
        if stage == "INGRESS" and seq is not None:
            row["at"] = row.get("at", row.get("received", UNKNOWN))
            return wake, session, "", f"INGRESS:{seq}", known(row, ("at", "decision", "revision"))
    if tag in {"R446_OUTPUT", "R44_6_SAMPLE"}:
        row["normalSurface"], _, reason = row.get("normal", UNKNOWN).partition("/")
        row["normalReason"] = reason or UNKNOWN
        handoff = row.get("handoff", UNKNOWN)
        ordinal = number(row.get("decisionOrdinal") or row.get("ordinal"))
        if not output and read and ordinal and handoff not in (UNKNOWN, "NOT_REQUIRED"):
            row["decision"] = handoff
            row["eligibility"] = row.get("eligibility", row.get("eligible", UNKNOWN))
            order = re.search(r"\border=\w+\(result=([A-Z_]+)", payload)
            row["authority"] = order[1] if order else row.get("order", UNKNOWN)
            if handoff == "PRIVATE_NOT_AUTHORIZED":
                row["domain"] = "PRIVATE"  # This return is reached only by the real private predicate.
                row["authority"] = "CURRENT_AT_PRE_ISSUE_CHECK"
            row["readEnd"] = row.get("readFinishedAt", row.get("readEnd", UNKNOWN))
            row["decisionAt"] = row.get("decisionAt", row.get("decide", UNKNOWN))
            return wake, session, read, f"DECISION:{ordinal}", values | known(row, ADMISSION + ("decisionAt", "scene"))
        if not output:
            return None
        if tag == "R446_OUTPUT":
            row["issue"] = row.get("issuedAt", UNKNOWN)
            row["submit"] = row.get("submittedAt", UNKNOWN)
            row["frame"] = row.get("frameAt", UNKNOWN)
        else:
            read = f"req:{row['progressReq']}" if number(row.get("progressReq")) else ""
        return wake, session, read, "OUTPUT", values | known(row, ("backend", "issue", "submit", "frame", "attachBegin", "attachEnd"))
    if tag == "R44_DECISION" and read:
        return wake, session, read, "CLASSIFICATION", known(row, ("mode", "testProbeInjected", "verdict", "reason"))
    if tag == "R44_9_OUTCOME":
        return wake, session, "", "OUTCOME", known(row, ("arm", "backend", "issue", "frame", "terminal"))
    if tag in {"R44_9_FLUVI_RECOVERY", "R449_RECOVERY"}:
        original = number(row.get("initialReq"))
        if original:
            return wake, session, f"req:{original}", "RECOVERY", known(row, ("arm", "stage", "successor", "at"))
    if tag == "R448_WORKER" and read:
        return wake, session, read, "WORKER", values | known(row, (
            "queued", "started", "finished", "outcome", "eligibility", "authorityAtEnd"))
    if tag == "R448_SYSTEM_VETO":
        row["requestCaptureMatched"] = row.get("requestCaptureMatched", UNKNOWN)
        return wake, session, "", f"SYSTEM_VETO:{row.get('requestId', UNKNOWN)}", known(row, (
            "reason", "receivedAt", "mainAt", "keyguardLocked", "interactive", "displayOn",
            "displayOff", "available", "requestCaptureMatched"))
    if tag == "EVENT":
        stage = row.get("stage")
        if read and stage in LIFECYCLE:
            return wake, session, read, stage, known(row, ("up", "el", "reason"))
        if stage in {"WAKE_CYCLE_STARTED", "SCREEN_ON_RECEIVED"}:
            return wake, session, "", stage, known(row, ("up", "el", "reason"))
    return None


def scene_window(payload):
    row = fields(payload, WINDOW_FIELD)
    window = row.get("win", "").split("/")
    root = row.get("root", "").split("/")
    if len(window) != 6 or len(root) != 2:
        return {}
    entry = re.compile(r"([A-Za-z_][A-Za-z0-9_]*)@(\d+):(\d+):(\d+)")
    entries = []
    if root == ["SYSTEMUI", "true"] and window[3] == "0" and window[5] == "false":
        # Store only technical structural entries, never labels, names, or notification-derived IDs.
        entries = [dict(entry=item[1], ordinal=int(item[2]), parent=int(item[3]), depth=int(item[4]))
                   for item in entry.finditer(row.get("ids", "")) if item[1] in STRUCTURE]
    return {
        "window": window[0], "type": window[1], "layer": window[2], "display": window[3],
        "active": window[4], "own": window[5], "root": root[0], "verified": root[1],
        "visibilityCounts": row.get("nodes", UNKNOWN), "idOverflow": row.get("idOverflow", UNKNOWN),
        "unverified": row.get("unverified", UNKNOWN), "entries": entries,
    }


def scene_observation(payload, windows):
    row = fields(payload, WINDOW_FIELD)
    req, at = number(row.get("req")), number(row.get("up"))
    if at is None:
        return None
    values = known(row, ("classification", "markers", "scene", "up", "source", "windowOmitted",
                         "ownAmbiguous", "unavailable", "stale", "truncated", "resourceLookup",
                         "hold", "reportIds", "retrieveWindows"))
    values["windows"] = windows
    values["readerComplete"] = completion(row)
    read = f"req:{req}" if req else f"observer:{at}"
    return number(row.get("wake")), number(row.get("session")), read, f"SCENE:{at}", values


def merge(records):
    """Merge complementary summary/spool fields; keep contradictory values and their source."""
    columns = defaultdict(dict)
    multiplicity = set()
    for record in records:
        if not record.values:
            continue
        multiplicity.add((record.origin, record.line))
        for key, value in record.values.items():
            if value != UNKNOWN:
                encoded = json.dumps(value, sort_keys=True)
                columns[key].setdefault(encoded, []).append(record.evidence())
    merged = {}
    for key, variants in columns.items():
        if len(variants) == 1:
            merged[key] = json.loads(next(iter(variants)))
        else:
            # OUTPUT rows can be successive receipts. Do not turn one backend
            # string into either an invented latest state or a contradiction.
            kind = "observations" if key == "backend" and records[0].stage == "OUTPUT" else "conflict"
            merged[key] = {kind: [{"value": json.loads(v), "sources": s} for v, s in variants.items()]}
    return merged | {"sources": [f"{origin}:{line}" for origin, line in sorted(multiplicity)]}


def unique(values):
    values = [v for v in values if not isinstance(v, dict) and v != UNKNOWN]
    return values[0] if values and all(v == values[0] for v in values) else UNKNOWN


def phase_value(stages, name):
    values = [row.get(name, UNKNOWN) for row in stages.values()]
    if any(isinstance(value, dict) for value in values):
        return UNKNOWN
    return unique(values)


def intervals_for(read, bookmarks, capture, session, wake):
    fields_seen = read["stages"]
    start = number(phase_value(fields_seen, "start")) if "READ" in fields_seen else None
    end = number(phase_value(fields_seen, "end")) if "READ" in fields_seen else None
    if start is None and "ADMISSION" in fields_seen:
        start, end = (number(fields_seen["ADMISSION"].get(key)) for key in ("readStart", "readEnd"))
    if start is None or end is None or end < start or session is None:
        return []
    return [label for label in bookmarks if label["capture"] == capture and label.get("session", session) == session
            and label.get("wake", wake) == wake and label["start"] <= start <= end <= label["end"]]


def verify_bookmarks(bookmarks):
    for label in bookmarks:
        if (label.get("scene") not in SCENES or label.get("clock") != "uptimeMs" or
                label.get("source") not in {"owner_bookmark", "independent_ui_automation_boundaries"} or
                not isinstance(label.get("start"), int) or not isinstance(label.get("end"), int) or
                not 0 <= label["start"] < label["end"] or not isinstance(label.get("capture"), str)):
            raise ValueError("expected independently identified uptimeMs bookmark intervals")
        if label["source"] == "owner_bookmark" and any(type(label.get(k)) is not int for k in ("session", "wake")):
            raise ValueError("owner bookmark needs exact session and wake")
    return bookmarks


def stock_bookmarks(path):
    with Path(path).open(encoding="utf-8") as file:
        header = fields(file.readline().strip())
        if header.get("source") != "independent_ui_automation_boundaries":
            raise ValueError("stock labels must come from the independent fixture")
        return verify_bookmarks([
            dict(capture=header.get("captureId"), scene=row.get("scene"), start=number(row.get("begin")),
                 end=number(row.get("end")), clock=row.get("clock"), source=header["source"])
            for line in file for row in [fields(line.strip())] if row.get("status") == "OBSERVED_ENDPOINTS"
        ])


def owner_of(item, candidates):
    observed = tuple(item.values.get(key, UNKNOWN) for key in OWNER)
    compatible = [owner for owner in candidates
                  if all(a == UNKNOWN or b == UNKNOWN or a == b for a, b in zip(observed, owner))]
    # Fill only a unique known value among compatible partial identities.
    return tuple(a if a != UNKNOWN else unique(
        [candidate[index] for candidate in compatible]) for index, a in enumerate(observed))


def last_read_stage(stages):
    if "OUTPUT" in stages and any(stages["OUTPUT"].get(k, UNKNOWN) != UNKNOWN
                                  for k in ("issue", "attachBegin", "attachEnd", "submit", "frame")):
        return "BACKEND_RECEIPT"
    if "ADMISSION" in stages or any(key.startswith("DECISION:") for key in stages):
        return "DECISION_RECORDED"
    if "MATERIAL_DENIED" in stages:
        return "DECISION_FRAGMENT"
    if "READ" in stages or "INSPECTION_FINISHED" in stages or number(stages.get("WORKER", {}).get("finished")):
        return "READ_RETURNED"
    if "INSPECTION_STARTED" in stages or number(stages.get("WORKER", {}).get("started")):
        return "READ_STARTED"
    if "INSPECTION_QUEUED" in stages or number(stages.get("WORKER", {}).get("queued")):
        return "QUEUED"
    if any(key.startswith("SCENE:") for key in stages):
        return "SCENE_OBSERVED"
    return UNKNOWN


def analyze(path, bookmarks=()):
    header, native, loss, lines, summary, spool, size, digest, full = envelope(path)
    capture, route = header["captureId"], header["route"]
    observed, sessions, foreign = [], defaultdict(set), 0
    material = []
    for (a, b), source in [(summary, "summary"), (spool, "spool")]:
        i = a + 1
        summary_wake = None
        while i < b:
            line = lines[i].strip()
            line_no = i + 1
            i += 1
            tag, _, payload = line.partition(" ")
            row = fields(payload)
            identity = row.get("captureId", row.get("capture", capture))
            if (identity not in {capture, UNKNOWN} or row.get("routeConfirmed", route) not in {route, UNKNOWN} or
                    (tag == "R45_EVENT" and row.get("route", route) not in {route, UNKNOWN})):
                foreign += 1
                continue
            if source == "summary":
                if tag == "R44_WAKE":
                    summary_wake = number(row.get("wake")), number(row.get("session"))
                elif tag == "R44_END":
                    summary_wake = None
                if summary_wake and tag in {"R44_4_PROFILE", "R44_4_WINDOW", "R44_5_INDEX", "R44_5_ID"}:
                    request = number(row.get("req"))
                    wake, session = summary_wake
                    if wake and request:
                        stage = tag
                        if tag in {"R44_4_WINDOW", "R44_5_ID"}:
                            stage += ":" + row.get("id" if tag == "R44_4_WINDOW" else "role", UNKNOWN)
                        metrics = ("id", "relativeLayer", "type", "active", "focused", "owner", "verified", "rootRole",
                                   "role", "outcome", "hitsCap9", "reject", "installedSmall", "installedLarge",
                                   "installedEntry", "status", "clockResource")
                        observed.append(Observation(wake, session, f"req:{request}", stage,
                                                    known(row, metrics), source, line_no))
                    continue
            if tag == "R47_MATERIAL":
                sample = known(row, ("origin", "sourceRevision", "animated", "playback", "frameStatus"))
                if sample and sample not in material:
                    material.append(sample)
                continue
            if tag == "R43_SCENE":
                scene, *views = SCENE_WINDOW.split(payload)
                while i < b and lines[i].lstrip().startswith("R43_WINDOW "):
                    views.append(lines[i].strip())
                    i += 1
                result = scene_observation(scene, [window for v in views if (window := scene_window(v))])
            else:
                result = normalize(tag, payload)
            results = [result]
            if tag in {"R446_OUTPUT", "R44_6_SAMPLE"}:
                results.append(normalize(tag, payload, output=True))
            for record in results:
                if record is None or not record[0]:
                    continue
                wake, session, read, stage, values = record
                if session is not None:
                    sessions[wake].add(session)
                observed.append(Observation(wake, session, read, stage, values, source, line_no))

    grouped = defaultdict(list)
    for event in observed:
        session = event.session
        if session is None and len(sessions[event.wake]) == 1:
            session = next(iter(sessions[event.wake]))
        grouped[session, event.wake].append(event)

    wakes = []
    for (session, wake), observations in sorted(grouped.items(), key=lambda item: (item[0][0] or 0, item[0][1])):
        groups = defaultdict(list)
        explicit = defaultdict(set)
        for item in observations:
            if item.read and any(key in item.values for key in OWNER):
                explicit[item.read].add(tuple(item.values.get(key, UNKNOWN) for key in OWNER))
        for item in observations:
            owner = owner_of(item, explicit[item.read]) if item.read else ()
            groups[item.read, owner, item.stage].append(item)

        subsets = defaultdict(dict)
        for (read, owner, stage), records in groups.items():
            subsets[read, owner][stage] = merge(records)
        wake_stages = subsets.pop(("", ()), {})
        reads = []
        completed = 0
        for (read, owner), stages in sorted(subsets.items()):
            decision = phase_value({k: v for k, v in stages.items()
                                   if k == "ADMISSION" or k.startswith("DECISION:")}, "decision")
            if decision != UNKNOWN:
                completed += 1
            item = {
                "id": read, "owner": dict(zip(OWNER, owner)),
                "domain": phase_value(stages, "domain"),
                "readerCompleteness": phase_value(stages, "readerComplete"),
                "positiveMainMarker": UNKNOWN,
                "normalSurface": phase_value(stages, "normalSurface"),
                "materialCurrent": phase_value(stages, "materialCurrent"),
                "exclusions": {k: phase_value(stages, k) for k in ("credential", "shade", "foreign", "power")},
                "decision": decision, "authority": phase_value(stages, "authority"),
                "lastProvenStage": last_read_stage(stages),
                "backend": stages.get("OUTPUT", {}).get("backend", UNKNOWN), "stages": stages,
            }
            scene_values = [value for key, value in stages.items() if key.startswith("SCENE:")]
            counts = [value.get("markers", UNKNOWN) for value in scene_values]
            sample = unique(counts)
            if isinstance(sample, str) and (match := re.match(r"main:(\d+),", sample)):
                item["positiveMainMarker"] = ("TRUE" if int(match[1]) else "FALSE"
                                              if item["readerCompleteness"] == "COMPLETE" else UNKNOWN)
            matches = intervals_for(item, bookmarks, capture, session, wake)
            item["label"] = matches[0]["scene"] if len(matches) == 1 else "UNLABELLED"
            if len(matches) == 1:
                item["labelEvidence"] = matches[0]
            reads.append(item)
        screen = phase_value({k: v for k, v in wake_stages.items() if k == "WAKE"}, "screenOn")
        outcome = wake_stages.get("OUTCOME", {})
        terminal = wake_stages.get("TERMINAL", {})
        reason = unique([terminal.get("reason", UNKNOWN), outcome.get("terminal", UNKNOWN)])
        if any(isinstance(value, dict) for value in (terminal.get("reason"), outcome.get("terminal"))):
            reason = UNKNOWN
        for item in reads:
            # The terminal belongs to the wake. It is not a completion receipt for this request.
            item["wakeTerminal"] = reason
        ingress = [v for k, v in wake_stages.items() if k.startswith("INGRESS:")]
        reassess = sum(1 for row in ingress if row.get("decision") == "REASSESS")
        wakes.append({
            "session": session if session is not None else UNKNOWN, "wake": wake,
            "kind": "WAKE" if number(screen) or any(k in wake_stages for k in ("WAKE_CYCLE_STARTED", "SCREEN_ON_RECEIVED"))
                    else "WAKE_ID_WITHOUT_OBSERVED_SCREEN_ON",
            "screenOn": screen, "clock": "uptimeMs",
            "terminal": reason, "retainedDecisions": completed,
            "decisionCoverage": "RETAINED" if completed else "INCONCLUSIVE",
            "retainedIngress": len(ingress), "retainedReassessments": reassess,
            "physical": UNKNOWN, "stages": wake_stages, "reads": reads,
        })
    return {
        "capture": capture, "route": route, "app": native.get("build", UNKNOWN),
        "end": header.get("end", UNKNOWN), "bodyBytes": size, "bodySha256": digest, "fileSha256": full,
        "lossAndObserverCost": loss, "excludedForeignRecords": foreign, "material": material,
        "wakes": wakes,
    }


def candidate_matrix(reports):
    rows = []
    for report in reports:
        for wake in report["wakes"]:
            for read in wake["reads"]:
                if read["label"] == "UNLABELLED":
                    continue
                for stage, scene in read["stages"].items():
                    if not stage.startswith("SCENE:"):
                        continue
                    up = number(scene.get("up"))
                    label = read["labelEvidence"]
                    if (up is None or not label["start"] <= up <= label["end"] or
                            read["stages"].get("READ", {}).get("scene", UNKNOWN) == UNKNOWN or
                            read["stages"]["READ"]["scene"] != scene.get("scene") or
                            scene.get("readerComplete") != "COMPLETE" or scene.get("ownAmbiguous") != "false"):
                        continue
                    features = set()
                    windows = scene.get("windows", [])
                    if not isinstance(windows, list):
                        continue
                    for w in windows:
                        if w["root"] != "SYSTEMUI" or w["verified"] != "true" or w["active"] != "true":
                            continue
                        for entry in w["entries"]:
                            features.add(f"active_systemui:{entry['entry']}:depth={entry['depth']}")
                    covered = (scene.get("windowOmitted") == "0" and scene.get("resourceLookup") == "AVAILABLE"
                               and scene.get("reportIds") == "true" and scene.get("retrieveWindows") == "true"
                               and bool(windows) and all(w["idOverflow"] == "0" for w in windows))
                    rows.append((report["capture"], wake["session"], wake["wake"], read["id"],
                                 read["label"], covered, features))
    main, other = [r for r in rows if r[4] == "MAIN"], [r for r in rows if r[4] != "MAIN"]
    matrix = []
    for feature in sorted(set().union(*(r[6] for r in main))):
        positives = {r[:3] for r in main if feature in r[6]}
        collisions = [r[:5] for r in other if feature in r[6]]
        negatives = sorted({r[4] for r in other if r[5] and feature not in r[6]})
        verdict = ("REJECT_NEGATIVE_COLLISION" if collisions else
                   "OBSERVATIONAL_ONLY" if len(positives) >= 2 and {"PIN", "SHADE", "FOREIGN"} <= set(negatives)
                   else "INCONCLUSIVE")
        matrix.append(dict(feature=feature, positiveWakes=len(positives), negativeCollisions=collisions,
                           completeNegativeScenes=negatives, verdict=verdict))
    return matrix


def main():
    cli = argparse.ArgumentParser(description=__doc__)
    cli.add_argument("recordings", type=Path, nargs="+")
    cli.add_argument("--bookmarks", type=Path, help="independently documented stable interval JSON")
    cli.add_argument("--stock-bookmarks", type=Path, action="append", default=[], help="synthetic API37 fixture ledger")
    args = cli.parse_args()
    try:
        labels = verify_bookmarks(json.loads(args.bookmarks.read_text(encoding="utf-8"))) if args.bookmarks else []
        for stock in args.stock_bookmarks:
            labels += stock_bookmarks(stock)
        reports = [analyze(path, labels) for path in args.recordings]
        json.dump({"recordings": reports, "candidateMatrix": candidate_matrix(reports)}, sys.stdout, indent=2)
        print()
    except (ValueError, TypeError, OSError) as error:
        cli.exit(2, f"R48 intake rejected: {error}\n")


if __name__ == "__main__":
    main()

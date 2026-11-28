"""R53 fixture. One direct swipe unlock on the pinned signed R52 installation."""

import argparse
from contextlib import contextmanager
from decimal import Decimal
from io import BytesIO
import json
from pathlib import Path
import re
import subprocess
import time

from PIL import Image

import r52_measure as stock
from r52_video import color_at
from r53_pixels import PixelWitness, reference_phase
from r53_video import analyze

APP = stock.PKG
OBSERVER = stock.WITNESS
REFERENCE = "com.fluvi.r53.reference"
COMPONENT = REFERENCE + "/.ReferenceActivity"
OLD_COMPONENT = OBSERVER + "/.R52ReferenceActivity"
APP_SOURCE = "7705f87c0c8f2bdf930a528b5bc6f87d276676a5"
TRACE_CONFIG = Path(__file__).with_name("trace.pbtxt")
FAILURES = (AssertionError, OSError, ValueError, subprocess.SubprocessError)


def image(raw):
    return Image.open(BytesIO(raw)).convert("RGB")


def save_json(device, filename, value):
    device.save(filename, (json.dumps(value, indent=2) + "\n").encode())


def now(device):
    return int(Decimal(device.shell("cat", "/proc/uptime").split()[0]) * 1_000_000_000)


def activity(device, package, name):
    data = device.adb("shell", "dumpsys", "activity", "activities")
    device.save(name + "-activities.txt", data)
    active = [line for line in data.decode(errors="replace").splitlines()
              if ("topResumedActivity" in line or "mResumedActivity" in line) and package + "/" in line]
    tasks = set(int(n) for line in active for n in re.findall(r"\bt(\d+)\b", line))
    pid = device.shell("pidof", package).split()
    assert len(tasks) == 1 and len(pid) == 1 and pid[0].isdigit(), (package, active, pid)
    return {"task": tasks.pop(), "pid": int(pid[0])}


def launch(device, phase, name, component=COMPONENT):
    # This driver launches a normal Activity explicitly while unlocked.
    launch_receipt = device.shell(
        f"cat /proc/uptime; am start -W --activity-single-top -n {component} --ei sync {phase}; cat /proc/uptime"
    )
    device.save(name + "-launch.txt", launch_receipt.encode())
    assert "Status: ok" in launch_receipt, launch_receipt
    return stock.bracket(launch_receipt)


def paint(device, phase, name, detector=reference_phase):
    until = time.monotonic() + 7
    while time.monotonic() < until:
        raw = device.adb("exec-out", "screencap", "-p")
        device.save(name + ".png", raw)
        if detector(image(raw)) == phase:
            return image(raw)
        time.sleep(.15)
    raise AssertionError(f"{name} did not paint phase {phase}")


def lifecycle(device):
    unlocked = ("ON", "false", "true")
    if stock.r51.system_state(device, "lifecycle-initial") != unlocked:
        device.shell("input", "keyevent", "KEYCODE_WAKEUP")
        stock.unlock(device)
    assert stock.r51.system_state(device, "lifecycle-unlocked") == unlocked
    launch(device, 0, "shared-before", OLD_COMPONENT)
    paint(device, 0, "shared-before", color_at)
    old = activity(device, OBSERVER, "shared-before")
    assert stock.r51.system_state(device, "shared-observer-original") == unlocked
    old_after_pids = device.shell(f"pidof {OBSERVER} || true").split()
    source = device.adb("shell", "dumpsys", "activity", "activities")
    device.save("shared-after-activities.txt", source)
    old_after = device.adb("exec-out", "screencap", "-p")
    device.save("shared-after.png", old_after)
    assert str(old["pid"]) not in old_after_pids and color_at(image(old_after)) != 0, (
        "R1 RED not reproduced", old, old_after_pids
    )
    device.note(f"R1 RED shared observer lost PID {old['pid']} and colored destination")
    launch(device, 0, "reference-before")
    neutral = paint(device, 0, "reference-before")
    before = activity(device, REFERENCE, "reference-before")
    assert stock.r51.system_state(device, "reference-observer-original") == unlocked
    remaining = activity(device, REFERENCE, "reference-after")
    assert before == remaining
    after = paint(device, 0, "reference-after")
    assert neutral.size == after.size
    result = dict(shared_before=old, shared_after_pids=old_after_pids,
                  reference_before=before, reference_after=remaining, extent=neutral.size,
                  r1_red="PASS_REPRODUCED", r1_separate="PASS")
    save_json(device, "reference-lifecycle.json", result)
    device.note(f"R1 PASS reference PID {before['pid']} task {before['task']} and both fiducials survived")
    return neutral.size


@contextmanager
def record(device, extent, trial):
    remote_mp4 = "/data/local/tmp/r53-unlock.mp4"
    remote_trace = "/data/misc/perfetto-traces/r53-unlock.pftrace"
    previous_trace = set(device.shell("pidof perfetto || true").split())
    trace_process = subprocess.run(["adb", "shell", "perfetto", "--txt", "-c", "-", "--background",
                                    "-o", remote_trace], input=TRACE_CONFIG.read_bytes(),
                                   capture_output=True, timeout=15, check=False)
    device.save("trace-start.txt", trace_process.stdout + b"\n" + trace_process.stderr)
    trace_pids = set(device.shell("pidof perfetto || true").split()) - previous_trace
    assert not device.shell("pidof screenrecord || true").strip(), "nonfixture screenrecord already active"
    capture_begin = now(device)
    try:
        with (device.output / "screenrecord.log").open("wb") as out:
            proc = subprocess.Popen(["adb", "shell", "screenrecord", "--time-limit", "70", "--size",
                                     f"{extent[0]}x{extent[1]}", "--bit-rate", "5000000", remote_mp4],
                                    stdout=out, stderr=subprocess.STDOUT)
            try:
                time.sleep(.65)
                assert proc.poll() is None, "screenrecord ended before the start reference"
                yield
            finally:
                pids = device.shell("pidof screenrecord || true").split()
                if len(pids) == 1 and pids[0].isdigit():
                    device.shell("kill", "-INT", pids[0])
                try:
                    proc.wait(17)
                except subprocess.TimeoutExpired:
                    proc.terminate()
                    proc.wait(5)
        trial["recording_bracket_ns"] = [capture_begin, now(device) + 10_000_000]
    finally:
        pull = subprocess.run(["adb", "pull", remote_mp4, str(device.output / "unlock.mp4")],
                              timeout=35, capture_output=True, check=False)
        device.save("video-pull.txt", pull.stdout + b"\n" + pull.stderr)
        if trace_process.returncode == 0:
            if len(trace_pids) == 1 and next(iter(trace_pids)).isdigit():
                device.shell(f"kill -INT {next(iter(trace_pids))} 2>/dev/null || true")
                time.sleep(.5)
            else:
                # Automatic 75-second trace limit is the fallback.
                remaining_ns = 77_000_000_000 - (now(device) - capture_begin)
                if remaining_ns > 0:
                    time.sleep(remaining_ns / 1e9)
            raw = subprocess.run(["adb", "pull", remote_trace, str(device.output / "unlock.pftrace")],
                                 timeout=35, capture_output=True, check=False)
            device.save("trace-pull.txt", raw.stdout + b"\n" + raw.stderr)
        device.shell("rm", "-f", remote_mp4, remote_trace)


def draw_records(device, start, reference_sha, task):
    raw = device.adb("logcat", "-d", "-v", "monotonic", "-s", "FluviR53Reference:I")
    device.save("reference-draws.txt", raw)
    pattern = r"source=(\w+) phase=(\d+) task=(\d+) display=(\d+) extent=(\d+)x(\d+) upBefore=(\d+) elapsedNs=(\d+) upAfter=(\d+)"
    draws = {}
    for source, phase, owner, display, w, h, up, elapsed, end in re.findall(pattern, raw.decode()):
        if source != reference_sha or int(owner) != task or int(elapsed) < start:
            continue
        draws.setdefault(int(phase), dict(display=int(display), extent=[int(w), int(h)],
                                          elapsed_ns=int(elapsed), up_before_ms=int(up), up_after_ms=int(end)))
    return draws


def sample(device, args, name, extent, trial):
    size = tuple(extent)
    trial.update(name=name, route="unlock", display=0, extent=size, fixture="INCONCLUSIVE", action_issued=False)
    reference = None
    try:
        stock.arm(device, name, 50)
        assert stock.readback(device, "normal-50-confirmed", 50) == [50]
        with record(device, size, trial):
            launch(device, 1, "start-color")
            paint(device, 1, "start-color")
            launch(device, 0, "before-lock")
            assert paint(device, 0, "neutral-before").size == size
            reference = activity(device, REFERENCE, "return-destination-before")
            assert stock.r51.system_state(device, "neutral-still-unlocked") == ("ON", "false", "true")
            assert activity(device, REFERENCE, "return-destination-after-read") == reference
            device.shell("input", "keyevent", "KEYCODE_SLEEP")
            stock.independent_state(device, "sleep-before-wake", stock.sleeping)
            painted, rect = stock.r51.wake(device, "lock-main")
            assert painted.size == size and rect[2] - rect[0] == rect[3] - rect[1]
            density = int(re.findall(r"\d+", device.shell("wm", "density").splitlines()[-1])[-1])
            assert rect[2] - rect[0] == round(112 * density / 160), (rect, density)
            trial["bounds"] = rect
            painted.save(device.output / "painted-main.png")
            device.save("pre-action-wm.txt", device.adb("shell", "dumpsys", "window", "windows"))
            trial["state_before"] = stock.r51.system_state(device, "action-pre")
            assert trial["state_before"] == ("ON", "true", "true")
            PixelWitness(painted, image((device.output / "neutral-before.png").read_bytes()), rect)
            trial["action_issued"] = True
            result = stock.unlock(device, size[0] // 5, size[1])
            device.save("direct-swipe.txt", result.encode())
            trial["action_bracket_ns"] = stock.bracket(result)
            device.save("first-request.png", device.adb("exec-out", "screencap", "-p"))
            unlocked = ("ON", "false", "true")
            trial["state_after"] = stock.independent_state(device, "action-negative", lambda s: s == unlocked)
            observed = activity(device, REFERENCE, "return-destination")
            assert observed == reference, (reference, observed)
            assert paint(device, 0, "return-neutral").size == size
            time.sleep(5)
            assert stock.r51.system_state(device, "held-after-unlock") == unlocked
            assert activity(device, REFERENCE, "held-destination") == reference
            assert paint(device, 0, "held-neutral").size == size
            trial["destination_witnessed"] = True
            trial["fixture"] = "VALID_SOFTWARE"
            launch(device, 2, "end-color")
            paint(device, 2, "end-color")
    except FAILURES as error:
        trial["error"] = str(error)
        device.note(f"setup/action limit {name}: {error}")
    finally:
        save_json(device, "trial.json", trial)
    return reference


def summary(device, trial, reference, args):
    identity = {}
    if trial["action_issued"]:
        try:
            document = stock.copy(device, "unlock", APP_SOURCE, 2, 50)
            row = stock.match_windows(document, [trial])[0]
            save_json(device, "owned-software-row.json", row)
            if (row.get("match"), row.get("dp"), row.get("displayId"), row.get("reason")) == (
                "MATCHED", "112", "0", "UNLOCKED"
            ):
                identity["owner"] = (APP, *(int(row[k]) for k in ("s", "e", "w", "id")))
                identity["local_hide_ns"] = int(row["localHide"].split(",")[2])
                for field, name in (("lockedControl", "locked_read_interval_ns"),
                                    ("publicNegative", "unlocked_read_interval_ns")):
                    if row[field] != "UNOBSERVED":
                        identity[name] = [int(v) for v in row[field].split(",")[3:5]]
        except FAILURES as error:
            device.save("copy-error.txt", (str(error) + "\n").encode())
    if reference and "recording_bracket_ns" in trial and "bounds" in trial:
        try:
            draws = draw_records(device, trial["recording_bracket_ns"][0], args.reference_sha, reference["task"])
            verdict = analyze(device.output, trial, identity, draws)
            device.note(f"FRAME VERDICT {verdict['verdict']['status']} clock={verdict['absolute_recorder_clock']}")
        except FAILURES as error:
            device.save("frame-error.txt", (str(error) + "\n").encode())
    save_json(device, "app-identity.json", identity)


def prepare(device, args):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == "37"
    ids = {}
    for pkg, apk in ((APP, args.apk), (OBSERVER, args.observer), (REFERENCE, args.reference)):
        assert b"Success" in device.adb("install", apk, timeout=90)
        declaration = device.shell("cmd", "package", "list", "packages", "-U", pkg)
        uids = re.findall(rf"^package:{re.escape(pkg)}\s+uid:(\d+)\s*$", declaration, re.M)
        assert len(uids) == 1, declaration
        ids[pkg] = int(uids[0])
    assert len(set(ids.values())) == 3
    save_json(device, "installed-uids.json", ids)
    stock.baseline_metadata(device, args)
    extent = lifecycle(device)
    # Enable the existing swipe lock on this disposable stock image, if needed.
    if device.shell("locksettings", "get-disabled").strip() == "true":
        device.shell("locksettings", "set-disabled", "false")
    device.shell("am", "start", "-W", "-n", stock.r51.ACTIVITY)
    stock.r51.stock.enter_settings(device)
    widget = stock.r51.stock.prepare_binding(device)
    device.click("2×2 (112 dp)", package=APP)
    device.save("widgets.txt", device.adb("shell", "dumpsys", "appwidget"))
    device.note(f"Bound widget {widget.decode()} for 112 dp plain ORB")
    return extent


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--observer", type=Path, required=True)
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--reference-sha", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.api, args.sha = "37.0", APP_SOURCE
    device = stock.r51.Device(args.output)
    try:
        extent = prepare(device, args)
        for attempt in (1, 2):
            step = stock.r51.Device(device.output / f"attempt-{attempt}")
            trial = {}
            reference = sample(step, args, f"attempt-{attempt}", extent, trial)
            summary(step, trial, reference, args)
            if trial["action_issued"]:
                assert trial["fixture"] == "VALID_SOFTWARE", trial
                assert (step.output / "frame-report.json").is_file(), "frames were retained with an analysis error"
                break
            assert attempt == 1, "no qualified pre-action setup in the two allowed attempts"
            # Restore unlocked state for the single permitted pre-action replacement.
            step.shell("input", "keyevent", "KEYCODE_WAKEUP")
            step.shell("wm", "dismiss-keyguard")
            stock.panel(step)
            if "Leállítás" in stock.labels(step):
                step.click("Leállítás", package=APP)
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

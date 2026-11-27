"""One exact signed installation per device, two independent withdrawal routes."""
from contextlib import contextmanager
import argparse
import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import time
from io import BytesIO
from PIL import Image

from r52_video import analyze_video, color_at

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("r51_fixture", ROOT / "scripts/test-r51-orb-transitions.py")
r51 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r51)
PKG = r51.PKG
WITNESS = r51.WITNESS
REF = WITNESS + "/.R52ReferenceActivity"
BASE = "e7542639d22d78d10e7b123e836ee9bc9758c91a"
SYSTEM = {1: "OFF", 2: "ON", 3: "DOZE", 4: "DOZE_SUSPEND"}
VIDEO_SIZE = "540x1200"
EXPERIMENT_FAILURES = (AssertionError, OSError, subprocess.SubprocessError, ValueError)


def baseline_metadata(device, args):
    for key in ("window_animation_scale", "transition_animation_scale", "animator_duration_scale"):
        value = device.shell("settings", "get", "global", key)
        device.note(f"{key}={value}")
        assert value in {"1", "1.0", "null"}, f"Unexpected {key}={value}"
    device.save("perfetto-sources.txt", device.adb("shell", "perfetto", "--query"))
    device.save("display.txt", device.adb("shell", "dumpsys", "display"))
    device.save("input.txt", device.adb("shell", "dumpsys", "input"))
    device.save("power.txt", device.adb("shell", "dumpsys", "power"))
    device.save("surfaceflinger-displays.txt", device.adb("shell", "dumpsys", "SurfaceFlinger", "--display-id"))
    identity = (args.sha, args.apk.stat().st_size, hashlib.file_digest(args.apk.open("rb"), "sha256").hexdigest())
    device.note(f"API {args.api} build {device.shell('getprop', 'ro.build.fingerprint')} artifact={identity}")


def labels(device):
    return r51.label_screen(device)


def panel(device):
    r51.panel(device)
    if "Felvétel indítása" not in labels(device) and "Leállítás" not in labels(device):
        device.click(r51.PANEL, package=PKG)


def readback(device, name, expected):
    state = device.adb("shell", "dumpsys", "accessibility")
    device.save(name + "-service.txt", state)
    chosen = [line for line in state.decode().splitlines()
              if "label=Fluvi zárképernyős ORB" in line and "Bound services" in line]
    values = [int(n) for line in chosen for n in re.findall(r"notificationTimeout[=: ]+(\d+)", line)]
    device.note(f"FRAMEWORK {name} expected={expected} observed={values}")
    return values


def arm(device, name, timeout):
    panel(device)
    initial = labels(device)
    assert any("50 ms" in label and ("Visszaállítva" in label or "Visszaolvasott" in label)
               for label in initial), initial
    device.click(f"{'A' if timeout == 50 else 'B'} · {timeout} ms", package=PKG)
    readback(device, name + "-before", 50)
    device.click("Felvétel indítása", package=PKG)
    device.click(f"Aktív beállítás: {timeout} ms", package=PKG, limit=8)
    assert "Leállítás" in labels(device), "Native start acknowledgement was absent"
    framework = readback(device, name + "-armed", timeout)
    assert not framework or framework == [timeout], "Framework timeout did not match the panel"


def copy(device, name, sha, version, timeout=None, stop=False):
    panel(device)
    if stop:
        device.click("Leállítás", package=PKG)
        device.click("Lezárt felvétel", package=PKG, limit=8)
    device.click("Vágólapra másolás", package=PKG)
    device.click("Felvétel a vágólapon.", package=PKG, limit=8)
    if timeout is not None:
        assert "Visszaállítva: 50 ms" in labels(device)
        last = readback(device, name + "-restored", 50)
        assert not last or last == [50]
    device.shell("run-as", WITNESS, "rm", "-f", "files/paste.txt")
    device.shell("am", "start", "-S", "-W", "-n", WITNESS + "/.ClipboardWitness", "--ez", "paste", "true")
    until = time.monotonic() + 6
    while time.monotonic() < until:
        result = subprocess.run(["adb", "shell", "run-as", WITNESS, "test", "-s", "files/paste.txt"],
                                timeout=4, check=False, capture_output=True)
        if result.returncode == 0:
            break
        time.sleep(.15)
    data = device.adb("exec-out", "run-as", WITNESS, "cat", "files/paste.txt")
    device.save(name + "-clipboard.txt", data)
    assert len(data) <= 131072
    assert data.startswith(f"FLUVI_WA_LOCKSCREEN_CAPTURE_V{version}\n".encode())
    body, hashline = data.rsplit(b"sha256=", 1)
    assert hashlib.sha256(body).hexdigest().encode() == hashline.strip()
    assert f"build={sha} purpose=HUMAN_DIAGNOSTIC".encode() in body
    if timeout is not None:
        assert f"armMs={timeout} baselineMs=50 armReadbackMs={timeout} restore=RESTORED restoreReadbackMs=50 armError=NONE".encode() in body
    device.note(f"COPY {name} V{version} bytes={len(data)} bodySHA={hashline.decode().strip()}")
    return data


def set_reference(device, code, name):
    text = device.shell(
        f"cat /proc/uptime; am start -W --activity-single-top -n {REF} --ei sync {code}; cat /proc/uptime"
    )
    before, _ = bracket(text)
    observed = None
    for _ in range(3):
        raw = device.adb("exec-out", "screencap", "-p")
        timestamp = device.shell("cat", "/proc/uptime")
        observed = color_at(Image.open(BytesIO(raw)).convert("RGB"))
        if observed == code:
            device.save(name + "-anchor.png", raw)
            break
    device.save(name + "-anchor.txt", (text + "\n" + timestamp + f" observed={observed}\n").encode())
    if observed != code:
        device.note(f"{name} visual sync {code} was not witnessed")
        return None
    return [before, int((float(timestamp.split()[0]) + .010) * 1e9)]


def bracket(text):
    times = [float(line.split()[0]) for line in text.splitlines() if re.fullmatch(r"[0-9.]+ [0-9.]+", line)]
    assert len(times) >= 2, text
    # The kernel prints the pair to 10 ms precision.
    return [int(times[0] * 1e9), int((times[-1] + .010) * 1e9)]


@contextmanager
def witnesses(device, name):
    log = device.output / (name + "-screenrecord.log")
    video = f"/data/local/tmp/{name}.mp4"
    trace = f"/data/misc/perfetto-traces/{name}.pftrace"
    config = ROOT / ".github/r52-stock/trace.pbtxt"
    record = None
    tracer = None
    try:
        try:
            device.adb("push", config, "/data/local/tmp/r52.pbtxt")
            device.shell("perfetto", "--txt", "-c", "/data/local/tmp/r52.pbtxt", "--background", "-o", trace)
            tracer = trace
        except subprocess.SubprocessError as error:
            device.note(f"{name} TRACE start unavailable: {error}")
        with log.open("wb") as handle:
            record = subprocess.Popen(["adb", "shell", "screenrecord", "--time-limit", "110",
                                       "--size", VIDEO_SIZE, "--bit-rate", "2500000", video],
                                      stdout=handle, stderr=subprocess.STDOUT)
            time.sleep(.7)
            yield
    finally:
        if record is not None:
            subprocess.run(["adb", "shell", "pkill", "-INT", "-x", "screenrecord"],
                           timeout=5, capture_output=True, check=False)
            try:
                record.wait(timeout=15)
            except subprocess.TimeoutExpired:
                record.terminate()
                record.wait(timeout=5)
            subprocess.run(["adb", "pull", video, str(device.output / (name + ".mp4"))],
                           timeout=30, capture_output=True, check=False)
        if tracer is not None:
            subprocess.run(["adb", "shell", "pkill", "-INT", "-x", "perfetto"],
                           timeout=5, capture_output=True, check=False)
            time.sleep(.5)
            subprocess.run(["adb", "pull", trace, str(device.output / (name + ".pftrace"))],
                           timeout=25, capture_output=True, check=False)
            subprocess.run(["adb", "shell", "rm", "-f", trace, video], timeout=5, check=False)
        device.save(name + "-witness-logcat.txt", device.adb("logcat", "-d", "-v", "monotonic",
                                                            "-s", "FluviR52Witness:I"))


def independent_state(device, name, predicate):
    deadline = time.monotonic() + 8
    attempt = 0
    while time.monotonic() < deadline:
        state = r51.system_state(device, f"{name}-{attempt:02d}")
        if predicate(state):
            return state
        attempt += 1
        time.sleep(.12)
    raise AssertionError(f"{name} independent state was {state}")


def sleeping(state):
    return state[0] in {"OFF", "DOZE", "DOZE_SUSPEND"} and state[1:] == ("true", "false")


def unlock(device, x=210, height=2400):
    return device.shell(f"cat /proc/uptime; input swipe {x} {int(height*.91)} {x} {int(height*.34)} 290; cat /proc/uptime")


def home(device):
    device.shell("input", "keyevent", "KEYCODE_WAKEUP")
    state = r51.system_state(device, "home-pre")
    if state[1] == "true":
        unlock(device)
        state = r51.system_state(device, "home-after-swipe")
    if state[1] == "true":
        # Cleanup only. A failed direct swipe retains its invalid measurement.
        device.shell("wm", "dismiss-keyguard")
    device.shell("input", "keyevent", "KEYCODE_HOME")
    independent_state(device, "home", lambda s: s == ("ON", "false", "true"))


def trial(device, name, route):
    row = {"name": name, "route": route, "fixture": "INCONCLUSIVE"}
    try:
        if route not in ("unlock", "sleep"):
            raise ValueError(route)
        now = r51.system_state(device, name + "-pre-wake")
        if not sleeping(now):
            device.shell("input", "keyevent", "KEYCODE_SLEEP")
            independent_state(device, name + "-pre-lock", sleeping)
        image, box = r51.wake(device, name + "-visible")
        image.save(device.output / (name + "-painted-pre.png"))
        row["bounds"] = box
        row["extent"] = image.size
        row["painted"] = True
        # A fresh state sample is separate from the independent composed crop.
        row["state_before"] = r51.system_state(device, name + "-action-pre")
        assert row["state_before"] == ("ON", "true", "true")
        action = (unlock(device, image.width // 5, image.height) if route == "unlock"
                  else device.shell("cat /proc/uptime; input keyevent KEYCODE_SLEEP; cat /proc/uptime"))
        device.save(name + "-action.txt", action.encode())
        row["action_bracket_ns"] = bracket(action)
        raw = device.adb("exec-out", "screencap", "-p")
        device.save(name + "-after-first-request.png", raw)
        sought = (lambda s: s == ("ON", "false", "true")) if route == "unlock" else sleeping
        state = independent_state(device, name + "-negative", sought)
        row["state_after"] = state
        # Keep the identified state for at least five seconds before the next wake.
        time.sleep(5)
        row["state_held"] = r51.system_state(device, name + "-held")
        assert sought(row["state_held"])
        settled, remaining = device.capture(name + "-settled")
        row["settled_root"] = remaining
        settled.crop(box).save(device.output / (name + "-absent-crop.png"))
        assert remaining is None, f"ORB root remains after the confirmed {route} state"
        row["fixture"] = "VALID_SOFTWARE"
    except EXPERIMENT_FAILURES as error:
        row["error"] = str(error)
        device.note(f"{name} {route} fixture did not qualify: {error}")
    device.note(json.dumps(row))
    return row


def save_run(device, name, arm_ms, rows, anchors, software):
    (device.output / (name + "-trials.json")).write_text(json.dumps(rows, indent=2) + "\n")
    if software is not None:
        compare = match_windows(software, rows)
        with (device.output / (name + "-app.csv")).open("w") as out:
            headers = list(dict.fromkeys(name for row in compare for name in row))
            writer = csv.DictWriter(out, fieldnames=headers)
            writer.writeheader()
            writer.writerows(compare)
    try:
        analyze_video(device.output, name, rows, anchors)
    except EXPERIMENT_FAILURES as error:
        device.note(f"{name} video endpoint INCONCLUSIVE: {error}")
    device.note(f"{name} arm={arm_ms} attempted={len(rows)} valid-software={sum(r['fixture']=='VALID_SOFTWARE' for r in rows)}")


def match_windows(text, rows):
    fields = [dict(item.split("=", 1) for item in line.split()[1:])
              for line in text.decode().splitlines() if line.startswith("WINDOW_SUMMARY ")]
    result = []
    for action in rows:
        row = {"name": action["name"], "route": action["route"], "fixture": action["fixture"]}
        result.append(row)
        if "action_bracket_ns" not in action:
            continue
        low, high = action["action_bracket_ns"]
        contenders = []
        for owner in fields:
            if owner["nonzero"] == "UNOBSERVED" or owner["localHide"] == "UNOBSERVED":
                continue
            nonzero = owner["nonzero"].split(",")
            local = owner["localHide"].split(",")
            reason = owner["reason"]
            if int(nonzero[2]) < low + 10_000_000 and low <= int(local[2]) <= high + 5_000_000_000:
                if (action["route"] == "unlock" and reason in {"UNLOCKED", "USER_PRESENT"}) or (
                        action["route"] == "sleep" and reason in {"DISPLAY", "SCREEN_OFF", "NONINTERACTIVE"}):
                    contenders.append(owner)
        if len(contenders) != 1:
            row["match"] = f"INCONCLUSIVE_{len(contenders)}_OWNERS"
            continue
        row.update(contenders[0])
        row["match"] = "MATCHED"
        trigger, decision, local = (row[k].split(",") for k in ("trigger", "decision", "localHide"))
        if len(trigger) > 5 and trigger[5].isdigit():
            row["event_age_ms"] = int(trigger[1]) - int(trigger[5])
        if len(decision) > 2:
            row["decision_to_local_ns"] = int(local[2]) - int(decision[2])
            for key, label in (("probeNegative", "probe_end_to_decision_ns"),
                               ("publicNegative", "public_read_end_to_decision_ns")):
                if row[key] != "UNOBSERVED":
                    row[label] = int(decision[2]) - int(row[key].split(",")[4])
        for key in ("detach", "firstRemove", "lastRemove", "hostStop"):
            if row[key] != "UNOBSERVED":
                row["local_to_" + key + "_ns"] = int(row[key].split(",")[2]) - int(local[2])
    return result


def run_block(device, args, index, arm_ms, order):
    name = f"block{index}-{arm_ms if arm_ms is not None else 'OFF'}"
    rows = []
    anchors = {}
    software = None
    # Arm before waking, while the real Flutter console is foreground.
    if arm_ms is not None:
        arm(device, name, arm_ms)
    else:
        framework = readback(device, name + "-ordinary", 50)
        assert not framework or framework == [50]
    with witnesses(device, name):
        anchors["start"] = set_reference(device, 1, name + "-start")
        time.sleep(.18)
        set_reference(device, 0, name + "-start-neutral")
        for route in order:
            row = trial(device, f"{name}-{route}", route)
            rows.append(row)
            if "action_bracket_ns" not in row:
                # One replacement only, for a setup that never reached the action.
                rows.append(trial(device, f"{name}-{route}-replacement", route))
        home(device)
        anchors["end"] = set_reference(device, 2, name + "-end")
        time.sleep(.25)
        set_reference(device, 0, name + "-end-neutral")
    if arm_ms is not None:
        software = copy(device, name, args.sha, 2, arm_ms, stop=index == 2)
        if index == 1:
            assert software == copy(device, name + "-recopy", args.sha, 2, arm_ms)
    save_run(device, name, arm_ms, rows, anchors, software)
    return any(row["fixture"] != "VALID_SOFTWARE" for row in rows)


def prepare(device, args):
    assert device.shell("getprop", "ro.kernel.qemu") == "1"
    assert device.shell("getprop", "ro.build.version.sdk") == args.api.split(".")[0]
    assert b"Success" in device.adb("install", args.apk, timeout=90)
    assert b"Success" in device.adb("install", args.observer)
    device.shell("wm", "dismiss-keyguard")
    device.shell("locksettings", "set-disabled", "false")
    device.shell("settings", "put", "secure", "lock_screen_lock_after_timeout", "0")
    device.shell("settings", "put", "secure", "doze_always_on", 0)
    device.shell("settings", "put", "secure", "doze_enabled", 0)
    device.shell("am", "start", "-W", "-n", r51.ACTIVITY)
    if "Quickstep isn't responding" in r51.stock.visible_labels(device.screen()):
        device.click("Close app", limit=6)
        device.shell("am", "start", "-W", "-n", r51.ACTIVITY)
    r51.stock.enter_settings(device)
    widget = r51.stock.prepare_binding(device)
    device.click("2×2 ORB", package=PKG)
    device.save("widgets.txt", device.adb("shell", "dumpsys", "appwidget"))
    device.note(f"Preset saved, 112 dp widget={widget.decode()} swipe-only lock mode")
    # Dedicated blank synthetic launcher provides an independent pixel reference.
    device.shell("cmd", "package", "set-home-activity", REF)
    device.shell("input", "keyevent", "KEYCODE_HOME")
    baseline_metadata(device, args)
    return widget


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--api", required=True)
    parser.add_argument("--observer", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    device = r51.Device(args.output)
    failures = []
    try:
        prepare(device, args)
        # Test video on an external, visible scene change before the first trial.
        try:
            with witnesses(device, "candidate-calibration"):
                start = set_reference(device, 1, "calibration-start")
                time.sleep(.9)
                end = set_reference(device, 2, "calibration-end")
                time.sleep(.9)
            analyze_video(device.output, "candidate-calibration", [], {"start": start, "end": end})
        except EXPERIMENT_FAILURES as error:
            device.note(f"External witness calibration INCONCLUSIVE: {error}")
        blocks = (50, 0, 0, 50, None) if args.api == "37.0" else (50, 0)
        for index, arm_ms in enumerate(blocks, 1):
            try:
                home(device)
                routes = ("sleep", "unlock") if index in (3, 4) else ("unlock", "sleep")
                if run_block(device, args, index, arm_ms, routes):
                    failures.append(f"block{index}: invalid trial retained")
            except EXPERIMENT_FAILURES as error:
                failures.append(f"block{index}: {error}")
                device.note(f"BLOCK {index} failed: {error}")
                try:
                    home(device)
                    panel(device)
                    if "Leállítás" in labels(device):
                        device.click("Leállítás", package=PKG)
                except EXPERIMENT_FAILURES as cleanup:
                    device.note(f"BLOCK {index} cleanup: {cleanup}")
        assert not failures, failures
    finally:
        device.save("logcat.txt", device.adb("logcat", "-d", "-v", "threadtime"))


if __name__ == "__main__":
    main()

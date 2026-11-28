"""Copy from the real existing product action and verify the bytes on the clipboard."""
import hashlib
import re
import subprocess
import time
from pathlib import Path

import mask_controls as masks
import r52_measure as stock

BASE = "41add67b7f4d4ecdf7a0a48abff64ca85364ac9e"


def copy(device, name, sha, debug=False):
    if debug:
        stock.panel(device)
        assert "Leállítás" not in stock.labels(device), "manual capture was armed"
    else:
        masks.settings(device)
    device.click("Legutóbbi feloldás másolása", package=stock.PKG)
    device.click("A feloldási napló a vágólapon van.", package=stock.PKG, limit=8)
    device.save(name + "-settings.xml", device.screen())
    witness = stock.WITNESS
    device.shell("run-as", witness, "rm", "-f", "files/paste.txt")
    device.shell("am", "start", "-S", "-W", "-n", witness + "/.ClipboardWitness", "--ez", "paste", "true")
    end = time.monotonic() + 8
    while time.monotonic() < end:
        if subprocess.run(["adb", "shell", "run-as", witness, "test", "-s", "files/paste.txt"],
                          timeout=3, capture_output=True).returncode == 0:
            break
        time.sleep(.15)
    raw = device.adb("exec-out", "run-as", witness, "cat", "files/paste.txt")
    device.save(name + "-clipboard.txt", raw)
    assert raw.startswith(b"FLUVI_WA_LAST_UNLOCK_V1\n") and len(raw) <= 4096
    body, tail = raw.rsplit(b"bodySha256=", 1)
    assert tail == hashlib.sha256(body).hexdigest().encode() + b"\n"
    fields = dict(re.findall(r"(\w+)=([^\s]+)", body.decode()))
    assert fields["package"] == stock.PKG and fields["build"] == sha
    assert (fields["version"], fields["code"]) == (("0.1.5", "7") if sha == BASE else ("0.1.6", "8"))
    assert fields["reason"] in ("UNLOCKED", "USER_PRESENT", "RESTRICTED")
    return raw, fields

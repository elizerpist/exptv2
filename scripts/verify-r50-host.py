#!/usr/bin/env python3
"""Inspect real manifest components, resources and DEX definitions in the narrowed product."""
import argparse
from pathlib import Path
import re
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

ANDROID = "{http://schemas.android.com/apk/res/android}"
WA_SERVICE = "tk.zwander.lockscreenwidgets.services.Accessibility"
FLUVI = "com.fluvi.app.MainActivity"
ORB_PROVIDERS = {
    "com.fluvi.app.widget.orb.FluviHeaderOrbWidgetProvider",
    "com.fluvi.app.widget.orb.FluviOrbWidgetProvider",
    "com.fluvi.app.widget.financial.FluviFinancialSnapshotWidgetProvider",
}
REMOVED = (
    "FluviKeyguardCardService", "KeyguardR448WidgetsAnywhereFrame", "KeyguardR446WindowPresenter",
    "KeyguardR46RecordingStore", "KeyguardR448DisplayRoute", "FluviOrbLockscreenTrialProvider",
    "R35DebugResidentService", "FluviActiveHeaderMaterialStore", "integration_test", "bugsnag",
)
REQUIRED = {
    "com.fluvi.wa.WaLockscreenService", "com.fluvi.wa.WaOrbWindow", "com.fluvi.wa.WaOrbHost", WA_SERVICE,
    "com.fluvi.app.widget.orb.HeaderOrbBinding", "com.fluvi.app.widget.orb.HeaderOrbPackage",
} | ORB_PROVIDERS
WA_NAMESPACES = ("tk.zwander.", "dev.zwander.")
WA_PERMISSIONS = {
    "android.permission.CALL_PHONE", "android.permission.SET_WALLPAPER",
    "android.permission.READ_CALL_LOG", "android.permission.WRITE_SECURE_SETTINGS",
    "android.permission.REQUEST_DELETE_PACKAGES", "android.permission.SYSTEM_ALERT_WINDOW",
}


def component(entry):
    name = entry.get(ANDROID + "name", "")
    return ("com.fluvi.app" + name) if name.startswith(".") else name


def filters(entry, attribute):
    return {child.get(ANDROID + "name") for item in entry.findall("intent-filter")
            for child in item.findall(attribute)}


def dex_definitions(data):
    """Resolve class_def -> type_id -> string_id. References cannot pass this check."""
    if data[:4] != b"dex\n":
        raise ValueError("Invalid DEX header")
    _, string_offset, _, type_offset = struct.unpack_from("<4I", data, 56)
    class_count, class_offset = struct.unpack_from("<2I", data, 96)
    for index in range(class_count):
        class_index = struct.unpack_from("<I", data, class_offset + index * 32)[0]
        string_index = struct.unpack_from("<I", data, type_offset + class_index * 4)[0]
        start = struct.unpack_from("<I", data, string_offset + string_index * 4)[0]
        while data[start] & 0x80:
            start += 1
        start += 1
        descriptor = data[start:data.index(0, start)]
        yield descriptor[1:-1].decode("utf-8", errors="replace").replace("/", ".")


def checks(manifest, definitions=None):
    app = manifest.find("application")
    services = [component(service) for service in app.findall("service")
                if "android.accessibilityservice.AccessibilityService" in filters(service, "action")]
    launchers = [component(activity) for activity in app.findall("activity") + app.findall("activity-alias")
                 if "android.intent.category.LAUNCHER" in filters(activity, "category")]
    providers = {component(entry) for entry in app.findall("receiver") if any(
        meta.get(ANDROID + "name") == "android.appwidget.provider" for meta in entry.findall("meta-data")
    )}
    names = {component(entry) for entry in app}
    permissions = {entry.get(ANDROID + "name") for entry in manifest if entry.tag.startswith("uses-permission")}
    assertions = [
        (manifest.get("package") == "com.fluvi.app", "application package"),
        (services == [WA_SERVICE], f"sole service, found {services}"),
        (launchers == [FLUVI], f"sole launcher, found {launchers}"),
        (providers == ORB_PROVIDERS, f"fixed and launcher providers, found {providers}"),
        (not component(app).startswith(WA_NAMESPACES), "WA Application removed"),
        (not {n for n in names if n.startswith(WA_NAMESPACES)} - {WA_SERVICE}, "obsolete WA components removed"),
        (not any(old in name for old in REMOVED for name in names), "retired component removed"),
        (not permissions & WA_PERMISSIONS, f"WA-only permissions removed: {permissions & WA_PERMISSIONS}"),
        ("android.permission.QUERY_ALL_PACKAGES" in permissions, "independent notification source discovery"),
    ]
    if definitions is not None:
        wa = {name for name in definitions if name.startswith(WA_NAMESPACES) and name != WA_SERVICE
              and not name.startswith(WA_SERVICE + "$")}
        assertions.extend([
            (not wa, f"generic WA class definitions removed: {sorted(wa)[:5]}"),
            (REQUIRED <= definitions, f"required definitions: {sorted(REQUIRED - definitions)}"),
            (not any(old in name for old in REMOVED for name in definitions), "retired definitions removed"),
        ])
    return [message for passes, message in assertions if not passes]


def main():
    parser = argparse.ArgumentParser()
    inputs = parser.add_mutually_exclusive_group(required=True)
    inputs.add_argument("--manifest", type=Path)
    inputs.add_argument("--apk", type=Path)
    args = parser.parse_args()
    definitions = None
    if args.apk:
        manifest = ET.fromstring(subprocess.check_output(["apkanalyzer", "manifest", "print", args.apk]))
        with zipfile.ZipFile(args.apk) as apk:
            names = apk.namelist()
            definitions = {cls for name in names if re.fullmatch(r"classes\d*\.dex", name)
                           for cls in dex_definitions(apk.read(name))}
            assert "assets/licenses/widgets-anywhere/LICENSE" in names
            assert "assets/licenses/widgets-anywhere/LICENSE.md" in names
            assert not any("lswwallpaper" in name or "tasker" in name for name in names)
            assert "lib/arm64-v8a/libapp.so" in names or "lib/arm64-v8a/libflutter.so" in names
    else:
        manifest = ET.parse(args.manifest).getroot()
    errors = checks(manifest, definitions)
    for error in errors:
        print(f"FAIL {error}", file=sys.stderr)
    if not errors:
        print("PASS Fluvi product, one WA service, one fixed lockscreen provider, two home providers")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())

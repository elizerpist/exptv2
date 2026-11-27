#!/usr/bin/env python3
"""Verify ownership and removal in source or in an installed-artifact manifest."""
import argparse
from pathlib import Path
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

ANDROID = "{http://schemas.android.com/apk/res/android}"
ACCESSIBILITY = "android.accessibilityservice.AccessibilityService"
WA_SERVICE = "tk.zwander.lockscreenwidgets.services.Accessibility"
WA_APP = "tk.zwander.lockscreenwidgets.App"
ORB = "com.fluvi.app.widget.orb.FluviHeaderOrbWidgetProvider"
FLUVI = "com.fluvi.app.MainActivity"
OLD = (
    "FluviKeyguardCardService", "KeyguardR448WidgetsAnywhereFrame",
    "KeyguardR446WindowPresenter", "KeyguardR46RecordingStore",
    "KeyguardR448DisplayRoute", "FluviOrbLockscreenTrialProvider",
    "R35DebugResidentService", "FluviActiveHeaderMaterialStore",
    "fluvi/keyguard_material", "dev/flutter/plugins/integration_test",
)


def component(entry):
    name = entry.get(ANDROID + "name", "")
    return ("com.fluvi.app" + name) if name.startswith(".") else name


def filters(entry, attribute):
    return {child.get(ANDROID + "name") for item in entry.findall("intent-filter")
            for child in item.findall(attribute)}


def checks(manifest, dex=None):
    app = manifest.find("application")
    services = [component(service) for service in app.findall("service")
                if ACCESSIBILITY in filters(service, "action")]
    launchers = [component(activity) for activity in app.findall("activity") + app.findall("activity-alias")
                 if "android.intent.category.LAUNCHER" in filters(activity, "category")]
    receivers = {component(entry) for entry in app.findall("receiver")
                 if any(meta.get(ANDROID + "name") == "android.appwidget.provider"
                        for meta in entry.findall("meta-data"))}
    names = {component(entry) for entry in app}
    errors = []
    for ok, why in [
        (services == [WA_SERVICE], f"expected sole WA accessibility service, found {services}"),
        (component(app) == WA_APP, "expected original WA Application lifecycle"),
        (launchers == [FLUVI], f"expected sole Fluvi launcher, found {launchers}"),
        (ORB in receivers, "current-header AppWidget provider absent"),
        ({"com.fluvi.app.widget.orb.FluviOrbWidgetProvider",
          "com.fluvi.app.widget.financial.FluviFinancialSnapshotWidgetProvider"} <= receivers,
         "existing launcher providers absent"),
        (all(not any(old in name for old in OLD) for name in names),
         "retired component in manifest"),
    ]:
        if not ok:
            errors.append(why)
    if dex is not None:
        for required in ("WidgetFrameDelegate", "WidgetHostCompat", "WidgetViewCacheRegistry",
                         "BaseBindWidgetActivity", "AddFrameWidgetActivity"):
            if f"/{required};".encode() not in dex:
                errors.append(f"upstream host class absent: {required}")
        for retired in OLD:
            if retired.encode() in dex:
                errors.append(f"retired runtime still in DEX: {retired}")
    return errors


def main():
    parser = argparse.ArgumentParser()
    inputs = parser.add_mutually_exclusive_group(required=True)
    inputs.add_argument("--manifest", type=Path)
    inputs.add_argument("--apk", type=Path)
    args = parser.parse_args()
    dex = None
    if args.apk:
        manifest = ET.fromstring(subprocess.check_output(["apkanalyzer", "manifest", "print", args.apk]))
        if manifest.get("package") != "com.fluvi.app":
            parser.error("unexpected application package")
        with zipfile.ZipFile(args.apk) as apk:
            dex = b"".join(apk.read(name) for name in apk.namelist() if name.endswith(".dex"))
    else:
        manifest = ET.parse(args.manifest).getroot()
    errors = checks(manifest, dex)
    for error in errors:
        print(f"FAIL {error}", file=sys.stderr)
    if not errors:
        print("PASS sole WA owner, Fluvi launcher and preserved/added AppWidget components")
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())

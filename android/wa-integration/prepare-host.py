#!/usr/bin/env python3
"""Stage the released Gradle project and apply the Fluvi product overlay."""
from pathlib import Path
import shutil
import os
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
VENDOR = ROOT / "third_party/widgets-anywhere"
ANDROID = "{http://schemas.android.com/apk/res/android}"
TOOLS = "{http://schemas.android.com/tools}"
WA = "tk.zwander.lockscreenwidgets"
ET.register_namespace("android", ANDROID[1:-1])
ET.register_namespace("tools", TOOLS[1:-1])


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError(f"Upstream overlay anchor drift: {old}")
    return text.replace(old, new)


def stage_settings(destination):
    target = destination / "settings.gradle.kts"
    text = replace_once(target.read_text(), 'include(":lswwallpaper")', "")
    target.write_text(replace_once(
        text, '        mavenLocal()',
        '''        maven(requireNotNull(System.getenv("FLUVI_PAYLOAD_REPO")))
        maven(requireNotNull(System.getenv("FLUVI_NATIVE_REPO")))
        maven("https://storage.googleapis.com/download.flutter.io") {
            content { includeGroup("io.flutter") }
        }''',
    ))


def stage_application(destination):
    target = destination / "app/build.gradle.kts"
    text = target.read_text()
    text = replace_once(text, 'applicationId = "tk.zwander.lockscreenwidgets"', 'applicationId = "com.fluvi.app"')
    text = replace_once(text, 'versionCode = 222', 'versionCode = 2')
    text = replace_once(text, 'versionName = "4.7.5"', 'versionName = "0.1.0"')
    text = replace_once(text, '    alias(libs.plugins.bugsnag)\n', '')
    start = text.index("bugsnag {\n")
    end = text.index("dependencies {", start)
    text = text[:start] + text[end:]
    text = replace_once(text, '    buildTypes {\n        all {', '''    buildTypes {
        create("profile") {
            initWith(getByName("release"))
            matchingFallbacks += "release"
        }
        all {''')
    text = replace_once(text, '    implementation(project(":lswinterconnect"))',
        '''    implementation(project(":lswinterconnect"))
    implementation("com.fluvi.native:fluvi-native:1.0")''')
    target.write_text(text)


def stage_manifest(destination):
    target = destination / "app/src/main/AndroidManifest.xml"
    manifest = ET.parse(target)
    root = manifest.getroot()
    app = root.find("application")
    app.set(ANDROID + "label", "Fluvi")
    app.set(TOOLS + "replace", "android:label")
    # App's original lifecycle remains the system Application. The explicit
    # WA activity remains the native entry to setup/onboarding.
    for entry in list(app):
        if entry.tag in {"activity", "activity-alias", "receiver", "service", "provider"}:
            name = entry.get(ANDROID + "name", "")
            if name.startswith("."):
                entry.set(ANDROID + "name", WA + name)
            if entry.tag in {"activity", "activity-alias"}:
                for filter_ in entry.findall("intent-filter"):
                    if any(c.get(ANDROID + "name") == "android.intent.category.LAUNCHER"
                           for c in filter_.findall("category")):
                        entry.remove(filter_)
                if entry.get(ANDROID + "name") == WA + ".MainActivity":
                    entry.set(ANDROID + "exported", "false")
        if entry.get(ANDROID + "name") == "com.bugsnag.android.API_KEY":
            app.remove(entry)
    for permission in root.findall("uses-permission"):
        if permission.get(ANDROID + "name") == WA + ".DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION":
            permission.set(ANDROID + "name", "${applicationId}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION")
    # Profile/debug builds can connect to Flutter's VM service.
    for mode in ("debug", "profile"):
        variant = destination / "app/src" / mode / "AndroidManifest.xml"
        if not variant.exists():
            variant.parent.mkdir(parents=True, exist_ok=True)
            variant.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
                               '    <uses-permission android:name="android.permission.INTERNET" />\n'
                               '</manifest>\n')
    for integration in (target, destination / "lswinterconnect/src/main/AndroidManifest.xml"):
        if integration == target:
            ET.indent(manifest, space="    ")
            manifest.write(target, encoding="utf-8", xml_declaration=True)
        xml = integration.read_text()
        integration.write_text(xml.replace(WA + ".WALLPAPER_INTERCONNECT", "com.fluvi.app.WALLPAPER_INTERCONNECT"))


def stage_defaults(destination):
    path = destination / "app/src/main/java/tk/zwander"
    app = path / "lockscreenwidgets/App.kt"
    text = app.read_text()
    start = text.index("        if (prefManager.enableBugsnag) {")
    end = text.index("        val previousHandler =", start)
    # This optional telemetry block is outside the WA host lifecycle.
    text = text[:start] + '        installFluviHostDefaults(this)\n\n' + text[end:]
    app.write_text(text)
    shutil.copy2(ROOT / "android/wa-integration/FluviHostDefaults.kt", app.parent)
    wallpaper = path / "common/util/WallpaperClient.kt"
    wallpaper.write_text(replace_once(wallpaper.read_text(),
        '"dev.zwander.lswwallpaper"', '"com.fluvi.app.wallpaper"'))
    # Include upstream notices in the distribution as well as the vendor tree.
    notices = destination / "app/src/main/assets/licenses/widgets-anywhere"
    notices.mkdir(parents=True, exist_ok=True)
    for name in ("LICENSE", "LICENSE.md"):
        shutil.copy2(VENDOR / name, notices / name)


def main():
    destination = Path(sys.argv[1])
    shutil.copytree(VENDOR, destination, symlinks=True)
    stage_settings(destination)
    stage_application(destination)
    stage_manifest(destination)
    stage_defaults(destination)
    if os.environ.get("FLUVI_R49_INCLUDE_FIXTURE") == "true":
        shutil.copytree(ROOT / "android/wa-integration/control-provider", destination / "r49-control")
        settings = destination / "settings.gradle.kts"
        settings.write_text(settings.read_text() + '\ninclude(":r49-control")\n')


if __name__ == "__main__":
    main()

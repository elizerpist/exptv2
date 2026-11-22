#!/usr/bin/env python3
"""Stage pinned Fluvi renderer fragments and generated assets for AOSP R29.

This only stages source. It does not apply a SystemUI patch or claim that a
platform binary has been compiled. All input digests must match the reviewed
canonical source and every generated shader must match its own metadata.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile

SOURCE_DIGESTS = {
    "android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardMaterialProfile.kt": "e37c2c1133a64d0643101f2da853025d04079c9de59f6e4edffb5a924e0ae3b4",
    "android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfaceMaterial.kt": "fff4b92322ea64808c08280584c7580bcec43d450b6721624d6e3b95b9b40c1f",
    "android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialView.kt": "b0997443f1a1e4fcd4f8b9131825111ad367b7c1a3537c314292eca95a7165ed",
    "android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardShaderArtifactStore.kt": "7daeea45f045bdbbb271a98a02c275786322a1e65cacc8935e10b22daa927b15",
    "shaders/dashboard_header_field.frag": "6be3e84d3e3ae6bffde549171b7319524768d67dbab1d55b74d565a4c76d4e7f",
}
SHADER_SOURCE = SOURCE_DIGESTS["shaders/dashboard_header_field.frag"]
GENERATOR_SHA256 = "a13d5e7766276eff02ac421bec70ce776aeeb6d282eff680faf5ea7f7f74a568"
EFFECTS = ("staticEffect", "dualTide", "magneticMembrane", "breathingLens", "cellularField",
           "balanceMembrane", "balanceCounterflow", "balanceCharges", "deepDrift", "freeFlow",
           "chaoticAdvection", "elasticSpace", "braidedCurrent", "volumetricCurrent", "metricBloom",
           "gravitationalFabric", "breathingMetric", "tidalCurvature")
PACKAGE = "com/fluvi/app/lockscreen/material"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def between(text, start, end):
    if text.count(start) != 1 or text.count(end) != 1:
        raise ValueError("source extraction markers are missing or ambiguous")
    return text[text.index(start):text.index(end)]


def stage(source, assets, output):
    source, assets, output = map(Path, (source, assets, output))
    if output.exists():
        raise ValueError("output already exists; refusing to overwrite")
    for rel, expected in SOURCE_DIGESTS.items():
        if sha((source / rel).read_bytes()) != expected:
            raise ValueError("source digest mismatch: " + rel)
    gradle = (source / "android/app/build.gradle.kts").read_text()
    generator = between(gradle, "// The keyguard card uses the same field mathematics as the Flutter Header.", "\nandroid {")
    # The pinned digest excludes the stable introductory marker itself.
    generator = generator.split("// The keyguard card uses the same field mathematics as the Flutter Header.", 1)[1]
    if sha(generator.encode()) != GENERATOR_SHA256:
        raise ValueError("shader generator digest mismatch")

    base = source / "android/app/src/main/kotlin/com/fluvi/app/lockscreen/material"
    profile = (base / "KeyguardMaterialProfile.kt").read_text()
    profile = profile.split("/** Ordering is intentionally independent", 1)[0]
    for line in ("import android.content.Context\n", "import android.os.Handler\n", "import android.os.Looper\n",
                 "import io.flutter.plugin.common.MethodChannel\n", "import java.util.concurrent.atomic.AtomicLong\n"):
        profile = profile.replace(line, "")
    header = (base / "KeyguardHeaderMaterialView.kt").read_text()
    scene = between(header, "/** Immutable clock anchor", "internal data class KeyguardMaterialRendererState(")
    time = between(header, "internal data class KeyguardMaterialTime(\n", "/**\n * Decorative retained view")
    shader = header[header.index("internal class KeyguardHeaderShader("):]
    artifact = (base / "KeyguardShaderArtifactStore.kt").read_text().split("/**\n * One bounded lane", 1)[0]
    for line in ("import android.os.Handler\n", "import android.os.Looper\n",
                 "import java.util.concurrent.ExecutorService\n", "import java.util.concurrent.Executors\n"):
        artifact = artifact.replace(line, "")
    prefix = "package com.fluvi.app.lockscreen.material\n\n"
    generated = {
        "KeyguardMaterialProfile.kt": profile,
        "KeyguardOrbSurfaceMaterial.kt": (base / "KeyguardOrbSurfaceMaterial.kt").read_text(),
        "KeyguardMaterialScene.kt": prefix + "import kotlin.math.max\n\n" + scene + time,
        "KeyguardShaderArtifact.kt": artifact,
        "KeyguardHeaderShader.kt": prefix + "import android.content.Context\nimport android.graphics.Color\n"
            "import android.graphics.RuntimeShader\nimport kotlin.math.cos\nimport kotlin.math.max\n"
            "import kotlin.math.min\nimport kotlin.math.sin\n\n" + shader,
    }
    # Validate everything before creating the destination, including all variants.
    asset_data = {}
    for shader_id, effect in enumerate(EFFECTS):
        for variant in ("plain", "portal"):
            stem = f"fluvi_keyguard_header_material_{effect}_{variant}"
            meta_bytes = (assets / (stem + ".meta")).read_bytes()
            metadata = dict(line.split("=", 1) for line in meta_bytes.decode().splitlines())
            agsl = (assets / (stem + ".agsl")).read_bytes()
            header_lines = [f"// generated-from=shaders/dashboard_header_field.frag",
                            f"// source-sha256={SHADER_SOURCE}", f"// effect-id={effect}", f"// variant={variant}"]
            prefix_bytes = ("\n".join(header_lines) + "\n").encode()
            if not agsl.startswith(prefix_bytes):
                raise ValueError("generated shader header mismatch: " + stem)
            expected = {"source-sha256": SHADER_SOURCE, "adapter-version": "9", "shader-abi-version": "6",
                        "effect-id": effect, "effect-shader-id": str(shader_id), "variant": variant}
            if any(metadata.get(k) != v for k, v in expected.items()):
                raise ValueError("shader metadata mismatch: " + stem)
            if sha(agsl[len(prefix_bytes):]) != metadata.get("generated-agsl-sha256"):
                raise ValueError("shader digest mismatch: " + stem)
            asset_data[stem + ".meta"] = meta_bytes
            asset_data[stem + ".agsl"] = agsl

    output.parent.mkdir(parents=True, exist_ok=True)
    temp = Path(tempfile.mkdtemp(prefix=".r29-stage-", dir=output.parent))
    try:
        srcdir = temp / "src" / PACKAGE
        assetdir = temp / "assets"
        srcdir.mkdir(parents=True)
        assetdir.mkdir()
        for name, contents in generated.items():
            (srcdir / name).write_text(contents)
        for name, contents in asset_data.items():
            (assetdir / name).write_bytes(contents)
        files = {str(path.relative_to(temp)): sha(path.read_bytes()) for path in sorted(temp.rglob("*")) if path.is_file()}
        manifest = {"schema": 1, "sourceFiles": SOURCE_DIGESTS, "generatorBlockSha256": GENERATOR_SHA256,
                    "shaderAbi": 6, "adapterVersion": 9, "effects": len(EFFECTS), "variants": 2, "files": files}
        (temp / "renderer-manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
        temp.rename(output)
    finally:
        if temp.exists():
            shutil.rmtree(temp)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--assets", required=True, help="Gradle generated/keyguardHeaderMaterial/assets")
    parser.add_argument("--output", required=True, help="must not exist")
    args = parser.parse_args()
    try:
        stage(args.source, args.assets, args.output)
    except (OSError, ValueError) as exc:
        parser.exit(1, f"R29 renderer staging failed: {exc}\n")

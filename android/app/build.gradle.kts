import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.security.MessageDigest

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// The keyguard card uses the same field mathematics as the Flutter Header.
// RuntimeShader speaks AGSL rather than Flutter runtime-effect GLSL, so keep
// the tiny, audited syntax adapter in the build instead of maintaining a
// second hand-edited shader.  Any upstream field change regenerates the asset
// and carries its SHA-256 into the installed APK for diagnostics.
val keyguardHeaderSource = rootProject.projectDir.parentFile.resolve("shaders/dashboard_header_field.frag")
val keyguardHeaderGeneratedAssets = layout.buildDirectory.dir("generated/keyguardHeaderMaterial/assets")
val keyguardHeaderSourceHash = "6be3e84d3e3ae6bffde549171b7319524768d67dbab1d55b74d565a4c76d4e7f"
// Bump only when the fixed, audited adapter changes.  This is intentionally
// separate from the canonical Flutter source hash: Android diagnostics must
// distinguish a source change from an AGSL adaptation change.
// RuntimeShader rejects the all-effects Flutter program as too large on API
// 35. The Header's effect is semantic configuration, not per-pixel input, so
// produce one mechanically-specialized AGSL program for each canonical
// shaderId. The compact entry point keeps only that effect family and injects
// its member ID as a numeric literal.  API-35's RuntimeShader treated the
// previous global-const selector as the static classic fallback, while a
// runtime uniform kept every member branch alive and exceeded its program-size
// budget. A literal lets SkSL remove the other branches before compilation.
val keyguardHeaderAdapterVersion = "5"
val keyguardHeaderEffects = listOf(
    "staticEffect" to 0,
    "dualTide" to 1,
    "magneticMembrane" to 2,
    "breathingLens" to 3,
    "cellularField" to 4,
    "balanceMembrane" to 5,
    "balanceCounterflow" to 6,
    "balanceCharges" to 7,
    "deepDrift" to 8,
    "freeFlow" to 9,
    "chaoticAdvection" to 10,
    "elasticSpace" to 11,
    "braidedCurrent" to 12,
    "volumetricCurrent" to 13,
    "metricBloom" to 14,
    "gravitationalFabric" to 15,
    "breathingMetric" to 16,
    "tidalCurvature" to 17,
)
val generateKeyguardHeaderMaterial by tasks.registering {
    inputs.file(keyguardHeaderSource)
    // Gradle must rerun when the fixed adapter changes even when the canonical
    // Flutter source has not. Otherwise an APK can retain an old AGSL asset
    // with the same source input and silently reintroduce a compiler failure.
    inputs.property("adapterVersion", keyguardHeaderAdapterVersion)
    outputs.dir(keyguardHeaderGeneratedAssets)
    doLast {
        val source = keyguardHeaderSource.readText()
        val hash = MessageDigest.getInstance("SHA-256")
            .digest(source.toByteArray())
            .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
        // The Dart bridge and native profile validator deliberately pin the
        // same source digest.  Failing here prevents a changed Header shader
        // from silently becoming a different Android scene contract.
        check(hash == keyguardHeaderSourceHash) {
            "dashboard_header_field.frag changed; update the keyguard material ABI/profile contract"
        }
        // This is deliberately a fixed adaptation of the known canonical
        // shader structure, not a generic text conversion pipeline.
        val sharedAgsl = source
            .replace("#include <flutter/runtime_effect.glsl>\n", "")
            .replace("out vec4 fragColor;\n", "")
            // AGSL exposes saturate as an intrinsic.  The canonical Flutter
            // program owns a helper with that name, so rename its declaration
            // and every complete identifier call without touching names such
            // as saturateColor.  The Flutter source remains untouched.
            .replace(Regex("\\bsaturate\\b"), "fluviSaturate")
            .replace("void main() {", "half4 main(float2 _fluviFragCoord) {")
            .replace("FlutterFragCoord()", "_fluviFragCoord")
            .replace("fragColor = vec4(composed, fluviSaturate(uOpacity));", "float _fluviAlpha = fluviSaturate(uOpacity);\n  return half4(composed * _fluviAlpha, _fluviAlpha);")
            .replace(Regex("\\bvec2\\b"), "float2")
            .replace(Regex("\\bvec3\\b"), "float3")
            .replace(Regex("\\bvec4\\b"), "float4")
            .replace(Regex("\\bmat2\\b"), "float2x2")
        check(sharedAgsl.contains("half4 main(float2 _fluviFragCoord)"))
        check(!sharedAgsl.contains("FlutterFragCoord"))
        check(!sharedAgsl.contains("runtime_effect.glsl"))
        check(!Regex("out\\s+vec4\\s+fragColor").containsMatchIn(sharedAgsl)) {
            "AGSL adapter retained the Flutter fragment output declaration"
        }
        check(!Regex("float\\s+saturate\\s*\\(").containsMatchIn(sharedAgsl)) {
            "AGSL adapter retained a custom saturate declaration"
        }
        check(sharedAgsl.contains("float fluviSaturate(float value)")) {
            "AGSL adapter did not rename the canonical saturate helper"
        }
        check(sharedAgsl.contains("return half4(")) { "AGSL adapter did not produce a return entry point" }
        check(sharedAgsl.contains("uniform float uEffect;")) {
            "AGSL adapter cannot specialize the canonical effect uniform"
        }
        val canonicalCommonField = """float3 commonField(float2 uv, float rippleLight) {
  if (uEffect < 8.5) return classicReferenceField(uv, rippleLight);
  if (uEffect < 13.5) return fullFieldFlowField(uv, rippleLight);
  return spaceFabricField(uv, rippleLight);
}"""
        check(sharedAgsl.contains(canonicalCommonField)) {
            "AGSL adapter cannot locate the canonical common-field dispatch"
        }
        val mainSignature = "half4 main(float2 _fluviFragCoord) {"
        check(sharedAgsl.contains(mainSignature)) {
            "AGSL adapter cannot locate the canonical entry point"
        }
        val destination = keyguardHeaderGeneratedAssets.get().asFile
        destination.mkdirs()
        keyguardHeaderEffects.forEach { (effectId, shaderId) ->
            // The overlay has no Header pointer/ripple/trail interaction. The
            // native binder pins all those uniforms to zero, so this compact
            // main is exactly the canonical zero-interaction path. More
            // importantly, it prevents SkSL from flattening the unused 25
            // trail and 10 ripple loops into RuntimeShader's strict program
            // size budget. Keep the actual selected effect, both Portals,
            // palette sampling and final alpha composition unchanged.
            val commonField = when (shaderId) {
                0 -> "return applyMaterialOptics(canonicalGradient(uv), uPulse * .025 + rippleLight * uTapPulseLight, 0.0);"
                8 -> "return deepDriftField(uv, rippleLight);"
                in 9..13 -> "return fullFieldFlowField(uv, rippleLight);"
                in 14..17 -> "return spaceFabricField(uv, rippleLight);"
                else -> "return classicReferenceField(uv, rippleLight);"
            }
            val specializedCommon = "float3 commonField(float2 uv, float rippleLight) {\n  $commonField\n}"
            val sourceUv = when (shaderId) {
                in 9..13 -> "fullFieldInverseFlowMap(%s, uPhase)"
                in 14..17 -> "spaceFabricSourceUv(%s, uPhase)"
                else -> "%s"
            }
            fun mapped(name: String) = sourceUv.format(name)
            val zeroInteractionMain = """
half4 main(float2 _fluviFragCoord) {
  float2 uv = _fluviFragCoord.xy / max(uRasterSize, float2(1.0));
  float2 displaced = uv;
  float rippleLight = 0.0;
  float backgroundMatter = uBackgroundEnabled > .5
      ? portalSample(displaced, uBackgroundEffect, uBackgroundPhase, 1.0)
      : 0.0;
  float backgroundCoordinate = portalMaterialCoordinate(
      ${mapped("displaced")}, backgroundMatter, uBackgroundCenter, uBackgroundWindow,
      uBackgroundPhase);
  float3 background = sampleCanonicalPalette(backgroundCoordinate);
  float3 base = commonField(displaced, rippleLight);
  float3 composed = mix(base, background, backgroundMatter);
  float2 interiorUv = displaced;
  if (uInteriorEnabled > .5 && uInteriorRotationEnabled > .5) {
    float aspect = uSize.x / max(1.0, uSize.y);
    float angle = uInteriorPhase * uInteriorRotationSpeed * PI * 2.0;
    float2x2 rotate = float2x2(cos(angle), -sin(angle), sin(angle), cos(angle));
    float2 centered = interiorUv - .5;
    centered.x *= aspect;
    centered = rotate * centered;
    centered.x /= aspect;
    interiorUv = mix(interiorUv, centered + .5, materialBoundaryEnvelope(interiorUv));
  }
  if (uInteriorEnabled > .5) {
    float matter = portalSample(interiorUv, uInteriorEffect, uInteriorPhase, 0.0);
    float interiorCoordinate = portalMaterialCoordinate(
        ${mapped("interiorUv")}, matter, uInteriorCenter, uInteriorWindow, uInteriorPhase);
    float3 interior = sampleCanonicalPalette(interiorCoordinate);
    composed = mix(composed, interior, matter * .38);
  }
  float _fluviAlpha = fluviSaturate(uOpacity);
  return half4(composed * _fluviAlpha, _fluviAlpha);
}
""".trim()
            val noPortalMain = """
half4 main(float2 _fluviFragCoord) {
  float2 uv = _fluviFragCoord.xy / max(uRasterSize, float2(1.0));
  float3 composed = commonField(uv, 0.0);
  float _fluviAlpha = fluviSaturate(uOpacity);
  return half4(composed * _fluviAlpha, _fluviAlpha);
}
""".trim()
            val agslPrefix = sharedAgsl.substringBefore(mainSignature)
                .replace(canonicalCommonField, specializedCommon)
                // Do not use a global `const float uEffect`: API-35 can
                // select the classic static fallback through that route. A
                // literal in the program body still enables compile-time
                // branch elimination, unlike the runtime uniform that made
                // this compact program too large for RuntimeShader.
                .replace("uniform float uEffect;\n", "")
                .replace(Regex("\\buEffect\\b"), "${shaderId}.0")
            check(!agslPrefix.contains("uEffect")) {
                "AGSL specialization retained the effect selector for $effectId"
            }
            listOf("plain" to noPortalMain, "portal" to zeroInteractionMain).forEach { (variant, main) ->
                val agsl = "$agslPrefix\n$main\n"
                val generatedHash = MessageDigest.getInstance("SHA-256")
                    .digest(agsl.toByteArray())
                    .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
                destination.resolve("fluvi_keyguard_header_material_${effectId}_$variant.agsl").writeText(
                    "// generated-from=shaders/dashboard_header_field.frag\n// source-sha256=$hash\n// effect-id=$effectId\n// variant=$variant\n$agsl",
                )
                destination.resolve("fluvi_keyguard_header_material_${effectId}_$variant.meta").writeText(
                    "source-sha256=$hash\ngenerated-agsl-sha256=$generatedHash\nadapter-version=$keyguardHeaderAdapterVersion\nshader-abi-version=6\neffect-id=$effectId\neffect-shader-id=$shaderId\nvariant=$variant\n",
                )
            }
        }
    }
}

android {
    namespace = "com.fluvi.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        applicationId = "com.fluvi.app"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
}

android.sourceSets.getByName("main").assets.srcDir(keyguardHeaderGeneratedAssets)
tasks.named("preBuild").configure { dependsOn(generateKeyguardHeaderMaterial) }

flutter {
    source = "../.."
}

dependencies {
    implementation(project(":fluvi-core"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    testImplementation("junit:junit:4.13.2")
    // Flutter's Android embedding pins the debug runtime to runner 1.2.0.
    // Keep the production RuntimeShader smoke on that compatible AndroidX
    // test family rather than relying on Gradle's inconsistent resolution.
    androidTestImplementation("androidx.test:runner:1.2.0")
    androidTestImplementation("androidx.test.ext:junit:1.1.1")
    androidTestImplementation("androidx.test:core:1.2.0")
}

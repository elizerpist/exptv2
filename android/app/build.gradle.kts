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
// shaderId. The compact entry point keeps only that effect family. For the
// classic family it additionally emits just the selected member's field body,
// but retains uEffect as its runtime guard. API-35's global-const/literal
// selector can resolve the classic path to a static fallback; retaining every
// runtime-selected member instead exceeds RuntimeShader's program-size budget.
val keyguardHeaderAdapterVersion = "6"
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
        fun closingBrace(sourceText: String, openingBrace: Int): Int {
            var depth = 0
            for (index in openingBrace..sourceText.lastIndex) {
                when (sourceText[index]) {
                    '{' -> depth += 1
                    '}' -> {
                        depth -= 1
                        if (depth == 0) return index
                    }
                }
            }
            error("AGSL adapter found an unterminated block")
        }
        fun blockBody(sourceText: String, marker: String, startIndex: Int = 0): String {
            val markerIndex = sourceText.indexOf(marker, startIndex)
            check(markerIndex >= 0) { "AGSL adapter cannot locate $marker" }
            val openingBrace = sourceText.indexOf('{', markerIndex)
            check(openingBrace >= 0) { "AGSL adapter cannot locate block for $marker" }
            return sourceText.substring(openingBrace + 1, closingBrace(sourceText, openingBrace))
        }
        fun replaceFunction(sourceText: String, signature: String, replacement: String): String {
            val functionStart = sourceText.indexOf(signature)
            check(functionStart >= 0) { "AGSL adapter cannot locate $signature" }
            val openingBrace = sourceText.indexOf('{', functionStart)
            check(openingBrace >= 0) { "AGSL adapter cannot locate body for $signature" }
            val functionEnd = closingBrace(sourceText, openingBrace)
            return sourceText.substring(0, functionStart) + replacement + sourceText.substring(functionEnd + 1)
        }
        val classicSignature = "float3 classicReferenceField(float2 uv, float rippleLight)"
        val classicBody = blockBody(sharedAgsl, classicSignature)
        val classicPrologueStart = classicBody.indexOf("  float strength = mainValue(0);")
        val classicMemberStart = classicBody.indexOf("  if (uEffect < 1.5) {")
        val classicTailStart = classicBody.indexOf("  float mixture = smooth01")
        check(classicPrologueStart >= 0 && classicMemberStart > classicPrologueStart && classicTailStart > classicMemberStart) {
            "AGSL adapter cannot locate the classic member structure"
        }
        val classicPrologue = classicBody.substring(classicPrologueStart, classicMemberStart)
        val classicTail = classicBody.substring(classicTailStart)
        fun specializedClassicField(shaderId: Int): String {
            val lowerBound = shaderId - .5
            val upperBound = shaderId + .5
            if (shaderId in 1..4) {
                val memberMarker = when (shaderId) {
                    1 -> "  if (uEffect < 1.5) {"
                    2 -> "  } else if (uEffect < 2.5) {"
                    3 -> "  } else if (uEffect < 3.5) {"
                    else -> "  } else if (uEffect < 4.5) {"
                }
                val memberBody = blockBody(classicBody, memberMarker)
                return """
$classicSignature {
$classicPrologue  if (uEffect < $lowerBound || uEffect >= $upperBound) {
    return sampleCanonicalPalette(baseCoordinate);
  }
$memberBody$classicTail
}""".trim()
            }
            val balanceMarker = "  } else {\n    float base = .08 + fluviSaturate(uPaletteSplit) * .84;"
            val balanceBody = blockBody(classicBody, balanceMarker)
            val balanceMemberStart = balanceBody.indexOf("    if (uEffect < 5.5) {")
            val balanceTailStart = balanceBody.indexOf("    if (strength <= 0.0)")
            check(balanceMemberStart >= 0 && balanceTailStart > balanceMemberStart) {
                "AGSL adapter cannot locate the balance member structure"
            }
            val balancePrologue = balanceBody.substring(0, balanceMemberStart)
            val balanceTail = balanceBody.substring(balanceTailStart)
            val memberBody = when (shaderId) {
                5 -> blockBody(balanceBody, "    if (uEffect < 5.5) {")
                6 -> blockBody(balanceBody, "    } else if (uEffect < 6.5) {")
                7 -> {
                    val counterMarker = "    } else if (uEffect < 6.5) {"
                    val counterStart = balanceBody.indexOf(counterMarker)
                    check(counterStart >= 0) { "AGSL adapter cannot locate the balance counterflow branch" }
                    val counterOpeningBrace = balanceBody.indexOf('{', counterStart)
                    val counterEnd = closingBrace(balanceBody, counterOpeningBrace)
                    val chargesOpeningBrace = balanceBody.indexOf('{', counterEnd + 1)
                    check(chargesOpeningBrace >= 0) { "AGSL adapter cannot locate the balance charges branch" }
                    balanceBody.substring(chargesOpeningBrace + 1, closingBrace(balanceBody, chargesOpeningBrace))
                }
                else -> error("Classic specialization requires IDs 1 through 7")
            }
            return """
$classicSignature {
$balancePrologue  if (uEffect < $lowerBound || uEffect >= $upperBound) {
    return sampleCanonicalPalette(baseCoordinate);
  }
$memberBody$balanceTail
}""".trim()
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
            var agslPrefix = sharedAgsl.substringBefore(mainSignature)
                .replace(canonicalCommonField, specializedCommon)
            if (shaderId in 1..7) {
                agslPrefix = replaceFunction(agslPrefix, classicSignature, specializedClassicField(shaderId))
            }
            check(agslPrefix.contains("uniform float uEffect;")) {
                "AGSL specialization lost the runtime effect selector for $effectId"
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

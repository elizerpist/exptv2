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
// shaderId. With uEffect made a compile-time constant SkSL can remove the
// sixteen unrelated effect branches while retaining the selected effect,
// Portal layers and canonical palette mathematics.
val keyguardHeaderAdapterVersion = "3"
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
        val destination = keyguardHeaderGeneratedAssets.get().asFile
        destination.mkdirs()
        keyguardHeaderEffects.forEach { (effectId, shaderId) ->
            val agsl = sharedAgsl.replace(
                "uniform float uEffect;",
                "const float uEffect = ${shaderId}.0;",
            )
            check(!agsl.contains("uniform float uEffect;")) {
                "AGSL specialization retained uEffect for $effectId"
            }
            val generatedHash = MessageDigest.getInstance("SHA-256")
                .digest(agsl.toByteArray())
                .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
            destination.resolve("fluvi_keyguard_header_material_$effectId.agsl").writeText(
                "// generated-from=shaders/dashboard_header_field.frag\n// source-sha256=$hash\n// effect-id=$effectId\n$agsl",
            )
            destination.resolve("fluvi_keyguard_header_material_$effectId.meta").writeText(
                "source-sha256=$hash\ngenerated-agsl-sha256=$generatedHash\nadapter-version=$keyguardHeaderAdapterVersion\nshader-abi-version=6\neffect-id=$effectId\neffect-shader-id=$shaderId\n",
            )
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

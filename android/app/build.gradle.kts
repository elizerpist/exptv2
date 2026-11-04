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
val generateKeyguardHeaderMaterial by tasks.registering {
    inputs.file(keyguardHeaderSource)
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
        val agsl = source
            .replace("#include <flutter/runtime_effect.glsl>\n", "")
            .replace("out vec4 fragColor;\n", "")
            .replace("void main() {", "half4 main(float2 _fluviFragCoord) {")
            .replace("FlutterFragCoord()", "_fluviFragCoord")
            .replace("fragColor = vec4(composed, saturate(uOpacity));", "float _fluviAlpha = saturate(uOpacity);\n  return half4(composed * _fluviAlpha, _fluviAlpha);")
            .replace(Regex("\\bvec2\\b"), "float2")
            .replace(Regex("\\bvec3\\b"), "float3")
            .replace(Regex("\\bvec4\\b"), "float4")
            .replace(Regex("\\bmat2\\b"), "float2x2")
        check(agsl.contains("half4 main(float2 _fluviFragCoord)"))
        check(!agsl.contains("FlutterFragCoord"))
        check(!agsl.contains("runtime_effect.glsl"))
        val destination = keyguardHeaderGeneratedAssets.get().asFile
        destination.mkdirs()
        destination.resolve("fluvi_keyguard_header_material.agsl").writeText(
            "// generated-from=shaders/dashboard_header_field.frag\n// source-sha256=$hash\n$agsl",
        )
        destination.resolve("fluvi_keyguard_header_material.meta").writeText(
            "source-sha256=$hash\nshader-abi-version=6\n",
        )
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
}

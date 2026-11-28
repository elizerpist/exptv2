plugins {
    id("com.android.application") version "9.3.3"
}

android {
    namespace = "com.fluvi.product"
    compileSdk { version = release(37) { minorApiLevel = 0 } }
    defaultConfig {
        applicationId = "com.fluvi.app"
        minSdk = 24
        targetSdk = 37
        versionCode = 8
        versionName = "0.1.6"
        ndk { abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64") }
    }
    buildTypes {
        create("profile") {
            matchingFallbacks += "release"
            manifestPlaceholders["fluviTraceByShell"] = (System.getenv("FLUVI_BUILD_PURPOSE") == "human_diagnostic").toString()
        }
    }
    packaging {
        jniLibs.useLegacyPackaging = false
    }
}

dependencies {
    val mode = requireNotNull(System.getenv("FLUVI_ANDROID_MODE"))
    implementation("com.fluvi.native:fluvi-native:1.0")
    implementation("com.fluvi.payload:flutter_${mode}:1.0")
}

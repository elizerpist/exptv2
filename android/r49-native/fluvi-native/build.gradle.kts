import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.fluvi.app"
    compileSdk = 36
    defaultConfig {
        minSdk = 24
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    sourceSets.getByName("main").apply {
        val source = projectDir.resolve("../../app/src/main")
        manifest.srcFile(source.resolve("AndroidManifest.xml"))
        java.srcDirs(source.resolve("kotlin"))
        res.srcDirs(source.resolve("res"))
        assets.srcDirs(source.resolve("assets"))
    }
}

kotlin.compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
val mode = requireNotNull(System.getenv("FLUVI_ANDROID_MODE"))

dependencies {
    implementation(project(":fluvi-core"))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    implementation("com.fluvi.payload:flutter_${mode}:1.0")
}

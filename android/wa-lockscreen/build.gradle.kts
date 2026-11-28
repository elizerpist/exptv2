import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.fluvi.wa"
    compileSdk = 36
    defaultConfig {
        minSdk = 24
        val source = providers.environmentVariable("FLUVI_BUILD_COMMIT").orNull
        resValue(
            "string", "fluvi_wa_source_commit",
            source?.takeIf { it.matches(Regex("[a-f0-9]{40}")) } ?: "UNOBSERVED",
        )
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin.compilerOptions.jvmTarget.set(JvmTarget.JVM_17)

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.14.2")
}

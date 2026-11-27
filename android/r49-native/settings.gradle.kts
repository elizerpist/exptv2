pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven(requireNotNull(System.getenv("FLUVI_PAYLOAD_REPO")))
        maven("https://storage.googleapis.com/download.flutter.io")
    }
}

plugins {
    id("com.android.library") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.devtools.ksp") version "2.2.20-2.0.4" apply false
}

rootProject.name = "Fluvi native libraries"
include(":fluvi-core", ":fluvi-native")
project(":fluvi-core").projectDir = file("../fluvi-core")

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
        maven(requireNotNull(System.getenv("FLUVI_NATIVE_REPO")))
        maven("https://storage.googleapis.com/download.flutter.io") {
            content { includeGroup("io.flutter") }
        }
    }
}

rootProject.name = "Fluvi product"
include(":app")

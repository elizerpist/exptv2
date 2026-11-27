import com.android.build.api.dsl.LibraryExtension

plugins { id("com.android.library") apply false }

// Publish the existing Kotlin/KSP artifacts with their transitive dependency
// metadata. The Fluvi product builds with a separate Gradle/JDK instance.
subprojects {
    group = "com.fluvi.native"
    version = "1.0"
    apply(plugin = "maven-publish")

    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            publishing.singleVariant("release")
        }
        afterEvaluate {
            extensions.configure<PublishingExtension> {
                publications.register<MavenPublication>("release") {
                    from(components["release"])
                }
                repositories.maven {
                    name = "fluviNative"
                    url = uri(requireNotNull(System.getenv("FLUVI_NATIVE_REPO")))
                }
            }
        }
    }
}

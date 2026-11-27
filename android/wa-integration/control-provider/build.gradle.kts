plugins { alias(libs.plugins.android.application) }

android {
    namespace = "com.fluvi.r49.control"
    compileSdk {
        version = release(37) { minorApiLevel = 0 }
    }
    defaultConfig {
        applicationId = "com.fluvi.r49.control"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "com.fluvi.r49.control.FrameTutorialTouch"
    }
}

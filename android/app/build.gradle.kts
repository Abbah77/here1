plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.here"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // --- MANDATORY FIX FOR NOTIFICATIONS ---
        isCoreLibraryDesugaringEnabled = true 
        // ---------------------------------------

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.here"
        
        // Desugaring requires minSdk 21 to avoid bugs on older devices
        minSdk = 21 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // --- THIS IS THE "TRANSLATOR" THE COMPILER IS ASKING FOR ---
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // -----------------------------------------------------------
}

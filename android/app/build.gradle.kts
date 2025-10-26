plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read the local.properties file to get the kotlin_version
val kotlin_version by extra("1.9.23") // A recent stable version

android {
    namespace = "com.example.smart_numerix"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // **FIXED**: Ensures both Java and Kotlin target the same JVM version (1.8).
    compileOptions {
        isCoreLibraryDesugaringEnabled = true // **ADDED**: Enables support for modern Java APIs.
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // **FIXED**: Aligns Kotlin's target with Java's.
    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.smart_numerix"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // **ADDED**: Required for desugaring.
        manifestPlaceholders["appAuthRedirectScheme"] = "com.googleusercontent.apps.167630521268-s1kiqae81t928go6pm2jlh002l1r994q"
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// **ADDED**: This whole block is necessary for your dependencies.
dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // **ADDED**: The desugaring library itself.
}
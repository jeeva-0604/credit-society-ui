import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystoreFile = rootProject.file("key.properties")
if (keystoreFile.exists()) {
    println("🔐 Loading signing config from key.properties")
    keystoreProperties.load(FileInputStream(keystoreFile))
} else {
    println("⚠️ key.properties file not found at: ${keystoreFile.absolutePath}")
}

android {
    ndkVersion = "29.0.13846066"
    namespace = "com.vtech.creditsociety"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.vtech.creditsociety"
        // UPDATED: Changed from flutter.minSdkVersion to 26 to fix the build error
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keystoreProperties["storeFile"]?.toString()
            val storePassword = keystoreProperties["storePassword"]?.toString()
            val keyAlias = keystoreProperties["keyAlias"]?.toString()
            val keyPassword = keystoreProperties["keyPassword"]?.toString()

            if (storeFilePath != null && storePassword != null && keyAlias != null && keyPassword != null) {
                val resolvedStoreFile = file(storeFilePath)
                println("✅ Using keystore at: ${resolvedStoreFile.absolutePath}")
                storeFile = resolvedStoreFile
                this.storePassword = storePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
            } else {
                println("❌ Missing one or more signing properties. Check key.properties.")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        // ADD THIS PART:
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
    // ADD THIS BLOCK TO FIX DUPLICATE CLASSES
    configurations.all {
        resolutionStrategy {
            // Force these to match to prevent version mismatches
            force("androidx.media3:media3-common:1.4.1")
            force("androidx.media3:media3-exoplayer:1.4.1")
            force("androidx.media3:media3-ui:1.4.1")
            force("androidx.media3:media3-session:1.4.1")
        }
        // FIX: Exclude this specific module because react-native-video already bundles it.
        // This prevents the "Duplicate class" error.
        exclude(group = "androidx.media3", module = "media3-exoplayer-rtsp")
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core:1.12.0")
    implementation(platform("org.jetbrains.kotlin:kotlin-bom:2.2.0"))
}

flutter {
    source = "../.."
}

tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions {
        jvmTarget = "17"
    }
}
tasks.withType<JavaCompile> {
    options.compilerArgs.add("-Xlint:-options")
}
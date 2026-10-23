import java.util.Properties
import java.util.Base64
import java.net.URI

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeys = Properties()
val releaseKeyFile = rootProject.file("key.properties")
if (releaseKeyFile.exists()) releaseKeyFile.inputStream().use { releaseKeys.load(it) }

gradle.taskGraph.whenReady {
    if (allTasks.any { it.project == project && it.name.contains("Release") }) {
        require(releaseKeyFile.exists() && listOf("storeFile", "storePassword", "keyAlias", "keyPassword").all { !releaseKeys.getProperty(it).isNullOrBlank() }) {
            "Configure android/key.properties with the production signing key before building release."
        }
        val defines = (project.findProperty("dart-defines") as? String).orEmpty().split(",")
            .filter { it.isNotBlank() }.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
        val endpoint = defines.firstOrNull { it.startsWith("API_BASE_URL=") }?.substringAfter("=")
        val api = endpoint?.let { URI(it) }
        require(api != null && api.scheme == "https" && !api.host.isNullOrBlank() && api.host !in listOf("localhost", "127.0.0.1", "::1") && api.path.trimEnd('/').endsWith("/api/v1")) {
            "Release requires --dart-define=API_BASE_URL=https://YOUR-BACKEND/api/v1."
        }
    }
}

android {
    namespace = "id.ac.annuur2.annuur_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "id.ac.annuur2.annuur_mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseKeyFile.exists()) {
                storeFile = rootProject.file(releaseKeys.getProperty("storeFile"))
                storePassword = releaseKeys.getProperty("storePassword")
                keyAlias = releaseKeys.getProperty("keyAlias")
                keyPassword = releaseKeys.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

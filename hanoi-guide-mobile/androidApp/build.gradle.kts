import java.net.URI
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.compose.compiler)
}

fun apiOrigin(value: String, requireHttps: Boolean): String {
    if (value.isEmpty()) return ""
    val origin = runCatching { URI(value) }.getOrNull()
    require(
        origin != null && origin.host != null && origin.userInfo == null &&
            origin.path.orEmpty() in listOf("", "/") && origin.query == null && origin.fragment == null &&
            (origin.scheme == "https" || (!requireHttps && origin.scheme == "http"))
    ) { "The Hanoi Guide API base URL must be a valid origin (scheme, host, optional port). Release requires HTTPS." }
    return value.trimEnd('/')
}

val debugApiOrigin = apiOrigin(
    providers.gradleProperty("HANOI_DEBUG_API_BASE_URL").orElse("http://10.0.2.2:8090").get(),
    requireHttps = false,
)
val releaseApiOrigin = apiOrigin(
    providers.gradleProperty("HANOI_RELEASE_API_BASE_URL").orElse("").get(),
    requireHttps = true,
)

android {
    namespace = "vn.hanoiguide.mobile"
    compileSdk = 36

    defaultConfig {
        applicationId = "vn.hanoiguide.mobile"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        buildConfig = true
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            buildConfigField("String", "API_ORIGIN", "\"$debugApiOrigin\"")
        }
        release {
            buildConfigField("String", "API_ORIGIN", "\"$releaseApiOrigin\"")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }
}

kotlin {
    compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
}

dependencies {
    implementation(project(":composeApp"))
    implementation(libs.androidx.activity.compose)
}

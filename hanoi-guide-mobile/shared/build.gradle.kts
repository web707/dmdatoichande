import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.kotlin.multiplatform)
    alias(libs.plugins.android.kmp.library)
    alias(libs.plugins.kotlin.serialization)
}

kotlin {
    android {
        namespace = "vn.hanoiguide.mobile.shared"
        compileSdk = 36
        minSdk = 24
        compilerOptions.jvmTarget.set(JvmTarget.JVM_17)
        withHostTest {}
    }
    iosArm64()
    iosSimulatorArm64()

    sourceSets {
        commonMain {
            dependencies {
                api(libs.coroutines.core)
                implementation(libs.ktor.core)
                implementation(libs.serialization.json)
            }
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
            implementation(libs.coroutines.test)
            implementation(libs.ktor.mock)
        }
        androidMain.dependencies { implementation(libs.ktor.android) }
        iosMain.dependencies { implementation(libs.ktor.darwin) }
    }
}

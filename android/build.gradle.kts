plugins {
    id("com.android.library")
    id("kotlin-android")
}

group = "com.afflicate.sdk"

android {
    namespace = "com.afflicate.sdk"
    compileSdk = 34

    defaultConfig {
        minSdk = 21
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("com.android.installreferrer:installreferrer:2.2")
}

package vn.hanoiguide.mobile.shared

import io.ktor.client.HttpClient
import io.ktor.client.engine.android.Android

internal actual fun createPlatformHttpClient(): HttpClient =
    HttpClient(Android) { configureDestinationClient() }

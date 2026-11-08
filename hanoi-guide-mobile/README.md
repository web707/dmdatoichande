# Hanoi Guide Mobile

This Kotlin Multiplatform project implements the destination catalog and detail migration slices. The Android launcher, shared Compose screens and cross-platform client build independently of Flutter, Node.js and the Web application. The backend owns the destination records and serves them from PostgreSQL.

## Android development on Windows

Install JDK 17 and Android SDK Platform 36, Build Tools 36.0.0 and Platform Tools. Set `JAVA_HOME` and `ANDROID_HOME` or configure the SDK through Android Studio. The Gradle Wrapper verifies the pinned distribution checksum.

```powershell
.\gradlew.bat :shared:testAndroidHostTest :androidApp:lintDebug :androidApp:assembleDebug
adb install -r androidApp/build/outputs/apk/debug/androidApp-debug.apk
adb shell am start -n vn.hanoiguide.mobile.debug/vn.hanoiguide.mobile.MainActivity
```

Start the backend on port 8090. The debug variant uses the Android emulator's host alias `http://10.0.2.2:8090`. On an attached physical device, forward the port and build with the loopback origin.

```powershell
adb reverse tcp:8090 tcp:8090
.\gradlew.bat :androidApp:assembleDebug "-PHANOI_DEBUG_API_BASE_URL=http://127.0.0.1:8090"
```

Debug cleartext is limited to the emulator host alias and loopback. Use HTTPS for a remote staging origin. The release variant requires an HTTPS origin at runtime. Supply your own API origin for distribution.

```powershell
.\gradlew.bat :androidApp:assembleRelease "-PHANOI_RELEASE_API_BASE_URL=https://api.example.org"
```

The release task produces an unsigned minified APK. Release signing belongs to the deployment pipeline. Android package IDs are `vn.hanoiguide.mobile` and `vn.hanoiguide.mobile.debug`, separate from the legacy Flutter app. An in-place upgrade will require a separate signing and bookmark migration decision.

## Modules

- `androidApp` owns Android packaging, the launch activity and variant-specific API origins.
- `composeApp` owns the shared Material 3 UI, lifecycle-aware StateFlow observation and iOS view controller.
- `shared` owns the Ktor client, destination catalog state, HTTP engine adapters and host-side tests. Its checked-in Kotlin DTOs mirror the generated destination contract in `hanoi-guide-contracts`.

The catalog loads up to 20 records per request. Search starts on submission. A new search cancels an in-flight request and subsequent pages keep the active search term. The list composes visible rows by stable IDs. The catalog keeps successfully loaded pages in memory across Android activity recreation. Opening a destination fetches its details on demand and returning restores the catalog search and scroll position. Maps, image loading, persistent cache, SSE, authentication, phrase bookmarks and VR360 are later parity slices.

## iOS target

The `:composeApp` framework targets arm64 devices and arm64 simulators. Build it on macOS with compatible Xcode and embed `HanoiGuide` in an iOS host. The shared `MainViewController(apiOrigin)` function takes the host's HTTPS API origin. Set `CADisableMinimumFrameDurationOnPhone` to true in the iOS host's Info.plist as required by Compose Multiplatform. The iOS framework and host integration require macOS/Xcode verification.

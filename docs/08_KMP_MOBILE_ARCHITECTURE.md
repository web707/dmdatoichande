# KMP mobile architecture

[hanoi-guide-mobile](../hanoi-guide-mobile) builds separately from Flutter and Next.js. Compose handles native presentation. Shared Kotlin owns the destination repository and network contract. Platform engines, lifecycle and URL configuration stay at the platform boundary. Release endpoints require explicit HTTPS configuration.

The new Android application ID allows co-installation. The original Flutter app ID is `vn.hanoiguide.hanoi_travel_guide`. It stores the Dart string list `phrase_favorites` as `flutter.phrase_favorites` in `FlutterSharedPreferences` on Android. The legacy plugin supports its current prefixed JSON encoding and older list encoding. The new app cannot read that sandbox. Test export/import or a same-ID and same-signature upgrade using representative prior data before any bookmark migration claim. Keep the old installation until then.

The destination slice uses in-memory presentation state. Select one persistent cache engine after schema and cross-platform build evaluation. Keep iOS targets distinct from a verified iOS artifact, which requires a macOS/Xcode run.

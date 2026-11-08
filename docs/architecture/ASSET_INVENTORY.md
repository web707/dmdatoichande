# Asset inventory

| Resource | Current location and measured size | Migration and acceptance |
| --- | --- | --- |
| Two fallback photographs and credits | [assets/images](../../assets/images), 3 files, 1,924,490 bytes. `widgets.dart` maps fallbacks by seed UUID. | Preserve credits and map IDs to the same images. Use sized, lazy image requests for lists; verify visual fallback. |
| Định Công | [assets/vr360](../../assets/vr360), 28 files, 19,854,513 bytes. Manifest, panoramas, scene links and EN/VI audio; packaged by [pubspec.yaml](../../pubspec.yaml). | Keep source authoritative and validate each scene/audio reference. Web fetches on route entry; choose Android packaging or verified predownload according to offline parity. |
| Hồ Gươm viewer | [backend/vr360](../../backend/vr360), HTML, CSS and JavaScript, plus pinned Pannellum npm dependency. | Continue using the existing delivery route and restrict embedding to approved origins. Verify cache behavior and unload on navigation. |
| Hồ Gươm public media | `.local/vr360/hoan-kiem/public`, 55 files, 56,317,730 bytes at inspection. | Keep manifest revalidatable and asset URLs immutable. Load only the current scene and measure decoded memory. |
| Hồ Gươm upstream archive | `.local/vr360/hoan-kiem/source`, 31 files, 124,237,800 bytes at inspection. Rebuilt with [import-hoan-kiem-vr360.py](../../scripts/import-hoan-kiem-vr360.py). | Retain archival input and attribution separately from public artifacts. Verify source paths are inaccessible via HTTP. |
| App icons | [Flutter Web icons](../../web/icons), Android mipmaps in [res](../../android/app/src/main/res). | Preserve branding and generate platform-appropriate sizes when release identities are chosen. |

Keep database media URLs and their source credits through the parallel migration. The two new clients can use the existing data without duplicating the tour assets in their initial downloads.

# Hanoi Guide

Ứng dụng hướng dẫn du lịch Hà Nội. Bản Next.js và Android Kotlin Multiplatform (KMP) hiện hỗ trợ danh sách, tìm kiếm và chi tiết điểm đến qua API Express v1. Hai ứng dụng dùng chung dữ liệu PostgreSQL với bản Flutter. [Ma trận tính năng](docs/migration/FEATURE_PARITY_MATRIX.md)

## Chạy toàn bộ hệ thống trên Windows

Máy cần Git Bash, PowerShell 7 (`pwsh` trên PATH), Node.js 24, JDK 17, Android SDK Platform 36 và Build Tools 36.0.0, Android Emulator cùng PostgreSQL 18 đã thiết lập cho dự án. Đặt `ANDROID_HOME` hoặc `ANDROID_SDK_ROOT` trỏ tới Android SDK. Nếu chưa có `backend/.env`, thực hiện phần thiết lập PostgreSQL bên dưới trước.

```bash
cd /d/App_HUBT
./dev.sh
```

| Thành phần | Địa chỉ hoặc thiết bị |
|---|---|
| Next.js | [http://127.0.0.1:1503/destinations](http://127.0.0.1:1503/destinations) |
| Backend Express | `http://127.0.0.1:8090` |
| PostgreSQL | `127.0.0.1:55432` |
| Android KMP | `emulator-5554`, gọi API qua `http://10.0.2.2:8090` |

Script tắt phiên đang chạy của AVD `Hanoi_VR360_API_34`, build APK debug rồi khởi động nguội máy ảo với `-no-snapshot`. Android bỏ qua snapshot khi mở và khi thoát. Dữ liệu ứng dụng trên máy ảo được giữ lại. Script tự cài và mở app sau khi Android khởi động xong.

Nếu máy dùng AVD khác, truyền đúng tên khi chạy. Xem danh sách AVD bằng `emulator -list-avds` nếu lệnh `emulator` có trên PATH.

```bash
HANOI_ANDROID_AVD=Medium_Phone_API_35 ./dev.sh
```

Giữ terminal mở trong lúc phát triển. Nhấn `Ctrl+C` để dừng Web, máy ảo và Backend do phiên này khởi chạy. API đã chạy sẵn và PostgreSQL tiếp tục hoạt động. Để khởi động lại, chạy `./dev.sh` sau khi phiên cũ đã thoát. Nếu cổng `1503`, `5554` hoặc `5555` bị chiếm, kiểm tra tiến trình đang dùng cổng. Log Web, Backend và emulator nằm trong `.local/dev/`.

Để chạy riêng từng phần, xem hướng dẫn của [Web Next.js](hanoi-guide-web/README.md), [Android KMP](hanoi-guide-mobile/README.md) và [Backend](docs/13_DEPLOYMENT_GUIDE.md).

## Chức năng của bản Flutter

- **Explore**: địa điểm, ảnh, lịch sử/văn hoá tiếng Anh, chi tiết và marker bản đồ.
- **Phrasebook**: nghĩa tiếng Anh, hướng dẫn phát âm gần đúng, TTS tiếng Việt nếu máy có giọng, bookmark trên thiết bị, thêm/sửa/xoá câu cá nhân sau đăng nhập.
- **Food**: tìm kiếm có/không dấu, nhóm quán theo món, địa chỉ và bản đồ.
- **Content studio**: đăng nhập Admin, CRUD ba nhóm nội dung, kiểm tra dữ liệu, preview ảnh/toạ độ, xác nhận xoá.
- **Đồng bộ**: PostgreSQL trigger → `NOTIFY` sau commit → Node `LISTEN` → SSE → Flutter tải snapshot. Có reconnect, tải lại khi trở về foreground và đối soát mỗi 20 giây.

## Thiết lập PostgreSQL lần đầu

Với workspace chưa có cơ sở dữ liệu dự án, mở PowerShell 7 và chạy:

```powershell
Set-Location D:\App_HUBT
.\scripts\setup-local.ps1
.\scripts\SETUP_BACKEND.ps1
npm.cmd --prefix backend run migrate
npm.cmd --prefix backend run seed
```

`setup-local.ps1` tạo cluster PostgreSQL riêng trong `.local\pgdata`, chỉ lắng nghe trên `127.0.0.1:55432`. Sau khi thiết lập xong, dùng `./dev.sh` để chạy hệ thống. Với workspace đã có dữ liệu, chạy trực tiếp `./dev.sh`.

Tài khoản Admin nằm trong **`.local\admin-credentials.txt`**. Mật khẩu được tạo ngẫu nhiên; không đưa `.local` hay `backend/.env` lên Git. Đăng ký trong UI luôn tạo tài khoản `traveler`, không cấp Admin.

Nếu cần chỉ định PostgreSQL đã cài ở nơi khác:

```powershell
.\scripts\setup-local.ps1 -PgBin 'C:\Program Files\PostgreSQL\18\bin'
```

## Chạy bản Flutter cũ

Khởi động API ở cổng 8090 nếu chưa chạy. Mở terminal Web Flutter:

```powershell
Set-Location D:\App_HUBT
.\scripts\run-web.ps1
```

Terminal Emulator/Mobile:

```powershell
Set-Location D:\App_HUBT
flutter emulators --launch Medium_Phone_API_35
flutter devices
.\scripts\run-mobile.ps1 -DeviceId emulator-5554
```

- Web: `http://localhost:8080`, API `http://localhost:8090`.
- Android Emulator: API `http://10.0.2.2:8090`.
- Đổi `DeviceId` theo `flutter devices` nếu có nhiều máy ảo.
- HTTP chỉ được phép trong Android **debug**, với các host local đã chỉ định. Bản release cần backend HTTPS.
- Với điện thoại thật, `10.0.2.2` không áp dụng; cần chủ động cấu hình bind host, firewall và IP LAN. Đây chưa phải cấu hình mặc định.

Có thể xem bản Web build tại chính cổng API:

```powershell
flutter build web --release --no-wasm-dry-run
```

Mở `http://localhost:8090/`. API phục vụ thư mục `build/web`. Router dùng URL hash nên reload trang con hoạt động mà không cần rewrite trên server.

## Lưu trữ trên ổ D

| Thành phần | Đường dẫn |
|---|---|
| Flutter SDK | `D:\flutter` |
| Android SDK | `D:\android-tools\sdk` |
| `PUB_CACHE` | `D:\android-tools\pub-cache` |
| `GRADLE_USER_HOME` | `D:\android-tools\gradle-home` |
| `ANDROID_AVD_HOME` | `D:\android-tools\avd` |
| PostgreSQL data | `D:\App_HUBT\.local\pgdata` |
| npm cache | `D:\android-tools\npm-cache` |

`set-env.ps1` đặt biến cho terminal hiện tại và user; mở lại các terminal/IDE khác để nhận biến mới. Script không tự di chuyển cache hay máy ảo cũ. Binaries PostgreSQL dùng bản hệ thống đã cài, còn dữ liệu dự án ở D.

## Tour VR360 trên Flutter

Tour Hồ Gươm mở từ **Explore → Hoan Kiem Lake → Explore in VR360** hoặc **More → VR360**. Chạy `python scripts/import-hoan-kiem-vr360.py` với Python có Pillow để tạo dữ liệu, rồi khởi động API. Ảnh và script gốc nằm trong `.local/vr360/hoan-kiem/source/`. API phục vụ manifest và media đã tối ưu từ thư mục `public/` cùng trình xem Pannellum. Nút **Open on Báo Nhân Dân** mở tour gốc.

Mở **More → VR360 → Start 360° tour**. Tour Đình Định Công Thượng và Đền thờ Tổ nghề Kim hoàn lấy 15 cảnh từ `pdc-vr360`. Có thể kéo ảnh để xoay, bấm mũi tên hoặc sơ đồ để chuyển cảnh, mở thông tin và nghe thuyết minh tiếng Anh hoặc tiếng Việt. Ảnh, nội dung và âm thanh được đóng gói với Flutter nên tour Android chạy được khi mất mạng. Bản Web tải các tài nguyên từ máy chủ phục vụ ứng dụng.

Để cập nhật từ dự án nguồn, chạy `node scripts/import-vr360.mjs D:\icss\pdc-vr360` bằng Node.js 24. Dự án nguồn cần có `sharp` và các ảnh/audio đã tối ưu trong `public/`. Script tạo lại dữ liệu và media của tour trong `assets/vr360/`.

## Kiến trúc và schema

```text
hanoi-guide-web/       Next.js destination catalog and details
hanoi-guide-mobile/    Android KMP destination catalog and details
hanoi-guide-contracts/ OpenAPI and generated TypeScript/Kotlin models
lib/app/          Theme, router, responsive shell
lib/core/         HTTP/SSE client, Riverpod store, model/search, shared widgets
lib/features/     Explore, Phrasebook, Food, map, account and CMS forms
backend/src/      Express API, authorization, validation, password/session handling
backend/migrations/  PostgreSQL schema and change triggers
backend/seed/     Content fixtures with source URLs
backend/test/     Real-database API and SSE tests
backend/e2e/      Chrome UI and optional Android sync tests
test/            Flutter unit/widget tests
scripts/         Local setup and launch commands
```

Các bảng nghiệp vụ gồm `places`, `phrases`, `foods_restaurants`, `events` và `emergency_contacts`. Các bảng kỹ thuật gồm `users`, `sessions` và `schema_migrations`.

- `phrases.owner_id IS NULL`: câu chung do Admin quản lý. Câu có `owner_id`: chỉ chủ tài khoản được đọc/ghi, kể cả Admin cũng không đọc câu riêng của người khác.
- `foods_restaurants`: một dòng = một món tại một địa chỉ quán. `food_key` nhóm cùng món; lưu tên/mô tả món sẽ cập nhật cả nhóm.
- UUID và timestamps do PostgreSQL quản lý; CHECK constraints cho toạ độ; index cho `owner_id`, `food_key`, session expiry.
- Phân quyền thực thi tại API; không dùng Supabase/RLS. SQL luôn parameterized, tên bảng/cột qua whitelist schema.
- Mật khẩu băm bằng scrypt + salt; session token ngẫu nhiên, database chỉ lưu hash. Token client chỉ ở RAM, cần đăng nhập lại khi reload ứng dụng. Session có hạn 7 ngày và được thu hồi khi logout thành công.
- SSE công khai chỉ gửi tên collection thay đổi, không chứa ID, nội dung cá nhân, mật khẩu hoặc token.

Next.js và KMP đọc `GET /api/v1/destinations` và `GET /api/v1/destinations/{id}`. Dùng `GET /api/ready` để kiểm tra kết nối của Backend tới PostgreSQL. [Danh mục API](docs/api/API_INVENTORY.md)

## Kiểm tra

Để kiểm tra Backend, Web, Android KMP và Flutter theo thứ tự, dùng `scripts/TEST_ALL.ps1` với bản sao PostgreSQL kiểm thử. [Hướng dẫn phục hồi bản sao](docs/10_MIGRATION_RUNBOOK.md) · [Kết quả xác thực](docs/16_FINAL_VERIFICATION.md)

### Kiểm tra riêng bản Flutter

Trỏ Backend và `DATABASE_URL` của terminal test vào cơ sở dữ liệu kiểm thử đã chạy migration trước khi chạy integration test có thao tác ghi.

```powershell
Set-Location backend
npm run build
npm run test:coverage
npm audit
npx playwright test
Set-Location ..
flutter analyze
flutter test --coverage
flutter build web --release --no-wasm-dry-run
flutter build apk --debug
```

Playwright cần Chrome và API đang chạy ở 8090 với Web đã build. Để kiểm tra CMS → Android thật trong Emulator (app đã mở ở màn hình Explore):

```powershell
Set-Location backend
$env:NATIVE_SYNC='1'
npx playwright test
Remove-Item Env:NATIVE_SYNC
```

Test này dùng ADB tới `emulator-5554`, thêm/sửa/xoá một câu thử duy nhất từ CMS và kiểm tra UI Android tự đổi. Ảnh và trace nằm trong `.local/`, không commit vì trace đăng nhập có thể chứa dữ liệu phiên test.

## Kịch bản demo thủ công trên Flutter

1. Mở Web và Mobile; đăng nhập Admin trên Web từ file credentials.
2. Vào Content studio → Phrases, thêm câu mới. Trên Mobile mở Phrasebook và tìm câu đó.
3. Sửa nghĩa tiếng Anh trên Web; Mobile tự cập nhật mà không refresh.
4. Xoá câu thử và kiểm tra Mobile biến mất.
5. Sửa toạ độ địa điểm; marker đang mở phải cập nhật.
6. Tắt mạng Mobile, sửa dữ liệu Web, bật lại mạng và chờ kết nối phục hồi; nội dung phải khớp snapshot mới.
7. Đăng nhập hai tài khoản traveller khác nhau: câu cá nhân của A không xuất hiện ở B.

## Seed, giấy phép và giới hạn của bản Flutter

Seed gồm Hồ Hoàn Kiếm, Văn Miếu, Phở Gia Truyền 49 Bát Đàn, Bún Chả Đắc Kim 1 Hàng Mành và 12 câu giao tiếp. Nguồn nội dung nằm trong bản ghi; ảnh và toạ độ ghi ở `assets/images/ATTRIBUTION.md`. Toạ độ di tích là điểm đại diện khu tham quan; địa chỉ quán đã đối chiếu Michelin và OpenStreetMap. Chưa cung cấp định tuyến tới cửa vào.

- Bookmark lưu theo thiết bị/trình duyệt, không đồng bộ tài khoản.
- Không queue ghi khi offline; lỗi được hiển thị, người dùng thử lưu lại. Trong cùng phiên, UI giữ snapshot cuối; chưa có cache offline toàn bộ nội dung qua lần khởi động.
- TTS phụ thuộc giọng `vi-VN` trên thiết bị; phiên âm chữ là gần đúng, không phải IPA chuẩn. Không tự tải giọng hoặc dùng dịch vụ TTS trả phí.
- Bản đồ cần Internet, attribution luôn hiển thị; không tải hàng loạt/offline tile. Có tuân thủ caching mặc định của flutter_map và browser.
- Chưa có upload ảnh; Admin nhập URL HTTPS và nguồn/giấy phép. Hai ảnh seed có bản đóng gói dự phòng.
- Không có email verification/reset password, thanh toán, GPS hay chỉ đường. Không dùng prototype local này như cấu hình production.
- Hai Admin sửa cùng nội dung theo cơ chế lần ghi cuối thắng; chưa có lịch sử phiên bản/khôi phục trong UI.
- Flutter Web build JavaScript/CanvasKit. `flutter_tts` hiện có cảnh báo kiểm tra tương thích WASM; không bật `--wasm` cho bản này.

Để dừng database riêng: dùng `pg_ctl -D D:\App_HUBT\.local\pgdata stop -m fast`. Không xoá `.local/pgdata` để “reset” nếu cần giữ dữ liệu; backup bằng `pg_dump` trước các thay đổi phá huỷ. Migrations có bảng theo dõi và chạy trong transaction.

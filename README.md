# Hanoi Guide — Flutter + TypeScript + PostgreSQL

Prototype hướng dẫn du lịch Hà Nội cho khách nước ngoài. Một codebase Flutter chạy trên Android và Web; API Node.js/TypeScript và PostgreSQL local là nguồn dữ liệu chung.

## Chức năng

- **Explore**: địa điểm, ảnh, lịch sử/văn hoá tiếng Anh, chi tiết và marker bản đồ.
- **Phrasebook**: nghĩa tiếng Anh, hướng dẫn phát âm gần đúng, TTS tiếng Việt nếu máy có giọng, bookmark trên thiết bị, thêm/sửa/xoá câu cá nhân sau đăng nhập.
- **Food**: tìm kiếm có/không dấu, nhóm quán theo món, địa chỉ và bản đồ.
- **Content studio**: đăng nhập Admin, CRUD ba nhóm nội dung, kiểm tra dữ liệu, preview ảnh/toạ độ, xác nhận xoá.
- **Đồng bộ**: PostgreSQL trigger → `NOTIFY` sau commit → Node `LISTEN` → SSE → Flutter tải snapshot. Có reconnect, tải lại khi trở về foreground và đối soát mỗi 20 giây.

## Khởi động nhanh trên máy hiện tại

Source: `D:\App_HUBT\hanoi_travel_guide`. Dùng PowerShell 7, Node.js 24, Flutter stable và PostgreSQL 18 đã cài.

```powershell
Set-Location D:\App_HUBT\hanoi_travel_guide
.\scripts\set-env.ps1
.\scripts\setup-local.ps1
Set-Location backend
npm ci --cache D:\android-tools\npm-cache
npm run migrate
npm run seed
npm start
```

Giữ terminal API chạy. `setup-local.ps1` tạo cluster PostgreSQL riêng ở `.local\pgdata`, cổng **55432**, chỉ bind `127.0.0.1`. Không sửa database/service PostgreSQL có sẵn. Script tái chạy được; seed không ghi đè bản ghi đã tồn tại.

Tài khoản Admin nằm trong **`.local\admin-credentials.txt`**. Mật khẩu được tạo ngẫu nhiên; không đưa `.local` hay `backend/.env` lên Git. Đăng ký trong UI luôn tạo tài khoản `traveler`, không cấp Admin.

Nếu cần chỉ định PostgreSQL đã cài ở nơi khác:

```powershell
.\scripts\setup-local.ps1 -PgBin 'C:\Program Files\PostgreSQL\18\bin'
```

## Chạy Web và Mobile song song

Terminal Web:

```powershell
Set-Location D:\App_HUBT\hanoi_travel_guide
.\scripts\run-web.ps1
```

Terminal Emulator/Mobile:

```powershell
Set-Location D:\App_HUBT\hanoi_travel_guide
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
| PostgreSQL data | `D:\App_HUBT\hanoi_travel_guide\.local\pgdata` |
| npm cache | `D:\android-tools\npm-cache` |

`set-env.ps1` đặt biến cho terminal hiện tại và user; mở lại các terminal/IDE khác để nhận biến mới. Script không tự di chuyển cache hay máy ảo cũ. Binaries PostgreSQL dùng bản hệ thống đã cài, còn dữ liệu dự án ở D.

## Tour VR360

Tour Hồ Gươm mở từ **Explore → Hoan Kiem Lake → Explore in VR360** hoặc **More → VR360**. Chạy `python scripts/import-hoan-kiem-vr360.py` với Python có Pillow để tạo dữ liệu, rồi khởi động API. Ảnh và script gốc nằm trong `.local/vr360/hoan-kiem/source/`. API phục vụ manifest và media đã tối ưu từ thư mục `public/` cùng trình xem Pannellum. Nút **Open on Báo Nhân Dân** mở tour gốc.

Mở **More → VR360 → Start 360° tour**. Tour Đình Định Công Thượng và Đền thờ Tổ nghề Kim hoàn lấy 15 cảnh từ `pdc-vr360`. Có thể kéo ảnh để xoay, bấm mũi tên hoặc sơ đồ để chuyển cảnh, mở thông tin và nghe thuyết minh tiếng Anh hoặc tiếng Việt. Ảnh, nội dung và âm thanh được đóng gói với Flutter nên tour Android chạy được khi mất mạng. Bản Web tải các tài nguyên từ máy chủ phục vụ ứng dụng.

Để cập nhật từ dự án nguồn, chạy `node scripts/import-vr360.mjs D:\icss\pdc-vr360` bằng Node.js 24. Dự án nguồn cần có `sharp` và các ảnh/audio đã tối ưu trong `public/`. Script tạo lại dữ liệu và media của tour trong `assets/vr360/`.

## Kiến trúc và schema

```text
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

Ba bảng nghiệp vụ: `places`, `phrases`, `foods_restaurants`. Các bảng kỹ thuật: `users`, `sessions`, `schema_migrations`.

- `phrases.owner_id IS NULL`: câu chung do Admin quản lý. Câu có `owner_id`: chỉ chủ tài khoản được đọc/ghi, kể cả Admin cũng không đọc câu riêng của người khác.
- `foods_restaurants`: một dòng = một món tại một địa chỉ quán. `food_key` nhóm cùng món; lưu tên/mô tả món sẽ cập nhật cả nhóm.
- UUID và timestamps do PostgreSQL quản lý; CHECK constraints cho toạ độ; index cho `owner_id`, `food_key`, session expiry.
- Phân quyền thực thi tại API; không dùng Supabase/RLS. SQL luôn parameterized, tên bảng/cột qua whitelist schema.
- Mật khẩu băm bằng scrypt + salt; session token ngẫu nhiên, database chỉ lưu hash. Token client chỉ ở RAM, cần đăng nhập lại khi reload ứng dụng. Session có hạn 7 ngày và được thu hồi khi logout thành công.
- SSE công khai chỉ gửi tên collection thay đổi, không chứa ID, nội dung cá nhân, mật khẩu hoặc token.

API: `GET /api/health`, `GET /api/events`, `POST /api/auth/register|login|logout`, `GET /api/auth/me`, `GET|POST /api/{collection}`, `PUT|DELETE /api/{collection}/{id}`. PUT nhận đầy đủ các trường nội dung. Bearer token dùng cho thao tác đăng nhập và ghi dữ liệu. CORS mặc định chỉ chấp nhận các origin localhost được liệt kê trong `.env`.

## Kiểm tra

Backend phải được migrate trước khi chạy integration tests. Test tạo fixture riêng bằng UUID và chỉ dọn dữ liệu của chính nó.

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

## Kịch bản demo thủ công

1. Mở Web và Mobile; đăng nhập Admin trên Web từ file credentials.
2. Vào Content studio → Phrases, thêm câu mới. Trên Mobile mở Phrasebook và tìm câu đó.
3. Sửa nghĩa tiếng Anh trên Web; Mobile tự cập nhật mà không refresh.
4. Xoá câu thử và kiểm tra Mobile biến mất.
5. Sửa toạ độ địa điểm; marker đang mở phải cập nhật.
6. Tắt mạng Mobile, sửa dữ liệu Web, bật lại mạng và chờ kết nối phục hồi; nội dung phải khớp snapshot mới.
7. Đăng nhập hai tài khoản traveller khác nhau: câu cá nhân của A không xuất hiện ở B.

## Seed, giấy phép và giới hạn MVP

Seed gồm Hồ Hoàn Kiếm, Văn Miếu, Phở Gia Truyền 49 Bát Đàn, Bún Chả Đắc Kim 1 Hàng Mành và 12 câu giao tiếp. Nguồn nội dung nằm trong bản ghi; ảnh và toạ độ ghi ở `assets/images/ATTRIBUTION.md`. Toạ độ di tích là điểm đại diện khu tham quan; địa chỉ quán đã đối chiếu Michelin và OpenStreetMap. Chưa cung cấp định tuyến tới cửa vào.

- Bookmark lưu theo thiết bị/trình duyệt, không đồng bộ tài khoản.
- Không queue ghi khi offline; lỗi được hiển thị, người dùng thử lưu lại. Trong cùng phiên, UI giữ snapshot cuối; chưa có cache offline toàn bộ nội dung qua lần khởi động.
- TTS phụ thuộc giọng `vi-VN` trên thiết bị; phiên âm chữ là gần đúng, không phải IPA chuẩn. Không tự tải giọng hoặc dùng dịch vụ TTS trả phí.
- Bản đồ cần Internet, attribution luôn hiển thị; không tải hàng loạt/offline tile. Có tuân thủ caching mặc định của flutter_map và browser.
- Chưa có upload ảnh; Admin nhập URL HTTPS và nguồn/giấy phép. Hai ảnh seed có bản đóng gói dự phòng.
- Không có email verification/reset password, thanh toán, GPS hay chỉ đường. Không dùng prototype local này như cấu hình production.
- Hai Admin sửa cùng nội dung theo cơ chế lần ghi cuối thắng; chưa có lịch sử phiên bản/khôi phục trong UI.
- Flutter Web build JavaScript/CanvasKit. `flutter_tts` hiện có cảnh báo kiểm tra tương thích WASM; không bật `--wasm` cho bản này.

Để dừng database riêng: dùng `pg_ctl -D D:\App_HUBT\hanoi_travel_guide\.local\pgdata stop -m fast`. Không xoá `.local/pgdata` để “reset” nếu cần giữ dữ liệu; backup bằng `pg_dump` trước các thay đổi phá huỷ. Migrations có bảng theo dõi và chạy trong transaction.

# VietNav — Build & Archive Guide

## Mở dự án trong Xcode

Xcode project được sinh từ `project.yml` bằng XcodeGen (không dùng `xcodebuild -create-xcode-project`, lệnh đó không tồn tại trong Xcode):

```bash
brew install xcodegen
xcodegen generate --spec project.yml
open VietNav.xcodeproj
```

Yêu cầu: macOS với Xcode 16 trở lên, iOS 17 trở lên. Các file Swift nằm trong `VietNav/`; bundle ID mặc định là `com.vietnav.app`.

## Dữ liệu bản đồ ngoại tuyến

Các workflow tải 7 file từ [VietHUD/speedmap](https://github.com/911273/VietHUD/tree/main/speedmap) vào `VietNav/Resources/speedmap/` trước khi tạo project:

- `cameras.bin`, `signs.bin`, `tiles.bin`, `index.bin`, `metadata.bin`, `names.bin`, `seg_names.bin`

Khi thêm file thủ công trong Xcode, hãy đảm bảo chúng được thêm vào target **VietNav** như resources. Không commit các file bản đồ lớn vào Git.

## Signing & capability

- Để chạy trên thiết bị hoặc xuất IPA có ký, chọn Apple Developer Team trong **Signing & Capabilities**.
- App cần quyền vị trí nền; `Info.plist` đã khai báo mô tả quyền và background modes (`location`, `audio`).
- Bundle ID trong provisioning profile phải là `com.vietnav.app`.

## Chạy thử

Chọn iPhone (iOS 17+) trong Xcode và nhấn **Run** (⌘R). GPS phù hợp hơn khi chạy trên thiết bị thật.

## Xuất IPA qua GitHub Actions

- **Unsigned IPA:** chạy workflow **Build Unsigned iOS IPA (No Apple Account)**. IPA này chỉ đóng gói app chưa ký, cần ký lại bằng AltStore/Sideloadly hoặc công cụ tương tự trước khi cài.
- **IPA đã ký Ad Hoc:** chạy workflow **Build iOS IPA (VietNav)**. Cần thiết lập repository secrets như trong `GITHUB_IPA_GUIDE.md`.

Cả hai workflow đều tạo Xcode project qua XcodeGen và kiểm tra lỗi tải dữ liệu thay vì tiếp tục với file tải hỏng.

## Cấu hình AI (ckey.vn)

Mở app → **Cài đặt** → **Triển khai AI** và nhập base URL, model, API key. API key được lưu trong Keychain.

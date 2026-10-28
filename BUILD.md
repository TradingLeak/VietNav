# VietNav — Build & Archive Guide

## 1. Mở dự án
- Mở Xcode, chọn `Open`, vào thư mục `VietNav`, chọn `VietNav.xcodeproj` (hoặc tạo workspace nếu bạn muốn).
- Nếu chưa có `.xcodeproj`, tạo mới: Xcode → File → New → Project → App → SwiftUI → Interface: SwiftUI → Life Cycle: SwiftUI App → Language: Swift. Sao chép các file Swift trong thư mục `VietNav/` vào dự án.

## 2. Thêm dữ liệu bản đồ ngoại tuyến
Tải 7 file từ [VietHUD/speedmap](https://github.com/911273/VietHUD/tree/main/speedmap):
- `cameras.bin`, `signs.bin`, `tiles.bin`, `index.bin`, `metadata.bin`, `names.bin`, `seg_names.bin`

Drag & drop toàn bộ vào Xcode vào folder `Resources/speedmap`:
- Tích **Copy items if needed**
- Tích **Add to target: VietNav**

> Lưu ý: `tiles.bin` rất lớn (~235 MB). Nếu dung lượng quá lớn, bạn có thể tách thành các vùng miền và tải khi cần.

## 3. Cấu hình ký&capability
- Signing & Capabilities →チーム chọn Apple Developer team.
- Thêm Capability: **Background Modes** → tick `Location updates` và `Audio`.
- Info.plist đã có các chuỗiuso Standort (`NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`).

## 4. Chạy thử
- Chọn thiết bị thật (iPhone) vì bản đồ ngoài tuyến cần GPS.
- Nhấn **Run** (⌘R).

## 5. Xuất IPA (sideload / TestFlight)
1. Product → Archive
2. Chọn archive vừa tạo → Distribute App
3. Chọn `Ad Hoc` (sideload) hoặc `App Store` (TestFlight/App Store)
4. Làm theo hướng dẫn ký certificate, export IPA

## 6. Cấu hình AI (ckey.vn)
Mở app → Cài đặt → Triển khai AI:
- Base URL: `https://ckey.vn`
- Model: tên model custom của bạn
- API Key: lấy từ ckey.vn (lưu trong Keychain, không hiển thị rõ)

## 7. Cấu trúc thư mục
```
VietNav/
├─ VietNavApp.swift
├─ Info.plist
├─ Package.swift
├─ Views/ (RootView, MapHomeView, NavigationDashboardView, SettingsView, ...)
├─ ViewModels/ (AppState.swift)
├─ Services/ (LocationService, AIRoutingService, SpeedmapParser, OSMMapService, WarningService)
├─ Models/ (mã nguồn gộp trong AppState.swift)
├─ Components/ (NeumorphicButton, PrimaryButton, ...)
└─ Resources/speedmap/ (*.bin)
```

## 8. Yêu cầu hệ thống
- Xcode 16+ (Swift 6, SwiftUI)
- iOS 17+
- Apple Developer account (để ký & xuất IPA)
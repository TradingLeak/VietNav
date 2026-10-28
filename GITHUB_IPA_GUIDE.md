# Hướng dẫn đóng gói IPA qua GitHub (không cần Mac)

## 0. Điều kiện tiên quyết
- **Tài khoản Apple Developer** (miễn phí hoặc trả phí $99/năm) — bắt buộc để ký ứng dụng iOS.
- **Repository GitHub** (nên để Public để có GitHub Actions macOS runner miễn phí).
- **Chứng chỉ ký & Provisioning Profile** (xem bước 2).
- **7 file .bin** đã được workflow tải tự động từ VietHUD/speedmap (không cần commit file lớn).

## 1. Tạo repository trên GitHub
```bash
cd "C:\Users\Admin\Documents\Default Project\VietNav"
git init
git add .
git commit -m "Initial VietNav project"
git branch -M main
git remote add origin https://github.com/<username>/VietNav.git
git push -u origin main
```

## 2. Chuẩn bị chứng chỉ ký (Signing) — làm trên Windows/mac/Linux bằng openssl
### 2.1 Tạo CSR (Certificate Signing Request)
```bash
openssl genrsa -out ios.key 2048
openssl req -new -key ios.key -out ios.csr -subj "/emailAddress=you@email.com, CN=Your Name, C=VN"
```
### 2.2 Tải CSR lên Apple Developer
- Vào https://developer.apple.com/account/resources/certificates/list
- Nhấn "+" → chọn **Apple Distribution** (hoặc iOS Distribution) → Upload `ios.csr` → Download `.cer`.
### 2.3 Chuyển .cer → .p12
```bash
openssl x509 -in distribution.cer -inform DER -out distribution.pem -outform PEM
openssl pkcs12 -export -out certificate.p12 -inkey ios.key -in distribution.pem -password pass:YOUR_PASSWORD
```
### 2.4 Mã hóa Base64 cho GitHub Secret
```bash
# Linux/macOS
base64 -i certificate.p12 | tr -d '\n' > cert.b64
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.p12")) | Out-File cert.b64
```
### 2.5 Tạo Provisioning Profile
- Apple Developer → Profiles → "+" → **Ad Hoc** (hoặc App Store) → chọn App ID `com.vietnav.app` → chọn chứng chỉ vừa tạo → chọn thiết bị → Download `.mobileprovision`.
- Mã hóa Base64 tương tự:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("profile.mobileprovision")) | Out-File profile.b64
```

## 3. Thêm GitHub Secrets
Vào Repository → **Settings → Secrets and variables → Actions → New repository secret**, thêm:

| Secret name | Giá trị |
|---|---|
| `CERTIFICATE_BASE64` | nội dung `cert.b64` |
| `CERTIFICATE_PASSWORD` | mật khẩu .p12 (ví dụ `YOUR_PASSWORD`) |
| `PROVISIONING_PROFILE_BASE64` | nội dung `profile.b64` |
| `PROFILE_NAME` | tên provisioning profile (ví dụ `VietNav AdHoc`) |

## 4. Kích hoạt build
- Mỗi lần `git push` lên `main`, workflow `.github/workflows/build-ios.yml` tự chạy.
- Hoặc vào tab **Actions → Build iOS IPA (VietNav) → Run workflow** để build thủ công.

## 5. Tải IPA
- Sau khi build xong, vào **Actions → run → Artifacts → VietNav-ipa** → tải file `.ipa` về.
- File `.ipa` có thể sideload lên iPhone bằng:
  - **AltStore / Sideloadly** (Windows/mac) — miễn phí, cần Apple ID.
  - **TrollStore** (iOS 14-17) — không cần ký lại.
  - **TestFlight** (nếu chọn App Store distribution).

## 6. Nếu chưa có Apple Developer (miễn phí)
- Dùng **AltStore** + **AltServer** trên Windows để ký & cài trực tiếp từ file `.ipa` (chứng chỉ miễn phí hết hạn sau 7 ngày, cần refresh).
- Hoặc thuê **Mac ảo** (MacStadium, AWS EC2 Mac, Scaleway) để build & ký trực tiếp.

## 7. Lưu ý về dung lượng
- File `tiles.bin` ~235 MB, `seg_names.bin` ~33 MB. Workflow tải tự động từ VietHUD nên bạn **không cần commit** các file này vào repo. Nếu muốn offline hoàn toàn, dùng Git LFS:
```bash
git lfs track "*.bin"
git add .gitattributes
```

## 8. Kiểm tra build locally (nếu sau này có Mac)
```bash
xcodebuild -project VietNav.xcodeproj -scheme VietNav -configuration Release -destination 'generic/platform=iOS' archive
```

## Troubleshooting
- **Lỗi "No signing certificate"**: kiểm tra secret `CERTIFICATE_BASE64` và password.
- **Lỗi "Provisioning profile doesn't match"**: đảm bảo Bundle ID `com.vietnav.app` trùng với App ID trong profile.
- **Lỗi "Missing .xcodeproj"**: workflow sẽ tự tạo bằng `xcodebuild -create-xcode-project`, nhưng tốt nhất nên tạo project bằng Xcode trước (nếu có Mac) rồi commit `.xcodeproj`.
- **Build timeout**: tăng timeout trong workflow (mặc định 6h) hoặc tách bước tải data.

---
**Tóm tắt:** Bạn chỉ cần push code lên GitHub → Actions tự build trên macOS runner → tải `.ipa` từ Artifacts. Không cần máy Mac cá nhân.
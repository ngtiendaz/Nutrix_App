# Hướng Dẫn Cài Đặt Chương Trình Nutrix

Tài liệu này hướng dẫn chi tiết các bước thiết lập và cài đặt dự án Nutrix trên máy tính cá nhân (macOS) để bạn có thể biên dịch, chạy và phát triển ứng dụng.

## 1. Yêu cầu hệ thống (Prerequisites)

- **Hệ điều hành:** macOS (phiên bản mới nhất tương thích với Xcode).
- **Công cụ phát triển:** [Xcode](https://developer.apple.com/xcode/) (Phiên bản mới nhất trên Mac App Store, đề xuất Xcode 15 trở lên).
- **Swift:** Hỗ trợ Swift 5.9 trở lên.
- **Git:** Để clone mã nguồn (Thường đã được tích hợp sẵn trên macOS hoặc cài đặt qua Xcode Command Line Tools).

## 2. Lấy mã nguồn (Clone Repository)

Mở Terminal và chạy lệnh sau để tải mã nguồn dự án về máy:

```bash
git clone <đường-dẫn-git-của-dự-án>
cd Nutrix
```

## 3. Cấu hình các khóa API (API Keys)

Ứng dụng sử dụng một số dịch vụ bên ngoài. Bạn cần phải cung cấp các khóa API để ứng dụng có thể hoạt động đúng.

1. Tìm file `Nutrix/Config.xcconfig` trong thư mục dự án.
2. Mở file và điền các khóa API tương ứng vào các biến sau:

```xcconfig
APP_ID_EDAMAM= <Nhập App ID của Edamam vào đây>
APP_KEY_EDAMAM= <Nhập App Key của Edamam vào đây>
API_KEY_VISION= <Nhập API Key của Google Vision vào đây>
API_KEY_GEMINI= <Nhập API Key của Gemini vào đây>
API_KEY_GEMINI_BACKUP= <Nhập API Key backup của Gemini vào đây>
```

> **Lưu ý quan trọng:** KHÔNG BAO GIỜ commit file `Config.xcconfig` chứa các key thật lên public repository để tránh lộ thông tin bảo mật.

## 4. Cấu hình Firebase

Dự án sử dụng Firebase cho việc xác thực (Authentication) và lưu trữ dữ liệu (Firestore).

1. Bạn cần một dự án Firebase trên [Firebase Console](https://console.firebase.google.com/).
2. Tạo ứng dụng iOS trong Firebase Console với Bundle ID khớp với dự án Nutrix (ví dụ: `com.nutrix.app` - vui lòng kiểm tra Bundle Identifier trong Xcode).
3. Tải file `GoogleService-Info.plist` từ Firebase Console.
4. Đưa file `GoogleService-Info.plist` vừa tải vào thư mục `Nutrix/` (ghi đè lên file hiện tại nếu có). Đảm bảo file này được thêm (Target Membership) vào ứng dụng Nutrix trong Xcode.

## 5. Cài đặt thư viện phụ thuộc (Dependencies)

Dự án này sử dụng **Swift Package Manager (SPM)** được tích hợp sẵn trong Xcode (hoặc có thể sử dụng CocoaPods nếu có file `Podfile`).

Nếu dự án dùng Swift Package Manager:
1. Mở file `Nutrix.xcodeproj` bằng Xcode.
2. Xcode sẽ tự động bắt đầu tải xuống (resolve) các package phụ thuộc (như `FirebaseFirestoreSwift`, vv.). Bạn có thể theo dõi quá trình này ở thanh tiến trình phía trên cùng của Xcode.

## 6. Mở và biên dịch (Build & Run)

1. Mở file `Nutrix.xcodeproj` (nếu bạn chưa mở ở bước trước).
2. Chọn máy ảo (Simulator) hoặc thiết bị thật của bạn ở góc trên bên trái Xcode.
3. Nhấn tổ hợp phím `Cmd + B` để kiểm tra việc biên dịch ứng dụng (`lỗi biên dịch` - bắt buộc như trong quy tắc dự án).
4. Nhấn nút **Play** (hoặc tổ hợp phím `Cmd + R`) để biên dịch và chạy ứng dụng.

## 7. Các quy tắc quan trọng khi làm việc

Hãy chắc chắn rằng bạn đã đọc và tuân thủ các quy tắc trong file `rule.md`:
- Sử dụng kiến trúc **MVVM** với lớp Service chuyên dụng.
- View chỉ chứa UI, mọi logic nghiệp vụ (business logic) đặt trong **ViewModel**.
- Tuân thủ Hệ thống thiết kế (Design System) qua `Color.App` và `.font(.App...)`.
- Tất cả các chức năng mới phải được kiểm tra (Text Analysis/Compile Checks) trước khi thực hiện commit mã nguồn mới.

---
**Chúc bạn phát triển dự án Nutrix thành công!**

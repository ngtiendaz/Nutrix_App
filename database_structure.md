# Cấu trúc Cơ sở dữ liệu Cloud Firestore - Dự án Nutrix

Tài liệu này mô tả chi tiết sơ đồ (schema) cơ sở dữ liệu Cloud Firestore hiện tại của ứng dụng di động Nutrix để đồng bộ hóa cấu trúc dữ liệu cho trang Web Admin, phục vụ cho việc thống kê, báo cáo và quản lý dữ liệu chính xác.

---

## 1. Root Collection: `users`
Quản lý thông tin tài khoản người dùng và các chỉ số cơ thể cơ bản.
* **Đường dẫn**: `users/{userId}`
* **Document ID**: `userId` (UID được cung cấp từ Firebase Authentication)

### Các trường dữ liệu (Fields):
| Tên trường (Field) | Kiểu dữ liệu (Type) | Mô tả |
| :--- | :--- | :--- |
| `userId` | `String` | ID duy nhất của người dùng. |
| `email` | `String` | Email đăng ký của người dùng. |
| `name` | `String` | Họ và tên đầy đủ của người dùng. |
| `age` | `Int` | Tuổi hiện tại (Optional). |
| `gender` | `String` | Giới tính (ví dụ: `"Nam"`, `"Nữ"`) (Optional). |
| `height` | `Double` | Chiều cao hiện tại (đơn vị: cm) (Optional). |
| `weight` | `Double` | Cân nặng hiện tại (đơn vị: kg) (Optional). |
| `activityLevel` | `String` | Cường độ vận động (ví dụ: `"Trầm lặng"`, `"Nhẹ nhàng"`, `"Năng động"`) (Optional). |
| `goal` | `String` | Mục tiêu cân nặng (ví dụ: `"Giảm cân"`, `"Tăng cơ"`, `"Duy trì"`) (Optional). |
| `healthNote` | `String` | Ghi chú sức khỏe/bệnh lý cá nhân (Optional). |
| `createdAt` | `Timestamp` | Thời gian tạo tài khoản. |

---

## 2. Subcollection: `daily_summaries` (con của `users/{userId}`)
Lưu trữ thông tin tổng hợp lượng dinh dưỡng nạp vào, lượng calo tiêu hao và snapshot mục tiêu hàng ngày của người dùng. Dùng trực tiếp cho các biểu đồ thống kê theo Ngày/Tuần/Tháng/Năm.
* **Đường dẫn**: `users/{userId}/daily_summaries/{dateKey}`
* **Document ID**: `dateKey` có định dạng `"yyyy-MM-dd"` (Ví dụ: `"2026-05-26"`)

### Các trường dữ liệu (Fields):
| Tên trường (Field) | Kiểu dữ liệu (Type) | Mô tả |
| :--- | :--- | :--- |
| `userId` | `String` | ID người dùng sở hữu bản ghi. |
| `dateKey` | `String` | Chuỗi định dạng ngày `"yyyy-MM-dd"`. |
| `intakeCalories` | `Double` | Tổng Calo thực tế nạp vào từ các bữa ăn trong ngày. |
| `intakeProtein` | `Double` | Tổng Protein thực tế nạp vào trong ngày (g). |
| `intakeCarbs` | `Double` | Tổng Carbohydrate thực tế nạp vào trong ngày (g). |
| `intakeFats` | `Double` | Tổng Chất béo (Fats) thực tế nạp vào trong ngày (g). |
| `burnedCalories` | `Double` | Tổng Calo thực tế đốt cháy từ các hoạt động thể chất trong ngày. |
| `targetCalories` | `Double` | Calo mục tiêu nạp vào của ngày đó (lấy snapshot từ lộ trình hoạt động). |
| `targetProtein` | `Double` | Mục tiêu chất đạm của ngày đó (g). |
| `targetCarbs` | `Double` | Mục tiêu tinh bột của ngày đó (g). |
| `targetFats` | `Double` | Mục tiêu chất béo của ngày đó (g). |
| `totalWater` | `Double` | Lượng nước uống trong ngày (đơn vị: ml). |
| `createdAt` | `Timestamp` | Thời điểm tạo bản ghi. |
| `updatedAt` | `Timestamp` | Thời điểm cập nhật bản ghi gần nhất. |

---

## 3. Subcollection: `meals` (con của `users/{userId}`)
Lưu trữ chi tiết các bữa ăn trong ngày của người dùng cùng với danh sách món ăn cụ thể.
* **Đường dẫn**: `users/{userId}/meals/{mealId}`
* **Document ID**: `mealId` có định dạng `"buaAn_nam-thang-ngay_gio-phut-giay"` (Ví dụ: `"breakfast_2026-05-26_08-30-00"`)

### Các trường dữ liệu (Fields):
| Tên trường (Field) | Kiểu dữ liệu (Type) | Mô tả |
| :--- | :--- | :--- |
| `id` | `String` | ID bữa ăn (trùng với Document ID). |
| `userId` | `String` | ID người dùng. |
| `mealType` | `String` | Loại bữa ăn (`"breakfast"`, `"lunch"`, `"dinner"`, `"snack"`). |
| `totalCalories` | `Double` | Tổng Calo của cả bữa ăn. |
| `totalProtein` | `Double` | Tổng chất đạm của cả bữa ăn (g). |
| `totalCarbs` | `Double` | Tổng tinh bột của cả bữa ăn (g). |
| `totalFats` | `Double` | Tổng chất béo của cả bữa ăn (g). |
| `dateKey` | `String` | Chuỗi định dạng ngày `"yyyy-MM-dd"`. |
| `imageUrl` | `String` | URL ảnh chụp bữa ăn lưu trữ trên Firebase Storage (Optional). |
| `createdAt` | `Timestamp` | Thời gian ghi nhận bữa ăn. |
| `food` | `Array (Objects)` | Danh sách các món ăn có trong bữa ăn này (xem định dạng đối tượng dưới đây). |

### Cấu trúc đối tượng `Food` trong mảng `food`:
| Thuộc tính (Property) | Kiểu dữ liệu (Type) | Mô tả |
| :--- | :--- | :--- |
| `id` | `String` | ID của món ăn (từ Edamam API hoặc tự tạo). |
| `name` | `String` | Tên món ăn (tiếng Việt hoặc tiếng Anh). |
| `imageUrl` | `String` | Link ảnh của món ăn (Optional). |
| `calories` | `Double` | Lượng Calo của 1 đơn vị khẩu phần món ăn. |
| `protein` | `Double` | Lượng chất đạm trong 1 đơn vị khẩu phần (g). |
| `carbs` | `Double` | Lượng tinh bột trong 1 đơn vị khẩu phần (g). |
| `fats` | `Double` | Lượng chất béo trong 1 đơn vị khẩu phần (g). |
| `servingSize` | `Double` | Kích thước trọng lượng khẩu phần chuẩn (ví dụ: `100.0`). |
| `servingUnit` | `String` | Đơn vị khẩu phần (ví dụ: `"Gram"`). |
| `quantity` | `Double` | Số lượng khẩu phần người dùng đã ăn (Ví dụ: `1.5` nghĩa là 1.5 lần servingSize). |
| `createdAt` | `Timestamp` | Thời gian thêm món ăn. |

---

## 4. Subcollection: `plans` (con của `users/{userId}`)
Lưu trữ thông tin lộ trình mục tiêu dinh dưỡng AI hiện tại của người dùng.
* **Đường dẫn**: `users/{userId}/plans/current_plan`
* **Document ID**: `current_plan` (Document cố định đại diện cho lộ trình đang kích hoạt)

### Các trường dữ liệu (Fields):
| Tên trường (Field) | Kiểu dữ liệu (Type) | Mô tả |
| :--- | :--- | :--- |
| `dailyCalories` | `Double` | Calo mục tiêu cần nạp hàng ngày. |
| `activityCalories` | `Double` | Calo mục tiêu cần đốt cháy hàng ngày thông qua luyện tập. |
| `protein` | `Double` | Chỉ số chất đạm mục tiêu hàng ngày (g). |
| `carbs` | `Double` | Chỉ số tinh bột mục tiêu hàng ngày (g). |
| `fat` | `Double` | Chỉ số chất béo mục tiêu hàng ngày (g). |
| `advice` | `String` | Lời khuyên tổng quan về dinh dưỡng từ AI. |
| `exercisePlan` | `String` | Lộ trình và hướng dẫn tập luyện chi tiết từ AI. |
| `startDate` | `Timestamp` | Ngày bắt đầu áp dụng lộ trình. |
| `endDate` | `Timestamp` | Ngày kết thúc lộ trình (hết hạn). |
| `currentWeight` | `Double` | Cân nặng tại thời điểm bắt đầu lộ trình (kg). |
| `targetWeight` | `Double` | Cân nặng mục tiêu hướng tới (kg). |
| `isActive` | `Boolean` | Trạng thái hoạt động của lộ trình (`true` là đang kích hoạt, `false` là đã hết hạn). |
| `createdAt` | `Timestamp` | Thời điểm tạo lộ trình. |
| `updatedAt` | `Timestamp` | Thời điểm cập nhật lộ trình (Optional). |

---

## 5. Subcollection: `history_plans` (con của `users/{userId}`)
Lưu trữ danh sách các lộ trình dinh dưỡng trong quá khứ đã hoàn thành hoặc bị người dùng hủy bỏ giữa chừng.
* **Đường dẫn**: `users/{userId}/history_plans/{documentId}`
* **Document ID**: Random Auto-generated ID

### Các trường dữ liệu (Fields):
* Sở hữu toàn bộ các trường dữ liệu tương tự tài liệu `current_plan`.
* Bổ sung các trường:
  * `status`: `String` (Trạng thái kết thúc: `"completed"` nếu hết hạn thành công, `"cancelled"` nếu bị người dùng chủ động xóa/hủy bỏ).
  * `archivedAt`: `Timestamp` (Thời điểm lưu trữ vào lịch sử).

---

## 6. Subcollection: `userActivities` (con của `users/{userId}`)
Lưu trữ nhật ký vận động thể thao, tập luyện của người dùng hàng ngày để tính tổng calo tiêu hao.
* **Đường dẫn**: `users/{userId}/userActivities/{logId}`
* **Document ID**: `logId` (Random Auto-generated ID hoặc UUID)

### Các trường dữ liệu (Fields):
| Tên trường (Field) | Kiểu dữ liệu (Type) | Mô tả |
| :--- | :--- | :--- |
| `id` | `String` | ID của nhật ký tập luyện (trùng với Document ID). |
| `durationMinutes` | `Double` | Thời gian tập luyện thực tế (đơn vị: Phút). |
| `caloriesBurned` | `Double` | Lượng Calo đã đốt cháy (tính toán tự động từ MET * Cân nặng * Thời gian). |
| `dateKey` | `String` | Chuỗi định dạng ngày `"yyyy-MM-dd"`. |
| `createdAt` | `Timestamp` | Thời điểm ghi nhận hoạt động tập luyện. |
| `activityType` | `Map (Object)` | Thông tin chi tiết về loại hoạt động (xem cấu trúc dưới đây). |

### Cấu trúc đối tượng `activityType`:
| Thuộc tính (Property) | Kiểu dữ liệu (Type) | Mô tả |
| :--- | :--- | :--- |
| `id` | `String` | ID của loại hoạt động gốc từ collection `activities` (Optional). |
| `name` | `String` | Tên hoạt động (ví dụ: `"Chạy bộ"`, `"Bơi lội"`, `"Yoga"`). |
| `metValue` | `Double` | Chỉ số MET của bài tập dùng để tính toán năng lượng. |
| `icon` | `String` | Tên SF Symbol hoặc biểu tượng đại diện. |

---

## 7. Root Collection: `activities`
Chứa bộ dữ liệu gốc về danh mục các môn thể thao/hoạt động thể chất do Admin quản lý để người dùng lựa chọn trên ứng dụng.
* **Đường dẫn**: `activities/{activityId}`
* **Document ID**: Auto-generated hoặc ID tự định nghĩa (Ví dụ: `"running"`, `"swimming"`)

### Các trường dữ liệu (Fields):
| Tên trường (Field) | Kiểu dữ liệu (Type) | Mô tả |
| :--- | :--- | :--- |
| `id` | `String` | ID của hoạt động (Optional). |
| `name` | `String` | Tên hoạt động (Ví dụ: `"Đi bộ (chậm)"`, `"Đá bóng"`). |
| `metValue` | `Double` | Chỉ số MET tương ứng của môn thể thao này. |
| `icon` | `String` | SF Symbol hoặc emoji icon hiển thị đại diện trên UI. |

---

## 8. Root Collection: `foods`
Bộ cơ sở dữ liệu các món ăn mẫu dùng chung được tạo thủ công từ phía Admin hoặc đóng góp từ cộng đồng người dùng.
* **Đường dẫn**: `foods/{foodId}`
* **Document ID**: Random Auto-generated ID

### Các trường dữ liệu (Fields):
* Các thuộc tính của món ăn tương tự cấu trúc đối tượng `Food` trong Collection `meals` (bao gồm: `name`, `calories`, `protein`, `carbs`, `fats`, `servingSize`, `servingUnit`).
* Bổ sung trường:
  * `createdAt`: `Timestamp` (Thời điểm tạo món ăn).

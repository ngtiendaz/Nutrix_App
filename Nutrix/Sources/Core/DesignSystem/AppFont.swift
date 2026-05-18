import SwiftUI

extension Font {
    struct App {
        /// Cỡ 60 - Dùng cho các số liệu cực lớn (ví dụ: vòng tròn tiến độ)
        static let huge = Font.system(size: 60, weight: .black)
        
        /// Cỡ 48 - Dùng cho số liệu chính nổi bật
        static let extraLarge = Font.system(size: 48, weight: .black)
        
        /// Cỡ 40 - Dùng cho số liệu quan trọng trong màn hình chi tiết
        static let large = Font.system(size: 40, weight: .black)
        
        /// Cỡ 32 - Dùng cho tiêu đề lớn
        static let display = Font.system(size: 32, weight: .black)
        
        /// Cỡ 24 - Dùng cho tiêu đề phụ hoặc số liệu vừa
        static let header = Font.system(size: 24, weight: .bold)
        
        /// Cỡ 22 - Dùng cho tiêu đề nội dung
        static let title2 = Font.system(size: 22, weight: .bold)
        
        /// Cỡ 19 - Dùng cho tiêu đề trong sheet hoặc card
        static let title3 = Font.system(size: 19, weight: .bold)
        
        /// Cỡ 18, Black - Dùng cho tiêu đề lớn, số liệu quan trọng (ví dụ: trung bình nạp)
        static let title = Font.system(size: 18, weight: .black)
        
        /// Cỡ 16, Bold - Dùng cho văn bản nội dung nhấn mạnh
        static let bodyBold = Font.system(size: 16, weight: .bold)
        
        /// Cỡ 16, Regular - Dùng cho văn bản nội dung lớn
        static let bodyLarge = Font.system(size: 16, weight: .regular)
        
        /// Cỡ 15, Bold - Dùng cho tiêu đề danh sách, tên món ăn chính
        static let headline = Font.system(size: 15, weight: .bold)
        
        /// Cỡ 15, Heavy - Dùng cho số liệu nhấn mạnh trong danh sách
        static let headlineHeavy = Font.system(size: 15, weight: .heavy)
        
        /// Cỡ 14, Bold - Dùng cho tiêu đề section, nút bấm chính, tiêu đề biểu đồ
        static let sectionHeader = Font.system(size: 14, weight: .bold)
        
        /// Cỡ 14, Regular - Dùng cho văn bản nội dung thông thường
        static let body = Font.system(size: 14, weight: .regular)
        
        /// Cỡ 13, Bold - Dùng cho văn bản nhấn mạnh nhỏ, Tab bar, nút tuần/tháng/năm
        static let subheadline = Font.system(size: 13, weight: .bold)
        
        /// Cỡ 13, Regular - Dùng cho văn bản phụ, thông báo trống
        static let subheadlineRegular = Font.system(size: 13, weight: .regular)
        
        /// Cỡ 12, Bold - Dùng cho label nhỏ, ngày tháng nhấn mạnh, tỉ lệ dinh dưỡng
        static let caption = Font.system(size: 12, weight: .bold)
        
        /// Cỡ 12, Medium - Dùng cho text mô tả nhỏ, chi tiết calo
        static let captionMedium = Font.system(size: 12, weight: .medium)
        
        /// Cỡ 11, Bold - Dùng cho tag, badge, xu hướng tăng trưởng
        static let small = Font.system(size: 11, weight: .bold)
        
        /// Cỡ 11, Semibold - Dùng cho label cực nhỏ (trung bình nạp)
        static let smallSemibold = Font.system(size: 11, weight: .semibold)
        
        /// Cỡ 10, Bold - Dùng cho text trong badge rất nhỏ, trạng thái hoàn thành
        static let tiny = Font.system(size: 10, weight: .bold)
        
        /// Cỡ 10, Medium - Dùng cho trục biểu đồ Y
        static let tinyMedium = Font.system(size: 10, weight: .medium)
        
        /// Cỡ 9, Bold - Dùng cho chú thích siêu nhỏ (không có lộ trình)
        static let micro = Font.system(size: 9, weight: .bold)
    }
}

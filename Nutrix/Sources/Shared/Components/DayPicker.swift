//
//  MonthPicker.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//

import SwiftUI

struct DayPicker: View {
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let today = Date()
    
    // BIẾN TRẠNG THÁI: Quản lý việc kích hoạt mở Popover lịch ẩn bằng mã Code
    @State private var showCalendarPopover = false

    var body: some View {
        // Đưa toàn bộ cụm vào ZStack để nhúng bộ lịch ẩn làm lớp nền vững chắc
        ZStack {
            // LỚP NỀN ẨN: Đặt DatePicker nằm chìm hoàn toàn ở dưới, không lấn chiếm 1 pixel nào trên TopBar
            DatePicker(
                "",
                selection: $selectedDate,
                in: ...today,
                displayedComponents: .date
            )
            .labelsHidden()
            .accentColor(Color.App.primary)
            .opacity(0.011) // Giữ độ mờ tối thiểu để biến mất hoàn toàn
            .id(showCalendarPopover) // Mẹo: Thay đổi ID để ép SwiftUI làm mới trạng thái kích hoạt khi cần
            
            // LỚP HIỂN THỊ CHÍNH: Giữ nguyên cấu trúc giao diện gốc phẳng lặng của ông
            HStack(spacing: 8) {
                // 1. Nút Lùi lại 1 ngày
                Button(action: { changeDay(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                        .background(Color.App.secondaryBackground)
                        .clipShape(Circle())
                }
                
                // 2. Ô hiển thị Ngày (Chạm vào chữ là tự động kích hoạt bộ lịch)
                Text(formatDate(selectedDate))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.App.secondaryBackground)
                    .cornerRadius(16)
                    // SỬA ĐỔI QUAN TRỌNG: Khi chạm vào chữ, lật State để kích hoạt DatePicker chìm ở dưới mở lịch
                    .onTapGesture {
                        showCalendarPopover.toggle()
                    }
                
                // 3. Nút Tiến lên 1 ngày (Bị khóa nếu chạm ngưỡng "Hôm nay")
                Button(action: { changeDay(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isNextDisabled ? .gray.opacity(0.3) : .gray)
                        .frame(width: 32, height: 32)
                        .background(Color.App.secondaryBackground)
                        .clipShape(Circle())
                }
                .disabled(isNextDisabled)
                
                // 4. Nút shortcut nhảy nhanh về "Hôm nay" khi ở quá khứ
                if !calendar.isDateInToday(selectedDate) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            selectedDate = today
                        }
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.App.primary)
                            .frame(width: 32, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
        }
    }
    
    // --- Logic Điều Phối Thời Gian ---
    
    private var isNextDisabled: Bool {
        return calendar.isDateInToday(selectedDate) || selectedDate > today
    }
    
    private func changeDay(by value: Int) {
        if let newDate = calendar.date(byAdding: .day, value: value, to: selectedDate) {
            if value > 0 && newDate > today && !calendar.isDateInToday(newDate) { return }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = newDate
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Hôm nay"
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        
        let currentYear = calendar.component(.year, from: today)
        let selectedYear = calendar.component(.year, from: date)
        
        if currentYear == selectedYear {
            formatter.dateFormat = "d 'thg' M"
        } else {
            formatter.dateFormat = "d 'thg' M, yyyy"
        }
        
        return formatter.string(from: date)
    }
}

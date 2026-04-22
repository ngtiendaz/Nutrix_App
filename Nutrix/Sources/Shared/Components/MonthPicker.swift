//
//  MonthPicker.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//

import SwiftUI

struct DayPicker: View { // Bạn có thể đổi tên thành DayPicker cho đúng ý nghĩa
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    private let today = Date()

    var body: some View {
        HStack(spacing: 12) {
            // 1. Nút Back
            Button(action: { changeDay(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .background(Color.App.secondaryBackground)
                    .clipShape(Circle())
            }
            
            // 2. Nhãn hiển thị Ngày (Hoặc "Hôm nay")
            Text(formatDate(selectedDate))
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.App.secondaryBackground)
                .cornerRadius(15)
            
            // 3. Nút Next (Bị chặn nếu là ngày hôm nay)
            Button(action: { changeDay(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(isNextDisabled ? .gray.opacity(0.3) : .gray)
                    .frame(width: 30, height: 30)
                    .background(Color.App.secondaryBackground)
                    .clipShape(Circle())
            }
            .disabled(isNextDisabled)
        }
    }
    
    // --- Logic Kiểm Tra ---
    
    private var isNextDisabled: Bool {
        // Kiểm tra nếu selectedDate lớn hơn hoặc bằng ngày hôm nay (tính theo ngày)
        return calendar.isDateInToday(selectedDate) || selectedDate > today
    }
    
    private func changeDay(by value: Int) {
        if let newDate = calendar.date(byAdding: .day, value: value, to: selectedDate) {
            // Bảo vệ không cho sang ngày mai
            if value > 0 && newDate > today && !calendar.isDateInToday(newDate) { return }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = newDate
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        // Kiểm tra nếu là hôm nay
        if calendar.isDateInToday(date) {
            return "Hôm nay"
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        
        // Kiểm tra nếu cùng năm thì ẩn năm đi cho gọn, hoặc hiện đầy đủ tùy bạn
        let currentYear = calendar.component(.year, from: today)
        let selectedYear = calendar.component(.year, from: date)
        
        if currentYear == selectedYear {
            formatter.dateFormat = "d 'thg' M" // Ví dụ: 16 thg 4
        } else {
            formatter.dateFormat = "d 'thg' M, yyyy" // Ví dụ: 16 thg 4, 2025
        }
        
        return formatter.string(from: date)
    }
}

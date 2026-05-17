//
//  TopBar.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

struct TopBar: View {
    @Binding var selectedTab: Tab
    @Binding var selectedDate: Date
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Text(selectedTab.title)
                .font(.system(size: 28)) // Hạ size xuống 28 một chút để cân bằng không gian khi xuất hiện nút Hôm nay phụ trợ
                .fontWeight(.bold)
                .foregroundColor(.black.opacity(0.8))
                .lineLimit(1)
            
            Spacer()
            
            // Hiển thị bộ chọn ngày cho Nhật ký, Thống kê, hoặc Hoạt động thể chất
            if selectedTab == .diary || selectedTab == .activity {
                DayPicker(selectedDate: $selectedDate)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            
        }
        // Thắt chặt hiệu ứng chuyển cảnh mượt mà
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
    }
}

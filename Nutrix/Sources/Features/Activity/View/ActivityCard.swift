//
//  ActivityCard.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//

import SwiftUI

struct ActivityCard: View {
    let log: UserActivityLog
    
    // MARK: - Helper to format Time
    private var startTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm" // Định dạng 24h
        return formatter.string(from: log.createdAt)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Section
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.App.primaryLight)
                    .frame(width: 54, height: 54)
                
                Image(systemName: log.activityType.icon)
                    .font(.App.header)
                    .foregroundColor(Color.App.primary)
            }
            
            // Info Section
            VStack(alignment: .leading, spacing: 6) {
                Text(log.activityType.name)
                    .font(.App.bodyBold)
                    .foregroundColor(Color.App.textPrimary)
                
                // Hiển thị 3 thông số: Giờ bắt đầu, Phút, Kcal
                HStack(spacing: 12) {
                    // Giờ bắt đầu
                    Label(startTime, systemImage: "timer")
                    
                    // Thời lượng
                    Label("\(Int(log.durationMinutes))p", systemImage: "clock")
                    
                    // Calo
                    Label("\(Int(log.caloriesBurned)) kcal", systemImage: "flame")
                }
                .font(.App.captionMedium) // Giảm size một chút để hàng thông tin không bị quá dài
                .foregroundColor(Color.App.lightGray)
            }
            
            Spacer()
            
            // Mũi tên điều hướng
            Image(systemName: "chevron.right")
                .font(.App.sectionHeader)
                .foregroundColor(Color.App.secondaryBackground)
        }
        .padding(14)
        .background(Color.App.cardBackground)
        .cornerRadius(22)
        .shadow(color: Color.App.shadow, radius: 8, x: 0, y: 4)
    }
}

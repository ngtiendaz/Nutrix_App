//
//  PlanSummaryCard.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//

import SwiftUI

struct PlanSummaryCard: View {
    let summary: PlanSummary
    
    var body: some View {
        VStack(spacing: 16) {
            // Row 1: Tiêu đề và Trạng thái
            HStack {
                Text("Lộ trình hiện tại")
                    .font(.App.sectionHeader)
                    .foregroundColor(.black.opacity(0.8))
                
                Spacer()
                
                // Badge trạng thái mini
                Text(summary.isActive ? "Đang thực hiện" : "Đã hoàn tất")
                    .font(.App.tiny)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(summary.isActive ? Color.App.primary.opacity(0.1) : Color.App.lightGray.opacity(0.1))
                    .foregroundColor(summary.isActive ? Color.App.primary : Color.App.lightGray)
                    .clipShape(Capsule())
            }
            
            // Row 2: Cân nặng mục tiêu
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(summary.currentWeight, specifier: "%.1f")")
                    .font(.App.title2)
                    .foregroundColor(Color.black)
                
                Image(systemName: "arrow.right")
                    .font(.App.caption)
                    .foregroundColor(Color.App.primary.opacity(0.5))
                
                Text("\(summary.targetWeight, specifier: "%.1f")")
                    .font(.App.title2)
                    .foregroundColor(Color.App.primary)
                
                Text("kg")
                    .font(.App.captionMedium)
                    .foregroundColor(Color.App.lightGray)
                
                Spacer()
            }
            
            // Row 3: Thời gian & Thanh tiến độ % theo ngày
            VStack(spacing: 8) {
                HStack {
                    Text("\(formatDate(summary.startDate)) — \(formatDate(summary.endDate))")
                        .font(.App.captionMedium)
                        .foregroundColor(Color.App.lightGray)
                    
                    Spacer()
                    
                    // Hiển thị % dựa trên số ngày thực tế
                    Text("\(Int(calculateProgress() * 100))%")
                        .font(.App.caption)
                        .foregroundColor(Color.App.primary)
                }
                
                // Thanh Progress tính toán theo thời gian thực
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.App.primary.opacity(0.1))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.App.primary)
                            .frame(width: geo.size.width * CGFloat(calculateProgress()), height: 6)
                    }
                }
                .frame(height: 6)
            }
            
            // Chú thích nhỏ về tiến độ ngày (Tùy chọn thêm để rõ ràng hơn)
            if summary.isActive {
                HStack {
                    Text("Đã thực hiện được \(daysElapsed()) ngày")
                        .font(.App.smallSemibold)
                        .foregroundColor(Color.App.lightGray)
                    Spacer()
                }
                .padding(.top, -4)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Helper Functions
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    // Tính toán tiến độ dựa trên số ngày
    private func calculateProgress() -> Double {
        let calendar = Calendar.current
        
        // Lấy ngày bắt đầu và kết thúc bỏ qua giờ phút giây để tính ngày thuần túy
        let start = calendar.startOfDay(for: summary.startDate)
        let end = calendar.startOfDay(for: summary.endDate)
        let today = calendar.startOfDay(for: Date())
        
        let totalDays = calendar.dateComponents([.day], from: start, to: end).day ?? 1
        let daysPassed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        
        // Đảm bảo % nằm trong khoảng 0.0 đến 1.0
        let progress = Double(daysPassed) / Double(totalDays)
        return max(0, min(1.0, progress))
    }
    
    // Trả về số ngày đã trôi qua để hiển thị text
    private func daysElapsed() -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: summary.startDate)
        let today = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: start, to: today).day ?? 0
    }
}

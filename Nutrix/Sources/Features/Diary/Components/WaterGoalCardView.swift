//
//  WaterGoalCardView.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//

import SwiftUI

struct WaterGoalCardView: View {
    let currentWater: Double // Lượng nước đã uống (Lít)
    let goalWater: Double = 2.0 // Mục tiêu mặc định (Lít)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Tiêu đề và icon
            HStack {
                Label("Nước uống", systemImage: "drop.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(String(format: "%.1f", currentWater)) / \(String(format: "%.1f", goalWater)) L")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Thanh tiến độ nước (Water Progress Bar)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Thanh nền
                    Capsule()
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 12)
                    
                    // Thanh mực nước hiện tại
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.5), .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(CGFloat(currentWater / goalWater) * geometry.size.width, geometry.size.width), height: 12)
                }
            }
            .frame(height: 12)
            
            // Chú thích phụ
            Text(currentWater >= goalWater ? "Tuyệt vời! Bạn đã uống đủ nước." : "Hãy uống thêm ít nước để đạt mục tiêu nhé.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .italic()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

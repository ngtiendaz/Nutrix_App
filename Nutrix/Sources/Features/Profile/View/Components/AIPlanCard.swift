//
//  AICoachCard.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//

import SwiftUI

struct AIPlanCard: View {
    // Thêm closure để xử lý sự kiện bấm nút
    var onStartPlan: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Top Section
            HStack(alignment: .center) {
                ZStack {
                    Circle()
                        .fill(Color.App.primary.opacity(0.12))
                        .frame(width: 46, height: 46)
                    Image(systemName: "calendar.badge.plus")
                        .font(.App.title2)
                        .foregroundColor(Color.App.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lộ trình NutriX AI")
                        .font(.App.bodyBold)
                        .foregroundColor(.black)
                    Text("Cá nhân hóa theo chỉ số cơ thể")
                        .font(.App.captionMedium)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("Sẵn sàng")
                        .font(.App.small)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.green.opacity(0.08)).cornerRadius(8)
            }
            
            // Suggestion Bar
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.App.captionMedium)
                    .foregroundColor(.orange)
                
                Text("AI sẽ tính toán Calo & thực đơn dựa trên mục tiêu cân nặng của bạn.")
                    .font(.App.captionMedium)
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.03)).cornerRadius(10)
            
            // Action Button
            Button(action: {
                // Gọi action truyền từ bên ngoài vào
                onStartPlan()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.App.body)
                    Text("Thiết lập lộ trình với AI")
                        .font(.App.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.App.primary, Color.App.primary.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.App.primary.opacity(0.25), radius: 6, x: 0, y: 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}

//
//  AIPlanPromoCard.swift
//  Nutrix
//
//  Created by Daz on 18/5/26.
//

import SwiftUI

struct AIPlanPromoCard: View {
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.App.display)
                .foregroundColor(Color.App.primary)
                .padding(22)
                .background(Color.App.primaryLight)
                .clipShape(Circle())
            
            VStack(spacing: 10) {
                Text("Thiết kế lộ trình với AI")
                    .font(.App.title2)
                    .foregroundColor(.black)
                Text("Hãy để Nutrix AI phân tích chỉ số cơ thể chuyên sâu và xây dựng mục tiêu dinh dưỡng cá nhân hoá phù hợp nhất dành riêng cho bạn.")
                    .font(.App.body)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 10)
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Text("Bắt đầu phân tích")
                    Image(systemName: "arrow.right")
                }
                .font(.App.bodyBold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.App.primary)
                .cornerRadius(16)
                .shadow(color: Color.App.primary.opacity(0.25), radius: 10, y: 6)
            }
        }
        .padding(28)
        .background(Color.white)
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.02), radius: 20, x: 0, y: 10)
    }
}

//
//  CircularProgress.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//
import SwiftUI

struct CircularProgress: View {
    let current: Double
    let goal: Double
    var color: Color = .green // Sử dụng màu chủ đạo của app (VD: Color.App.primary)
    
    @State private var animatedProgress: Double = 0
    
    // Kiểm tra trạng thái vượt ngưỡng dựa trên giá trị đang animate
    private var isOverGoal: Bool {
        animatedProgress > goal
    }
    
    // Tỷ lệ vòng chính (xanh) - dừng lại ở 1.0 khi đạt mục tiêu
    private var mainProgressRatio: CGFloat {
        guard goal > 0 else { return 0 }
        return CGFloat(min(animatedProgress / goal, 1.0))
    }
    
    // Tỷ lệ vòng phụ (đỏ) - bắt đầu chạy từ 0 khi vượt qua 1.0
    private var excessProgressRatio: CGFloat {
        guard goal > 0 else { return 0 }
        return CGFloat(max((animatedProgress - goal) / goal, 0))
    }

    var body: some View {
        ZStack {
            // 1. Vòng tròn nền (Track)
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 12)
            
            // 2. Vòng tiến độ chính (Mờ đi khi vượt mục tiêu để nổi bật vòng đỏ)
            Circle()
                .trim(from: 0, to: mainProgressRatio)
                .stroke(isOverGoal ? color.opacity(0.3) : color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // 3. Vòng dư thừa màu đỏ
            if isOverGoal {
                Circle()
                    .trim(from: 0, to: CGFloat(min(excessProgressRatio, 1.0)))
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 0)
            }
            
            // 4. Chỉ số trung tâm
            VStack(spacing: -2) {
                let diff = animatedProgress - goal
                
                // Sử dụng rollingNumber custom của bạn
                Color.clear
                    .frame(width: 0, height: 0)
                    .rollingNumber(value: abs(diff))
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(isOverGoal ? .red : .black)
                
                Text(isOverGoal ? "kcal vượt" : "kcal còn lại")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                    .textCase(.uppercase)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = current
            }
        }
        .onChange(of: current) { newValue in
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

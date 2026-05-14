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
    var color: Color = .App.primary
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(min(animatedProgress / goal, 1.0))) // Dùng biến animated
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: animatedProgress)
            
            VStack {
                Color.clear
                        .frame(width: 0, height: 0)
                        .rollingNumber(value: max(goal - animatedProgress, 0)) // Chạy theo biến animated
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                Text("kcal còn lại")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 140, height: 140)
        .onAppear {
                    // Khi hiện ra lần đầu, chạy từ 0 đến current
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        animatedProgress = current
                    }
                }
        .onChange(of: current) { newValue in
                    // Khi current thay đổi (kể cả về 0), thanh bar sẽ chạy lùi/tiến đến đó
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        animatedProgress = newValue
                    }
                }
    }
    private func updateProgress() {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = current
            }
        }
    private var progressRatio: CGFloat {
            guard goal > 0 else { return 0 }
            return CGFloat(min(animatedProgress / goal, 1.0))
        }
}

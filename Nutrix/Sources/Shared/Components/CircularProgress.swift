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
            
            VStack {
                Text("\(Int(goal - current))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                Text("kcal còn lại")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 140, height: 140)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { // Chạy trong 1.2 giây
                        animatedProgress = current
                    }
                }
    }
}

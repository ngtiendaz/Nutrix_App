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
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 12)
            Circle()
                .trim(from: 0, to: CGFloat(min(current / goal, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: current)
            
            VStack {
                Text("\(Int(goal - current))")
                    .font(.system(size: 40, weight: .bold))
                Text("kcal còn lại")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 150, height: 150)
    }
}

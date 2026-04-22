//
//  MacroCircle.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//
import SwiftUI

struct MacroCircle: View {
    let label: String
    let current: Double
    let goal: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(min(current / goal, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(Int(current))")
                        .font(.system(size: 14, weight: .bold))
                    Text("/ \(Int(goal))g")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 70, height: 70)
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
        }
    }
}

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
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(min(animatedProgress / goal, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: animatedProgress)
                
                VStack(spacing: 0) {
                    Color.clear
                            .frame(width: 0, height: 0)
                            .rollingNumber(value: animatedProgress) // Nhảy số từ 0 -> current hoặc ngược lại
                            .font(.App.sectionHeader)
                            .foregroundColor(.black)
                    Text("/ \(Int(goal))g")
                        .font(.App.tinyMedium)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 70, height: 70)
            
            Text(label)
                .font(.App.caption)
                .foregroundColor(.black)
        }.onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedProgress = current
            }
        }
        .onChange(of: current) { newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                animatedProgress = newValue
            }
        }
    }
    private func updateProgress() {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = current
            }
        }
    private var progressRatio: CGFloat {
            guard goal > 0 else { return 0 }
            return CGFloat(min(animatedProgress / goal, 1.0))
        }
}

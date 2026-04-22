//
//  WaterGoalCardView.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//

import SwiftUI

struct WaterGoalCardView: View {
    let currentWater: Double
    let goalWater: Double = 2.0
    
    @State private var animatedWidth: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
         
            HStack {
                Label("Nước uống", systemImage: "drop.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(String(format: "%.1f", currentWater)) / \(String(format: "%.1f", goalWater)) L")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            
           
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                  
                    Capsule()
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.5), .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: min(CGFloat(animatedWidth / goalWater) * geometry.size.width, geometry.size.width), height: 12)
                }
            }
            .frame(height: 12)
            
            Text(currentWater >= goalWater ? "Tuyệt vời! Bạn đã uống đủ nước." : "Hãy uống thêm ít nước để đạt mục tiêu nhé.")
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .italic()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    animatedWidth = currentWater
                }
        }
    }
}

//
//  NutritionGoalCardView.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//
import SwiftUI

struct NutritionGoalCardView: View {
    let data: DailyNutrition
    
    // Giả sử mục tiêu (Goal) của người dùng (có thể lấy từ Profile)
    let goalCalories: Double = 2560
    let goalProtein: Double = 128
    let goalCarbs: Double = 224
    let goalFat: Double = 128
    
    var body: some View {
        VStack(spacing: 25) {
            // Phần Calo chính
            HStack(spacing: 30) {
                VStack(alignment: .leading) {
                    Label("Đã ăn", systemImage: "leaf.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    Text("\(Int(data.totalCalories))")
                        .font(.system(size: 24, weight: .bold))
                    Text("kcal")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                CircularProgress(current: data.totalCalories, goal: goalCalories)
                
                VStack(alignment: .leading) {
                    Label("Đốt cháy", systemImage: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    Text("0") // Bạn có thể thêm trường burnedCalories vào model sau
                        .font(.system(size: 24, weight: .bold))
                    Text("kcal")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Phần 3 chỉ số chính
            HStack {
                Spacer()
                MacroCircle(label: "Carbs", current: data.totalCarbs, goal: goalCarbs, color: .blue.opacity(0.7))
                Spacer()
                MacroCircle(label: "Protein", current: data.totalProtein, goal: goalProtein, color: .red.opacity(0.7))
                Spacer()
                MacroCircle(label: "Fat", current: data.totalFat, goal: goalFat, color: .orange.opacity(0.7))
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
    }
}

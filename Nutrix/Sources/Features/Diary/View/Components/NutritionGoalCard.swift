//
//  NutritionGoalCardView.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//
import SwiftUI

struct NutritionGoalCard: View {
    let data: DailyNutrition
    let goal: NutritionPlan
    
    
    @State private var animatedCalories: Double = 0
    
    // Logic xác định trạng thái vượt ngưỡng
    private var isOverGoal: Bool {
        data.totalCalories > goal.dailyCalories
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                // Vòng tròn tiến độ
                CircularProgress(current: data.totalCalories, goal: goal.dailyCalories)
                    .frame(width: 110, height: 110)
                
                Spacer(minLength: 25)
                
                // Các chỉ số calo bên phải
                VStack(alignment: .leading, spacing: 18) {
                    nutritionRow(label: "Hấp thụ",
                                 value: data.totalCalories,
                                 unit: "kcal",
                                 icon: "leaf.fill",
                                 color: isOverGoal ? .red : .App.primary)
                    
                    nutritionRow(label: "Tiêu thụ",
                                 value: data.totalBurned ?? 0,
                                 unit: "kcal",
                                 icon: "flame.fill",
                                 color: .orange)
                }
                .frame(minWidth: 120, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal, 5)
            
            Divider()
                .padding(.vertical, 5)
            
            // Chỉ số Macro bên dưới
            HStack(spacing: 0) {
                macroGroup(label: "Tinh bột", current: data.totalCarbs, goal: goal.carbs, color: .blue)
                macroGroup(label: "Chất đạm", current: data.totalProtein, goal: goal.protein, color: .red)
                macroGroup(label: "Chất béo", current: data.totalFat, goal: goal.fat, color: .orange)
            }
            .padding(.horizontal, 10)
            
            // Cảnh báo thông minh khi vượt mức
            if isOverGoal {
                warningView
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedCalories = data.totalCalories
            }
        }
        .onChange(of: data.totalCalories) { newValue in
            withAnimation(.easeOut(duration: 0.8)) {
                animatedCalories = newValue
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
    }
    
    // View cảnh báo khi ăn quá mức
    private var warningView: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundColor(.red)
                .font(.App.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Vượt mục tiêu \(Int(data.totalCalories - goal.dailyCalories)) kcal")
                    .font(.App.sectionHeader)
                    .foregroundColor(.red)
                
                Text("Bạn đã nạp quá calo quy định. Hãy cân nhắc tập thêm một bài vận động nhẹ.")
                    .font(.App.captionMedium)
                    .foregroundColor(.black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func nutritionRow(label: String, value: Double, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(label, systemImage: icon)
                .font(.App.subheadline)
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(Int(value))")
                    .font(.App.header)
                    .foregroundColor(.black)
                
                Text(unit)
                    .font(.App.body)
                    .foregroundColor(.gray)
            }
        }
    }

    @ViewBuilder
    private func macroGroup(label: String, current: Double, goal: Double, color: Color) -> some View {
        MacroCircle(label: label, current: current, goal: goal, color: color.opacity(0.8))
            .frame(maxWidth: .infinity)
    }
}

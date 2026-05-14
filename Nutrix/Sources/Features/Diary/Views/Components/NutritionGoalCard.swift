//
//  NutritionGoalCardView.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//
import SwiftUI

struct NutritionGoalCard: View {
    let data: DailyNutrition
    @State private var animatedCalories: Double = 0
    @State private var animatedBurned: Double = 0
    
    let goalCalories: Double = 22560
    let goalProtein: Double = 128
    let goalCarbs: Double = 224
    let goalFat: Double = 128
    
    var body: some View {
        VStack(spacing: 20) {
      
            HStack(alignment: .center) {
              
                CircularProgress(current: data.totalCalories, goal: goalCalories)
                    .frame(width: 110, height: 110)
                
                Spacer(minLength: 25)
                
                // Cụm thông số bên phải
                VStack(alignment: .leading, spacing: 18) {
                    nutritionRow(label: "Đã ăn",
                                 value: Int(data.totalCalories),
                                 unit: "kcal",
                                 icon: "leaf.fill",
                                 color: .green)
                    
                    nutritionRow(label: "Đốt cháy",
                                 value: Int(data.totalBurned ?? 0),
                                 unit: "kcal",
                                 icon: "flame.fill",
                                 color: .orange)
                }.frame(minWidth: 120, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal, 5)
            
            Divider()
                .padding(.vertical, 5)
            
           
            HStack(spacing: 0) {
                macroGroup(label: "Carbs", current: data.totalCarbs, goal: goalCarbs, color: .blue)
                Spacer()
                macroGroup(label: "Protein", current: data.totalProtein, goal: goalProtein, color: .red)
                Spacer()
                macroGroup(label: "Fat", current: data.totalFat, goal: goalFat, color: .orange)
            }
            .padding(.horizontal, 10)
        }.onAppear {
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
        .background(Color(.white))
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
    }
    
    @ViewBuilder
    private func nutritionRow(label: String, value: Int, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Color.clear
                    .frame(width: 0, height: 0)
                    .rollingNumber(value: animatedCalories)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
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

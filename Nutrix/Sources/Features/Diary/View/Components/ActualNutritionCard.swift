import SwiftUI

struct ActualNutritionCard: View {
    let data: DailyNutrition
    
    @State private var animatedCalories: Double = 0
    @State private var animatedBurned: Double = 0
    @State private var animatedCarbs: Double = 0
    @State private var animatedProtein: Double = 0
    @State private var animatedFat: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tổng quan dinh dưỡng")
                        .font(.App.body)
                        .foregroundColor(Color.App.lightGray)
                    
                    Text(dateTitle)
                        .font(.App.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.App.title)
                    .foregroundColor(Color.App.primary)
            }
            
            Divider().background(Color.App.primary.opacity(0.1))
            
            // Calorie Info
            HStack(spacing: 20) {
                nutritionInfo(label: "Hấp thụ",
                              value: animatedCalories,
                              unit: "kcal",
                              icon: "leaf.fill",
                              color: Color.App.primary)
                
                Divider()
                    .frame(height: 40)
                    .background(Color.gray.opacity(0.2))
                
                nutritionInfo(label: "Tiêu thụ",
                              value: animatedBurned,
                              unit: "kcal",
                              icon: "flame.fill",
                              color: .orange)
            }
            .padding(.vertical, 5)
            
            // Macro breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Thành phần dinh dưỡng")
                    .font(.App.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    macroItem(label: "Carbs", value: animatedCarbs, color: .blue)
                    macroItem(label: "Đạm", value: animatedProtein, color: .red)
                    macroItem(label: "Béo", value: animatedFat, color: .orange)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.04), radius: 15, x: 0, y: 8)
        .onAppear { animateData() }
        .onChange(of: data.totalCalories) { _ in animateData() }
    }
    
    private func animateData() {
        withAnimation(.easeOut(duration: 0.8)) {
            animatedCalories = data.totalCalories
            animatedBurned = data.totalBurned ?? 0
            animatedCarbs = data.totalCarbs
            animatedProtein = data.totalProtein
            animatedFat = data.totalFat
        }
    }
    
    private var dateTitle: String {
        return "Số liệu thực tế"
    }
    
    @ViewBuilder
    private func nutritionInfo(label: String, value: Double, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.App.captionMedium)
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Color.clear
                    .frame(width: 0, height: 0)
                    .rollingNumber(value: value)
                    .font(.App.header)
                    .foregroundColor(.black)
                
                Text(unit)
                    .font(.App.body)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func macroItem(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.App.tinyMedium)
                .foregroundColor(.gray)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Color.clear
                    .frame(width: 0, height: 0)
                    .rollingNumber(value: value)
                    .font(.App.headline)
                    .foregroundColor(.black)
                
                Text("g")
                    .font(.App.caption)
                    .foregroundColor(.gray)
            }
            
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.2))
                .frame(height: 4)
                .overlay(
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color)
                            .frame(width: geo.size.width * 0.6) // Placeholder for bar progress
                    }
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.05))
        .cornerRadius(15)
    }
}

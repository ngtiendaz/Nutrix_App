import SwiftUI

struct ActualNutritionCard: View {
    let data: DailyNutrition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tổng dinh dưỡng đã nạp")
                        .font(.App.body)
                        .foregroundColor(Color.App.lightGray) // Màu xám nhẹ cho label phụ
                    
                    Text("\(Int(data.totalCalories)) kcal")
                        .font(.App.headlineHeavy)
                        .foregroundColor(.black) // Chuyển về màu đen cho nổi bật
                }
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.App.display)
                    .foregroundColor(Color.App.primary)
            }
            
            Divider().background(Color.App.primary.opacity(0.1))
            
            HStack(spacing: 8) {
                NutrientMiniCard(title: "Tiêu thụ", value: data.totalBurned ?? 0, color: .orange, unit: "kcal")
                NutrientMiniCard(title: "Tinh bột", value: data.totalCarbs, color: .blue)
                NutrientMiniCard(title: "Chất đạm", value: data.totalProtein, color: .red)
                NutrientMiniCard(title: "Chất béo", value: data.totalFat, color: .orange)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 5)
    }
    
}

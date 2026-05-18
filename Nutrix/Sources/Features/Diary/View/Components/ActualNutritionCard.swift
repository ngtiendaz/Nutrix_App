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
                        .font(.App.display)
                        .foregroundColor(.black) // Chuyển về màu đen cho nổi bật
                }
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.App.display)
                    .foregroundColor(Color.App.primary)
            }
            
            Divider().background(Color.App.primary.opacity(0.1))
            
            // Hàng hiển thị các chỉ số chi tiết với màu sắc riêng
            HStack(spacing: 0) {
                nutrientMiniValue(label: "Protein", value: data.totalProtein, color: .blue)
                nutrientMiniValue(label: "Carbs", value: data.totalCarbs, color: .red)
                nutrientMiniValue(label: "Fat", value: data.totalFat, color: .orange)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Helper View
    func nutrientMiniValue(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label (Protein, Carbs, Fat) sử dụng màu sắc định danh
            Text(label + ":")
                .font(.App.caption)
                .foregroundColor(color)
            
            // Con số hiển thị màu đen đậm
            Text("\(Int(value))g")
                .font(.App.title)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

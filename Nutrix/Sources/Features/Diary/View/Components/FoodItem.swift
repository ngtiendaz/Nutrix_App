import SwiftUI

struct FoodItem: View {
    let food: Food
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 12) {

                CachedImage(urlString: food.imageUrl, width: 100, height: 100)
                
                // MARK: - Food Details
                VStack(alignment: .leading, spacing: 8) {
                    // Header: Name & Unit
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .top){
                            Text(food.name)
                                .font(.App.title)
                                .foregroundColor(Color(hex: "333333"))
                            
                            Spacer()
                            Text("\(food.createdAt, format: .dateTime.hour().minute())")
                                    .font(.App.tiny)
                                    .foregroundColor(Color.App.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.App.primaryLight)
                                    .clipShape(Capsule())
                        }
                        let totalWeight = food.servingSize * food.quantity
                        Text("\(totalWeight.formatted()) \(food.servingUnit)")
                            .font(.App.captionMedium)
                            .foregroundColor(Color.App.lightGray)
                    }
                    
                    // Nutrients Row (Gọn hơn)
                    HStack(spacing: 15) {
                        NutrientSmallView(label: "Protein:", value: food.protein, color: .blue)
                        NutrientSmallView(label: "Cabs:", value: food.carbs, color: .red)
                        NutrientSmallView(label: "Fat:", value: food.fats, color: .orange)
                    }
                    
                    // Calories Row
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.App.captionMedium)
                            .foregroundColor(Color.App.primary)
                        
                        Text(String(format: "%.1f", food.calories))
                            .font(.App.bodyBold)
                            .foregroundColor(Color.App.primary)
                        
                        Text("Kcal")
                            .font(.App.captionMedium)
                            .foregroundColor(Color.App.lightGray)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.App.caption)
                            .foregroundColor(Color.App.lightGray)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
//            .padding(.horizontal)
        }
//        .padding(.horizontal)
    }
}



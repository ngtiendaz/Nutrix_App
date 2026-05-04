//
//  Untitled.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//
import Foundation
import SwiftUI

class RecommendationService {
    static let shared = RecommendationService()
    
    private init() {}
    
    func generateAdvice(
        currentFood: Food,
        quantity: Double,
        dailyNutrition: DailyNutrition,
        dailyGoal: DailyGoal,
        user: User,
        mealType: MealType // 👈 thêm
    ) -> AIAdvice {
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        let mealCalories = currentFood.calories * quantity
        let mealProtein = currentFood.protein * quantity
        
        // Fix lỗi tên biến từ Model Food: carbohydrates -> carbs, fat -> fats
        let projectedCalories = dailyNutrition.totalCalories + mealCalories
        
        // 1. KIỂM TRA KHẨU PHẦN (QUANTITY)
        if quantity >= 2.5 {
            return AIAdvice(
                title: "Khẩu phần quá lớn",
                message: "Daz ơi, bạn đang chọn tới \(String(format: "%.1f", quantity)) khẩu phần. Ăn quá nhiều một lúc dễ gây đầy bụng và giảm năng lượng làm việc vào \(getTimeDisplayName(hour: currentHour)).",
                statusColor: .orange,
                iconName: "exclamationmark.triangle.fill"
            )
        }
        
        let mealType = getMealTypeByTime(hour: currentHour)
        let isLoseWeightGoal = user.goal.lowercased().contains("lose")
        
        // 2. PHÂN TÍCH THEO MỤC TIÊU
        if isLoseWeightGoal {
            // Trường hợp vượt Calo ngày
            if projectedCalories > dailyGoal.targetCalories {
                let excess = projectedCalories - dailyGoal.targetCalories
                return AIAdvice(
                    title: "Vượt hạn mức Calo",
                    message: "Món này sẽ khiến bạn vượt ngưỡng ngày khoảng \(Int(excess)) Kcal. Để giữ lộ trình giảm cân, hãy thử giảm khẩu phần xuống còn 1.0 hoặc bù lại bằng bài tập Cardio nhé!",
                    statusColor: .red,
                    iconName: "xmark.octagon.fill"
                )
            }
            
            // Cảnh báo bữa đêm cho người giảm cân
            if mealType == .night {
                return AIAdvice(
                    title: "Cân nhắc bữa muộn",
                    message: "Cơ thể ít vận động vào ban đêm nên năng lượng từ \(currentFood.name) dễ tích tụ thành mỡ thừa. Bạn nên ưu tiên các món thanh đạm hơn.",
                    statusColor: .orange,
                    iconName: "moon.stars.fill"
                )
            }
        } else {
            // Mục tiêu Tăng cân / Tăng cơ: Kiểm tra Protein bữa trưa
            if mealProtein < 15 && mealType == .lunch {
                return AIAdvice(
                    title: "Cần thêm Protein",
                    message: "Bữa trưa rất quan trọng để xây dựng cơ bắp. Món này hơi thiếu đạm (\(Int(mealProtein))g), Daz nên bổ sung thêm trứng hoặc sữa hạt nhé!",
                    statusColor: .blue,
                    iconName: "plus.circle.fill"
                )
            }
        }

        // 3. KIỂM TRA TRẠNG THÁI DINH DƯỠNG TRONG NGÀY
        // Nếu đã qua buổi chiều mà nạp quá ít calo (dưới 50% mục tiêu)
        if dailyNutrition.totalCalories < dailyGoal.targetCalories * 0.5 && currentHour > 15 {
            return AIAdvice(
                title: "Nạp thêm năng lượng",
                message: "Daz ơi, bạn mới nạp chưa tới một nửa mục tiêu Calo ngày. Món \(currentFood.name) lúc này là lựa chọn tuyệt vời để lấy lại phong độ đấy!",
                statusColor: Color.App.primary,
                iconName: "bolt.fill"
            )
        }

        // 4. KHUYẾN NGHỊ MẶC ĐỊNH
        return AIAdvice(
            title: "Dinh dưỡng lý tưởng",
            message: "Món \(currentFood.name) hoàn toàn phù hợp với thực đơn \(getTimeDisplayName(hour: currentHour)) của bạn. Thưởng thức ngay thôi!",
            statusColor: Color.App.primary,
            iconName: "checkmark.seal.fill"
        )
    }
    
    private func getMealTypeByTime(hour: Int) -> MealType {
        switch hour {
        case 5...10: return .breakfast
        case 11...14: return .lunch
        case 15...17: return .afternoon
        case 18...21: return .dinner
        default: return .night
        }
    }
    
    private func getTimeDisplayName(hour: Int) -> String {
        return getMealTypeByTime(hour: hour).displayName
    }
}

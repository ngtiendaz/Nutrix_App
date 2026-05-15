//
//  GeminiService.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//

import GoogleGenerativeAI
import FirebaseFirestore

class GeminiService {
    private let apiKey: String
    private let model: GenerativeModel
    private let db = Firestore.firestore()
    init() {
            // Lấy key từ AppConfig
            self.apiKey = AppConfig.visionAPIKey
            // Khởi tạo model bên trong init để tránh lỗi "instance member"
            self.model = GenerativeModel(name: "gemini-1.5-flash", apiKey: self.apiKey)
        }
    func generatePlan(user: User, input: AIPlanInput) async throws -> NutritionPlan? {
        let prompt = """
        Dựa trên thông tin người dùng:
        - Tên: \(user.name), Tuổi: \(user.age ?? 22), Giới tính: \(user.gender ?? "Nam")
        - Cân nặng hiện tại: \(user.weight ?? 70)kg, Chiều cao: \(user.height ?? 170)cm
        - Mức độ vận động: \(user.activityLevel ?? "Vừa phải")
        
        Mục tiêu:
        - Cân nặng hướng tới: \(input.targetWeight)kg
        - Thời gian thực hiện: \(input.durationMonths) tháng
        - Thời gian tập luyện mỗi ngày: \(input.exerciseMinutesPerDay) phút
        
        Hãy tính toán và trả về một JSON duy nhất với cấu trúc:
        {
          "dailyCalories": Int,
          "protein": Int,
          "carbs": Int,
          "fat": Int,
          "advice": String (Lời khuyên ngắn gọn),
          "exercisePlan": String (Gợi ý bài tập)
        }
        Chỉ trả về JSON, không kèm văn bản giải thích.
        """

        let response = try await model.generateContent(prompt)
        guard let text = response.text, let data = text.data(using: .utf8) else { return nil }
        
        return try JSONDecoder().decode(NutritionPlan.self, from: data)
    }
    
    func savePlanToFirestore(userId: String, plan: NutritionPlan) {
        let data: [String: Any] = [
            "dailyCalories": plan.dailyCalories,
            "protein": plan.protein,
            "carbs": plan.carbs,
            "fat": plan.fat,
            "advice": plan.advice,
            "exercisePlan": plan.exercisePlan,
            "startDate": Timestamp(date: plan.startDate ?? Date())
        ]
        db.collection("users").document(userId).collection("active_plan").document("current").setData(data)
    }
}

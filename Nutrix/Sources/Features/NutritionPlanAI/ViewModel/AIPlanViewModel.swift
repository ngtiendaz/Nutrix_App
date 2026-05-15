//
//  AIPlanViewModel.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//

import GoogleGenerativeAI
import Foundation
import Combine

@MainActor
class AIPlanViewModel: ObservableObject {
    @Published var targetWeight: String = ""
    @Published var duration: Double = 1.0
    @Published var exerciseTime: String = "30"
    @Published var generatedPlan: NutritionPlan?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    
    private let model = GenerativeModel(
        name: "models/gemini-2.5-flash",
        apiKey: AppConfig.geminiAPIKey,
        requestOptions: RequestOptions(apiVersion: "v1")
    )

    func createPlan(user: User) async {
            self.isLoading = true
            self.errorMessage = nil
            self.generatedPlan = nil
            
            // Chuyển đổi activity level sang mô tả tiếng Việt để AI hiểu rõ hơn
            let userActivity = user.activityLevel ?? "không rõ"
            
            let prompt = """
            Context: Bạn là chuyên gia dinh dưỡng và huấn luyện viên cá nhân của ứng dụng Nutrix.
            User: \(user.name), \(user.age ?? 22) tuổi, nặng \(user.weight ?? 0)kg, cao \(user.height ?? 0)cm.
            Mức độ hoạt động hiện tại: \(userActivity).
            Goal: Mục tiêu nặng \(targetWeight)kg trong \(Int(duration)) tháng.
            Thời gian tập luyện cam kết: \(exerciseTime) phút/ngày.
            
            Nhiệm vụ:
            1. Tính TDEE dựa trên chỉ số cơ thể và mức độ hoạt động (\(userActivity)).
            2. Tính 'dailyCalories' (lượng calo nạp vào hàng ngày để đạt mục tiêu).
            3. Tính 'activityCalories' (lượng calo mục tiêu cần đốt cháy thông qua tập luyện mỗi ngày).
            4. Đề xuất 'exercisePlan' CỤ THỂ dựa trên mức độ hoạt động (\(userActivity)):
               - Nếu ít vận động: Gợi ý các bài tập cường độ nhẹ, tăng dần.
               - Nếu vận động nhiều: Gợi ý các bài tập cường độ cao, tối ưu cơ bắp.

            Yêu cầu:
            1. Trả về DUY NHẤT 1 JSON object, không markdown.
            2. 'advice': Ngắn gọn, tập trung vào chế độ ăn và tính khả thi (2-3 câu).
            3. 'exercisePlan': Phải phù hợp với \(exerciseTime) phút tập luyện.
            
            JSON Structure:
            {
              "dailyCalories": 1800,
              "activityCalories": 300,
              "protein": 130,
              "carbs": 200,
              "fat": 60,
              "advice": "...",
              "exercisePlan": "..."
            }
            """
            
            do {
                print("--- 🚀 STARTING AI REQUEST WITH ACTIVITY LEVEL: \(userActivity) ---")
                let response = try await model.generateContent(prompt)
                
                guard let rawText = response.text else {
                    self.errorMessage = "AI không trả về văn bản."
                    isLoading = false
                    return
                }
                
                let cleanText = rawText
                    .replacingOccurrences(of: "```json", with: "")
                    .replacingOccurrences(of: "```", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                if let data = cleanText.data(using: .utf8) {
                    let decodedPlan = try JSONDecoder().decode(NutritionPlan.self, from: data)
                    self.generatedPlan = decodedPlan
                    print("✅ LOG: Decode thành công với Activity Calories: \(decodedPlan.activityCalories)")
                }
                
            } catch {
                self.errorMessage = "Lỗi kết nối AI: \(error.localizedDescription)"
                print("--- 🛠️ ERROR: \(error)")
            }
            self.isLoading = false
        }
}

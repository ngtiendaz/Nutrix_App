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
        apiKey: "AIzaSyCXZPcKW_lIzqMxTxzpFAd60Hqriw5bOKw",
        requestOptions: RequestOptions(apiVersion: "v1")
    )

    func createPlan(user: User) async {
        self.isLoading = true
        self.errorMessage = nil
        self.generatedPlan = nil
        
        let prompt = """
        Context: Bạn là chuyên gia dinh dưỡng của ứng dụng Nutrix.
        User: \(user.name), \(user.age ?? 22)t, nặng \(user.weight ?? 0)kg, cao \(user.height ?? 0)cm.
        Goal: \(targetWeight)kg trong \(Int(duration)) tháng, tập \(exerciseTime) phút/ngày.
        
        Nhiệm vụ: Tính toán TDEE và lộ trình.
        Yêu cầu:
        1. Trả về DUY NHẤT 1 JSON object, không markdown.
        2. 'advice': Ngắn gọn, súc tích (khoảng 2-3 câu), tập trung vào tính khả thi.
        3. 'exercisePlan': Gợi ý chung các bộ môn như Gym, Chạy bộ, Bơi lội, Đạp xe, Yoga để người dùng dễ chọn lựa.
        4. Không bao gồm trường 'waterLiters' trong JSON (Nutrix sẽ tự tính sau).
        
        JSON Structure:
        {"dailyCalories": 2000, "protein": 150, "carbs": 250, "fat": 70, "advice": "...", "exercisePlan": "..."}
        """
        
        do {
            print("--- 🚀 STARTING AI REQUEST ---")
            let response = try await model.generateContent(prompt)
            
            guard let rawText = response.text else {
                self.errorMessage = "AI không trả về văn bản."
                isLoading = false
                return
            }
            
            print("--- 📥 DEBUG AI RAW RESPONSE ---")
            print(rawText)
            
            let cleanText = rawText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                
            if let data = cleanText.data(using: .utf8) {
                // Sử dụng decoder tùy chỉnh nếu cần xử lý Date hoặc dùng giá trị mặc định trong struct
                let decodedPlan = try JSONDecoder().decode(NutritionPlan.self, from: data)
                self.generatedPlan = decodedPlan
                print("✅ LOG: Decode NutritionPlan thành công!")
            }
            
        } catch {
            print("--- 🛠️ DEEP DEBUG ERROR ---")
            if let genError = error as? GoogleGenerativeAI.GenerateContentError {
                self.errorMessage = "Lỗi nội dung AI: \(genError)"
            } else {
                self.errorMessage = error.localizedDescription
            }
            print("Error: \(error)")
        }
        self.isLoading = false
    }
}

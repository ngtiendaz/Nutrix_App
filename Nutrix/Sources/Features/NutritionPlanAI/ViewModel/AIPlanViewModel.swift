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
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date()
    @Published var exerciseTime: String = "30"
    @Published var healthNote: String = ""
    @Published var generatedPlan: NutritionPlan?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let model = GenerativeModel(
        name: "models/gemini-2.5-flash-lite",
        apiKey: AppConfig.geminiAPIKey,
        requestOptions: RequestOptions(apiVersion: "v1")
    )

    func createPlan(user: User) async {
        self.isLoading = true
        self.errorMessage = nil
        self.generatedPlan = nil
        
        let userActivity = user.activityLevel ?? "không rõ"
        
        let components = Calendar.current.dateComponents([.day], from: startDate, to: endDate)
        let durationDays = max(10, components.day ?? 10)
        
        let prompt = """
        Context: Bạn là chuyên gia dinh dưỡng và huấn luyện viên cá nhân của ứng dụng Nutrix.
        User: \(user.name), \(user.age ?? 22) tuổi, nặng \(user.weight ?? 0)kg, cao \(user.height ?? 0)cm.
        Mức độ hoạt động hiện tại: \(userActivity).
        Tình trạng sức khỏe/Lưu ý: \(healthNote.isEmpty ? "Không có lưu ý đặc biệt" : healthNote).
        Goal: Mục tiêu nặng \(targetWeight)kg trong \(durationDays) ngày.
        Thời gian tập luyện cam kết: \(exerciseTime) phút/ngày.
        
        Nhiệm vụ:
        1. Tính TDEE dựa trên chỉ số cơ thể và mức độ hoạt động (\(userActivity)).
        2. Tính 'dailyCalories' (lượng calo nạp vào hàng ngày để đạt mục tiêu).
        3. Tính 'activityCalories' (lượng calo mục tiêu cần đốt cháy thông qua tập luyện mỗi ngày).
        4. Đề xuất 'exercisePlan' CỤ THỂ dựa trên mức độ hoạt động (\(userActivity)) và Tình trạng sức khỏe:
           - Nếu ít vận động: Gợi ý các bài tập cường độ nhẹ, tăng dần.
           - Nếu vận động nhiều: Gợi ý các bài tập cường độ cao, tối ưu cơ bắp.
           - ĐẶC BIỆT: Nếu người dùng có bệnh lý (ví dụ: đau khớp, tiểu đường, tim mạch...) được ghi trong "Tình trạng sức khỏe", hãy điều chỉnh bài tập và lời khuyên dinh dưỡng cho PHÙ HỢP và AN TOÀN.

        Yêu cầu:
        1. Trả về DUY NHẤT 1 JSON object, không markdown.
        2. 'advice': Ngắn gọn, tập trung vào chế độ ăn, tính khả thi và CÁC LƯU Ý SỨC KHỎE nếu có (2-3 câu).
        3. 'exercisePlan': Phải phù hợp với \(exerciseTime) phút tập luyện và an toàn cho sức khỏe người dùng.
        
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
                self.errorMessage = "Không nhận được phản hồi từ trí tuệ nhân tạo."
                self.isLoading = false
                return
            }
            
            let cleanText = rawText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                
            if let data = cleanText.data(using: .utf8) {
                var decodedPlan = try JSONDecoder().decode(NutritionPlan.self, from: data)
                
                decodedPlan.currentWeight = user.weight
                decodedPlan.targetWeight = Double(self.targetWeight)
                decodedPlan.startDate = self.startDate
                decodedPlan.endDate = self.endDate
                
                self.generatedPlan = decodedPlan
                print("✅ LOG: Decode thành công. Target: \(decodedPlan.targetWeight ?? 0)")
            }
            
        } catch {
            print("--- 🛠️ ERROR SYSTEM: \(error)")
            let systemErrorString = String(describing: error)
            
            // Xử lý bắt lỗi 503 (Bị quá tải / High Demand từ phía Google Server)
            if systemErrorString.contains("503") || systemErrorString.contains("high demand") {
                self.errorMessage = "Đã xảy ra lỗi khi kết nối đến máy chủ."
            } else {
                self.errorMessage = "Lỗi kết nối mạng hoặc không thể phân tích dữ liệu. Vui lòng thử lại."
            }
        }
        self.isLoading = false
    }
}

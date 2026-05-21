import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import GoogleGenerativeAI

// Cấu trúc dữ liệu cho điểm biểu đồ xu hướng cân nặng
struct WeightChartPoint: Identifiable {
    let id = UUID()
    let dateLabel: String
    let weight: Double
    let type: String // "Hiện tại" hoặc "Mục tiêu"
}

class PlanViewModel: ObservableObject {
    @Published var currentPlan: NutritionPlan? = nil
    @Published var historyPlans: [NutritionPlan] = []
    @Published var weeklyStreak: [(dayName: String, isCompleted: Bool, isToday: Bool)] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Lưu trữ thông tin User thực tế lấy từ FirebaseAuthService
    @Published var user: User? = nil
    @Published var metricsHistory: [BodyMetrics] = []
    
    // Thuộc tính phục vụ cho Đánh giá tiến trình AI
    @Published var evaluationResult: NutritionPlan? = nil
    @Published var evaluationAdvice: String? = nil
    @Published var isEvaluating: Bool = false
    
    private var lastEvaluationTime: Date? = nil
    private let evaluationCooldown: TimeInterval = 60 // 1 phút giữa các lần đánh giá

    // Input tạm phục vụ cho chế độ Edit toàn bộ Plan
    @Published var isEditingPlan: Bool = false
    @Published var editDailyCalories: String = ""
    @Published var editProtein: String = ""
    @Published var editCarbs: String = ""
    @Published var editFat: String = ""
    @Published var editCurrentWeight: String = ""
    @Published var editTargetWeight: String = ""
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    private let authService: FirebaseAuthService
    
    // Computed property chuyển đổi danh sách chỉ số cơ thể thành dữ liệu vẽ biểu đồ
    var weightChartData: [WeightChartPoint] {
        var points: [WeightChartPoint] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        
        // Sắp xếp lịch sử từ cũ đến mới (metricsHistory thường là mới nhất trước)
        let sortedMetrics = metricsHistory.sorted(by: { $0.timestamp < $1.timestamp })
        
        for metric in sortedMetrics {
            let label = formatter.string(from: metric.timestamp)
            points.append(WeightChartPoint(dateLabel: label, weight: metric.weight, type: "Cân nặng"))
        }
        
        return points
    }
    
    init(authService: FirebaseAuthService = FirebaseAuthService()) {
        self.authService = authService
        
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedUser in
                self?.user = updatedUser
            }
            .store(in: &cancellables)
    }
    
    func loadAllData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.isLoading = true
        self.evaluationResult = nil
        self.evaluationAdvice = nil
        let group = DispatchGroup()
        
        authService.fetchUserData(userId: userId)
        
        group.enter()
        firebaseService.fetchCurrentPlan(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let plan):
                    self?.currentPlan = plan
                    if let plan = plan {
                        self?.setupEditFields(from: plan)
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
                group.leave()
            }
        }
        
        group.enter()
        firebaseService.fetchHistoryPlans(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let history):
                    self?.historyPlans = history
                case .failure(let error):
                    print("Lỗi load history: \(error)")
                }
                group.leave()
            }
        }

        group.enter()
        authService.fetchBodyMetricsHistory { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let history):
                    self?.metricsHistory = history
                case .failure(let error):
                    print("Lỗi load metrics: \(error)")
                }
                group.leave()
            }
        }
        
        group.enter()
        fetchRealWeeklyStreak(userId: userId) {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }

    func evaluateProgressWithAI() async {
        // 1. Guard chống re-entry (bấm nhiều lần)
        if isEvaluating { return }
        
        // 2. Cooldown local (tránh gửi dồn dập trong 1 phút)
        if let lastTime = lastEvaluationTime, Date().timeIntervalSince(lastTime) < evaluationCooldown {
            let remain = Int(evaluationCooldown - Date().timeIntervalSince(lastTime))
            self.errorMessage = "Vui lòng đợi \(remain) giây để tiếp tục đánh giá."
            return
        }

        print("🚀 [AI EVAL] Bắt đầu đánh giá tiến trình...")
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ [AI EVAL] Lỗi: Không tìm thấy UserId")
            return
        }
        guard let plan = currentPlan else {
            print("❌ [AI EVAL] Lỗi: Không tìm thấy Current Plan")
            return
        }
        
        self.isEvaluating = true
        self.errorMessage = nil
        
        // 1. Lấy dữ liệu 7 ngày gần nhất (Batching data)
        let db = Firestore.firestore()
        print("📅 [AI EVAL] Đang tải 7 ngày daily_summaries (Gom nhóm dữ liệu)...")
        
        var recentSummaries: [[String: Any]] = []
        
        do {
            let snapshot = try await db.collection("users").document(userId).collection("daily_summaries")
                .order(by: "dateKey", descending: true)
                .limit(to: 7)
                .getDocuments()
            
            recentSummaries = snapshot.documents.map { $0.data() }
            print("📊 [AI EVAL] Đã gom nhóm xong \(recentSummaries.count) ngày thành 1 yêu cầu duy nhất.")
            
            // 2. Gọi AI để đánh giá
            let userWeight = user?.weight ?? 0.0
            let healthNote = user?.healthNote ?? "Không có"
            
            var summaryPrompt = ""
            for summary in recentSummaries {
                let date = summary["dateKey"] as? String ?? ""
                let intake = summary["intakeCalories"] as? Double ?? 0.0
                let target = summary["targetCalories"] as? Double ?? 0.0
                summaryPrompt += "- \(date): \(intake)/\(target) kcal\n"
            }
            
            let prompt = """
            Context: Chuyên gia dinh dưỡng Nutrix.
            Task: Đánh giá 7 ngày qua và điều chỉnh lộ trình (tối đa +/- 15%).
            
            User: \(user?.name ?? "User"), \(userWeight)kg, Goal: \(plan.targetWeight ?? 0.0)kg. Health: \(healthNote).
            Current Plan: \(plan.dailyCalories) kcal (P:\(plan.protein), C:\(plan.carbs), F:\(plan.fat)).
            
            History:
            \(summaryPrompt)
            
            Output: DUY NHẤT JSON. 'advice' dùng gạch đầu dòng, ngắn gọn ý chính.
            
            {
              "dailyCalories": 1850, "protein": 135, "carbs": 210, "fat": 60,
              "advice": "• ...\\n• ...", "hasChanges": true
            }
            """
            
            print("🤖 [AI EVAL] Đang gửi 1 yêu cầu duy nhất (Batch Request) tới Gemini...")
            let model = GoogleGenerativeAI.GenerativeModel(
                name: "models/gemini-2.5-flash",
                apiKey: AppConfig.geminiAPIKey,
                requestOptions: RequestOptions(apiVersion: "v1")
            )
            let response = try await model.generateContent(prompt)
            
            if let rawText = response.text {
                print("📝 [AI EVAL] Phân tích phản hồi...")
                if let cleanJSON = extractJSON(from: rawText) {
                    if let data = cleanJSON.data(using: .utf8) {
                        let evaluation = try JSONDecoder().decode(AIEvaluationResponse.self, from: data)
                        print("✅ [AI EVAL] Thành công.")
                        
                        var newPlan = plan
                        newPlan.dailyCalories = evaluation.dailyCalories
                        newPlan.protein = evaluation.protein
                        newPlan.carbs = evaluation.carbs
                        newPlan.fat = evaluation.fat
                        newPlan.advice = evaluation.advice
                        
                        DispatchQueue.main.async {
                            self.evaluationResult = newPlan
                            self.lastEvaluationTime = Date() // Cập nhật thời gian đánh giá thành công
                        }
                    }
                }
            }
            
        } catch {
            print("❌ [AI EVAL] Lỗi hệ thống: \(error)")
            let errorString = String(describing: error)
            
            if errorString.contains("429") || errorString.contains("Quota exceeded") {
                if let range = errorString.range(of: "retry in ") {
                    let waitTime = errorString[range.upperBound...].components(separatedBy: "s").first ?? "một lát"
                    self.errorMessage = "Giới hạn AI: Thử lại sau \(waitTime) giây."
                } else {
                    self.errorMessage = "Hệ thống AI đang bận. Vui lòng thử lại sau 1 phút."
                }
            } else if errorString.contains("503") {
                self.errorMessage = "Máy chủ AI đang bảo trì. Vui lòng thử lại sau."
            } else {
                self.errorMessage = "Lỗi kết nối AI. Vui lòng thử lại sau."
            }
        }
        
        DispatchQueue.main.async {
            self.isEvaluating = false
        }
    }
    
    // Helper để trích xuất JSON từ chuỗi văn bản hỗn hợp
    private func extractJSON(from text: String) -> String? {
        guard let firstBrace = text.firstIndex(of: "{"),
              let lastBrace = text.lastIndex(of: "}") else {
            return nil
        }
        
        let jsonString = String(text[firstBrace...lastBrace])
        return jsonString
    }
    
    struct AIEvaluationResponse: Codable {
        let dailyCalories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        let advice: String
        let hasChanges: Bool
    }
    
    private func fetchRealWeeklyStreak(userId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Tìm ngày Thứ 2 của tuần hiện tại
        var calendarForMonday = calendar
        calendarForMonday.firstWeekday = 2 // Monday
        
        let components = calendarForMonday.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let monday = calendarForMonday.date(from: components) else {
            completion()
            return
        }
        
        var targetDays: [(dayName: String, dateKey: String, isToday: Bool)] = []
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        
        let weekdayNames = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        
        for i in 0...6 {
            if let date = calendar.date(byAdding: .day, value: i, to: monday) {
                let dateKey = keyFormatter.string(from: date)
                let isToday = calendar.isDate(date, inSameDayAs: today)
                targetDays.append((dayName: weekdayNames[i], dateKey: dateKey, isToday: isToday))
            }
        }
        
        db.collection("users").document(userId).collection("daily_summaries")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion()
                    return
                }
                
                var updatedStreak: [(dayName: String, isCompleted: Bool, isToday: Bool)] = []
                let documents = snapshot?.documents ?? []
                
                for day in targetDays {
                    if let doc = documents.first(where: { $0.documentID == day.dateKey }) {
                        let data = doc.data()
                        let totalCalories = data["totalCalories"] as? Double ?? data["intakeCalories"] as? Double ?? 0.0
                        updatedStreak.append((dayName: day.dayName, isCompleted: totalCalories > 0, isToday: day.isToday))
                    } else {
                        updatedStreak.append((dayName: day.dayName, isCompleted: false, isToday: day.isToday))
                    }
                }
                
                DispatchQueue.main.async {
                    self.weeklyStreak = updatedStreak
                    completion()
                }
            }
    }
    
    func setupEditFields(from plan: NutritionPlan) {
        editDailyCalories = String(format: "%.0f", plan.dailyCalories)
        editProtein = String(format: "%.0f", plan.protein)
        editCarbs = String(format: "%.0f", plan.carbs)
        editFat = String(format: "%.0f", plan.fat)
        editCurrentWeight = String(format: "%.1f", plan.currentWeight ?? 0.0)
        editTargetWeight = String(format: "%.1f", plan.targetWeight ?? 0.0)
    }
    
    func savePlanUpdates() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let current = currentPlan else { return }
        
        let updatedPlan = NutritionPlan(
            dailyCalories: Double(editDailyCalories) ?? current.dailyCalories,
            activityCalories: current.activityCalories,
            protein: Double(editProtein) ?? current.protein,
            carbs: Double(editCarbs) ?? current.carbs,
            fat: Double(editFat) ?? current.fat,
            advice: current.advice,
            exercisePlan: current.exercisePlan,
            startDate: current.startDate,
            currentWeight: Double(editCurrentWeight) ?? current.currentWeight,
            targetWeight: Double(editTargetWeight) ?? current.targetWeight
        )
        
        isLoading = true
        firebaseService.updateCurrentPlan(
            userId: userId,
            plan: updatedPlan,
            startDate: current.startDate ?? Date(),
            endDate: Date().addingTimeInterval(30*24*60*60),
            currentWeight: updatedPlan.currentWeight ?? 0.0,
            targetWeight: updatedPlan.targetWeight ?? 0.0,
            isActive: true
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.currentPlan = updatedPlan
                    self?.isEditingPlan = false
                    self?.loadAllData()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func abandonCurrentPlan() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        firebaseService.deleteCurrentPlan(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.currentPlan = nil
                    self?.loadAllData()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func getPlanGoalType(current: Double, target: Double) -> String {
        if target < current { return "Giảm cân" }
        if target > current { return "Tăng cân" }
        return "Giữ dáng"
    }
    
    func calculateProgress(startDate: Date?, endDate: Date?) -> (daysPassed: Int, totalDays: Int, percentage: Double) {
        guard let start = startDate, let end = endDate else { return (0, 1, 0.0) }
        let calendar = Calendar.current
        
        let totalDays = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 1
        let daysPassed = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: Date())).day ?? 0
        
        let safeDaysPassed = max(0, min(daysPassed, totalDays))
        let percentage = (Double(safeDaysPassed) / Double(totalDays == 0 ? 1 : totalDays)) * 100
        
        return (safeDaysPassed, totalDays == 0 ? 1 : totalDays, percentage)
    }
}

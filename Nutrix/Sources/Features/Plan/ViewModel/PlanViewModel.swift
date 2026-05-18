import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

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
    @Published var weeklyStreak: [(dayName: String, isCompleted: Bool)] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Lưu trữ thông tin User thực tế lấy từ FirebaseAuthService
    @Published var user: User? = nil
    
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
    
    // Computed property chuyển đổi danh sách lộ trình thành dữ liệu vẽ biểu đồ đường
    var weightChartData: [WeightChartPoint] {
        var points: [WeightChartPoint] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        
        // 1. Lấy chỉ số từ các lộ trình cũ trong lịch sử (đảo ngược để chạy tuyến tính từ cũ đến mới nhất)
        let sortedHistory = historyPlans.reversed()
        for plan in sortedHistory {
            if let start = plan.startDate {
                let label = formatter.string(from: start)
                if let currentW = plan.currentWeight {
                    points.append(WeightChartPoint(dateLabel: label, weight: currentW, type: "Cân nặng"))
                }
            }
        }
        
        // 2. Thêm chỉ số của lộ trình đang kích hoạt hiện tại ở cuối biểu đồ
        if let currentPlan = currentPlan, let start = currentPlan.startDate {
            let label = formatter.string(from: start)
            if let currentW = currentPlan.currentWeight {
                points.append(WeightChartPoint(dateLabel: label, weight: currentW, type: "Cân nặng"))
            }
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
        fetchRealWeeklyStreak(userId: userId) {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    private func fetchRealWeeklyStreak(userId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let calendar = Calendar.current
        let today = Date()
        
        var targetDays: [(dayName: String, dateKey: String)] = []
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "vi_VN")
        weekdayFormatter.dateFormat = "E"
        
        for i in (0...6).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dateKey = keyFormatter.string(from: date)
                var name = weekdayFormatter.string(from: date)
                
                name = name.replacingOccurrences(of: "Th ", with: "T")
                if name.contains("Chủ") || name.contains("CN") { name = "CN" }
                
                targetDays.append((dayName: name, dateKey: dateKey))
            }
        }
        
        db.collection("users").document(userId).collection("daily_summaries")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion()
                    return
                }
                
                var updatedStreak: [(dayName: String, isCompleted: Bool)] = []
                let documents = snapshot?.documents ?? []
                
                for day in targetDays {
                    if let doc = documents.first(where: { $0.documentID == day.dateKey }) {
                        let data = doc.data()
                        let totalCalories = data["totalCalories"] as? Double ?? data["intakeCalories"] as? Double ?? 0.0
                        updatedStreak.append((dayName: day.dayName, isCompleted: totalCalories > 0))
                    } else {
                        updatedStreak.append((dayName: day.dayName, isCompleted: false))
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

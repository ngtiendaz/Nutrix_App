//
//  PlanViewModel.swift
//  Nutrix
//
//  Created by Daz on 18/5/26.
//


//
//  PlanViewModel.swift
//  Nutrix
//
//  Created by Daz on 18/5/26.
//

import Foundation
import Combine
import FirebaseAuth

class PlanViewModel: ObservableObject {
    @Published var currentPlan: NutritionPlan? = nil
    @Published var historyPlans: [NutritionPlan] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // ✅ Lưu trữ thông tin User thực tế lấy từ FirebaseAuthService
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
    
    // ✅ Sử dụng Dependency Injection để lấy instance của FirebaseAuthService
    init(authService: FirebaseAuthService = FirebaseAuthService()) {
        self.authService = authService
        
        // Lắng nghe sự thay đổi của currentUser từ FirebaseAuthService
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
        
        // Trigger fetch lại thông tin user từ Firestore để đảm bảo chỉ số mới nhất (nếu cần)
        authService.fetchUserData(userId: userId)
        
        // 1. Load Current Plan
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
        
        // 2. Load History Plans
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
        
        group.notify(queue: .main) {
            self.isLoading = false
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
    
    // MARK: - Helper Logic Calculation
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

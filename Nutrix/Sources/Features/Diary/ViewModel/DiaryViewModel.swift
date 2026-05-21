import Foundation
import Combine
import UIKit
import FirebaseAuth

class DiaryViewModel: ObservableObject, Hashable {
    @Published var isShowingCamera = false
    @Published var isShowingLibrary = false
    @Published var isShowingPermissionAlert = false
    @Published var selectedImage: UIImage?
    
    @Published var allFoods: [Food] = []
    @Published var dailyNutrition: DailyNutrition?
    @Published var currentPlan: NutritionPlan? = nil
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hasPlan: Bool = true
    @Published var planSummary: PlanSummary? = nil
    
    private var lastSelectedDate: Date = Date()
    
    // MARK: - Hashable
    static func == (lhs: DiaryViewModel, rhs: DiaryViewModel) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    func refreshData(onComplete: (() -> Void)? = nil, force: Bool = false) {
        fetchDailyData(for: lastSelectedDate, onComplete: onComplete, force: force)
    }
    
    
    // MARK: - Actions
    func handleCameraSelection() {
        PermissionManager.shared.checkCameraPermission(
            authorized: { self.isShowingCamera = true },
            denied: { self.isShowingPermissionAlert = true }
        )
    }
    
    func showLibrary() {
        self.isShowingLibrary = true
    }
    // Trong DiaryViewModel.swift

    @MainActor // Thêm cái này để đảm bảo mọi thay đổi UI đều an toàn
    func fetchDailyData(for date: Date, onComplete: (() -> Void)? = nil, force: Bool = false) {
        if isLoading && !force {
            onComplete?()
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        self.lastSelectedDate = date
        self.isLoading = true
        
        // Reset data cũ để tránh hiển thị sai lệch
        self.planSummary = nil
        self.currentPlan = nil
        
        let group = DispatchGroup()
        
        // --- TASK 1: PLAN ---
        group.enter()
        FirebaseService.shared.fetchPlanForDate(userId: userId, date: date) { [weak self] result in
            // Firebase trả về ở Background Thread -> Phải đẩy về Main
            DispatchQueue.main.async {
                self?.handlePlanResult(result, group: group)
            }
        }
        
        // --- TASK 2: FOODS ---
        group.enter()
        FirebaseService.shared.fetchMeals(userId: userId, date: date) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleMealsResult(result, date: date, userId: userId, group: group)
            }
        }
        
        // --- KẾT THÚC ---
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
            onComplete?()
            print("--- 🏁 RELOAD THÀNH CÔNG ---")
        }
    }

    // Đảm bảo các hàm Helper cũng chạy trên Main Thread
    private func handlePlanResult(_ result: Result<PlanSummary?, Error>, group: DispatchGroup) {
        // Luôn sử dụng defer để đảm bảo leave() luôn được gọi đúng 1 lần
        defer { group.leave() }
        
        if case .success(let summary) = result, let summary = summary {
            self.planSummary = summary
            self.currentPlan = NutritionPlan(
                dailyCalories: summary.dailyCalories,
                activityCalories: summary.activityCalories,
                protein: summary.protein,
                carbs: summary.carbs,
                fat: summary.fat,
                advice: "",
                exercisePlan: ""
            )
            self.hasPlan = true
        } else {
            self.hasPlan = false
        }
    }

    private func handleMealsResult(_ result: Result<[Meal], Error>, date: Date, userId: String, group: DispatchGroup) {
        DispatchQueue.main.async { [weak self] in
            defer { group.leave() }
            guard let self = self else { return }
            
            if case .success(let meals) = result {
                self.allFoods = meals.flatMap { $0.food }.sorted(by: { $0.createdAt > $1.createdAt })
                
                let calories = meals.reduce(0) { $0 + $1.totalCalories }
                let protein = meals.reduce(0) { $0 + $1.totalProtein }
                let carbs = meals.reduce(0) { $0 + $1.totalCarbs }
                let fats = meals.reduce(0) { $0 + $1.totalFats }
                
                self.dailyNutrition = DailyNutrition(
                    userId: userId,
                    date: FirebaseService.shared.getDateKey(from: date),
                    totalCalories: calories,
                    totalProtein: protein,
                    totalCarbs: carbs,
                    totalFat: fats,
                    totalWater: 0.0,
                    totalBurned: 0.0
                )
            }
        }
    }
}


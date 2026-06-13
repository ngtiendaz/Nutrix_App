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

    private(set) var lastSelectedDate: Date = Date()
    private var pendingNutrition = PendingDailyNutrition()

    private struct PendingDailyNutrition {
        var mealCalories: Double = 0
        var mealProtein: Double = 0
        var mealCarbs: Double = 0
        var mealFats: Double = 0
        
        var summaryCalories: Double = 0
        var summaryProtein: Double = 0
        var summaryCarbs: Double = 0
        var summaryFats: Double = 0
        var summaryBurned: Double = 0
        
        var hasMeals: Bool = false
        var hasSummary: Bool = false
    }

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

    @MainActor
    func fetchDailyData(for date: Date, onComplete: (() -> Void)? = nil, force: Bool = false) {
        if isLoading && !force {
            onComplete?()
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else { return }

        self.lastSelectedDate = date
        self.isLoading = true
        self.pendingNutrition = PendingDailyNutrition()

        self.planSummary = nil
        self.currentPlan = nil

        Task {
            // Sử dụng TaskGroup để chạy song song hiệu quả hơn
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.fetchPlan(userId: userId, date: date)
                }
                group.addTask {
                    await self.fetchMeals(userId: userId, date: date)
                }
                group.addTask {
                    await self.fetchSummary(userId: userId, date: date)
                }
            }
            
            self.applyPendingNutrition(userId: userId, date: date)
            self.isLoading = false
            onComplete?()
        }
    }

    private func fetchPlan(userId: String, date: Date) async {
        return await withCheckedContinuation { continuation in
            FirebaseService.shared.fetchPlanForDate(userId: userId, date: date) { [weak self] result in
                if case .success(let summary) = result, let summary = summary {
                    self?.planSummary = summary
                    self?.currentPlan = NutritionPlan(
                        dailyCalories: summary.dailyCalories,
                        activityCalories: summary.activityCalories,
                        protein: summary.protein,
                        carbs: summary.carbs,
                        fat: summary.fat,
                        advice: "",
                        exercisePlan: ""
                    )
                    self?.hasPlan = true
                } else {
                    self?.hasPlan = false
                }
                continuation.resume()
            }
        }
    }

    private func fetchMeals(userId: String, date: Date) async {
        return await withCheckedContinuation { continuation in
            FirebaseService.shared.fetchMeals(userId: userId, date: date) { [weak self] result in
                if case .success(let meals) = result {
                    self?.allFoods = meals.flatMap { $0.food }.sorted(by: { $0.createdAt > $1.createdAt })
                    self?.pendingNutrition.mealCalories = meals.reduce(0) { $0 + $1.totalCalories }
                    self?.pendingNutrition.mealProtein = meals.reduce(0) { $0 + $1.totalProtein }
                    self?.pendingNutrition.mealCarbs = meals.reduce(0) { $0 + $1.totalCarbs }
                    self?.pendingNutrition.mealFats = meals.reduce(0) { $0 + $1.totalFats }
                    self?.pendingNutrition.hasMeals = true
                }
                continuation.resume()
            }
        }
    }

    private func fetchSummary(userId: String, date: Date) async {
        return await withCheckedContinuation { continuation in
            FirebaseService.shared.fetchDailySummary(userId: userId, date: date) { [weak self] result in
                if case .success(let summary) = result, let summary = summary {
                    self?.pendingNutrition.summaryCalories = summary.intakeCalories
                    self?.pendingNutrition.summaryProtein = summary.intakeProtein
                    self?.pendingNutrition.summaryCarbs = summary.intakeCarbs
                    self?.pendingNutrition.summaryFats = summary.intakeFats
                    self?.pendingNutrition.summaryBurned = summary.burnedCalories
                    self?.pendingNutrition.hasSummary = true
                }
                continuation.resume()
            }
        }
    }

    private func applyPendingNutrition(userId: String, date: Date) {
        guard pendingNutrition.hasMeals || pendingNutrition.hasSummary else {
            dailyNutrition = nil
            return
        }

        // Ưu tiên dùng dữ liệu từ Meals cho Intake vì nó được cập nhật tức thì hơn Summary trên Firestore
        // Dùng Summary cho phần Burned (vì trong Meal không có thông tin tập luyện)
        let totalCal = pendingNutrition.hasMeals ? pendingNutrition.mealCalories : pendingNutrition.summaryCalories
        let totalPro = pendingNutrition.hasMeals ? pendingNutrition.mealProtein : pendingNutrition.summaryProtein
        let totalCarb = pendingNutrition.hasMeals ? pendingNutrition.mealCarbs : pendingNutrition.summaryCarbs
        let totalFat = pendingNutrition.hasMeals ? pendingNutrition.mealFats : pendingNutrition.summaryFats
        let totalBurned = pendingNutrition.summaryBurned

        dailyNutrition = DailyNutrition(
            userId: userId,
            date: FirebaseService.shared.getDateKey(from: date),
            totalCalories: totalCal,
            totalProtein: totalPro,
            totalCarbs: totalCarb,
            totalFat: totalFat,
            totalWater: 0.0,
            totalBurned: totalBurned
        )
    }
}

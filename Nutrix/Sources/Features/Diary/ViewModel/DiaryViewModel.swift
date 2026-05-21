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

        let group = DispatchGroup()

        group.enter()
        FirebaseService.shared.fetchPlanForDate(userId: userId, date: date) { [weak self] result in
            DispatchQueue.main.async {
                self?.handlePlanResult(result, group: group)
            }
        }

        group.enter()
        FirebaseService.shared.fetchMeals(userId: userId, date: date) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleMealsResult(result, group: group)
            }
        }

        group.enter()
        FirebaseService.shared.fetchDailySummary(userId: userId, date: date) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleSummaryResult(result, group: group)
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.applyPendingNutrition(userId: userId, date: date)
            self.isLoading = false
            onComplete?()
        }
    }

    private func handlePlanResult(_ result: Result<PlanSummary?, Error>, group: DispatchGroup) {
        defer { group.leave() }

        if case .success(let summary) = result, let summary {
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

    private func handleMealsResult(_ result: Result<[Meal], Error>, group: DispatchGroup) {
        defer { group.leave() }

        guard case .success(let meals) = result else { return }

        allFoods = meals.flatMap { $0.food }.sorted(by: { $0.createdAt > $1.createdAt })

        pendingNutrition.mealCalories = meals.reduce(0) { $0 + $1.totalCalories }
        pendingNutrition.mealProtein = meals.reduce(0) { $0 + $1.totalProtein }
        pendingNutrition.mealCarbs = meals.reduce(0) { $0 + $1.totalCarbs }
        pendingNutrition.mealFats = meals.reduce(0) { $0 + $1.totalFats }
        pendingNutrition.hasMeals = true
    }

    private func handleSummaryResult(_ result: Result<DailySummary?, Error>, group: DispatchGroup) {
        defer { group.leave() }

        guard case .success(let summary) = result, let summary else { return }

        pendingNutrition.summaryCalories = summary.intakeCalories
        pendingNutrition.summaryProtein = summary.intakeProtein
        pendingNutrition.summaryCarbs = summary.intakeCarbs
        pendingNutrition.summaryFats = summary.intakeFats
        pendingNutrition.summaryBurned = summary.burnedCalories
        pendingNutrition.hasSummary = true
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

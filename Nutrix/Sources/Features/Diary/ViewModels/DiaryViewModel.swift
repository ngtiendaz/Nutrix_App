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
    
    private var lastSelectedDate: Date = Date()
    
    // MARK: - Hashable
    static func == (lhs: DiaryViewModel, rhs: DiaryViewModel) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    // MARK: - Data Fetching
    func fetchDailyData(for date: Date) {
        print("--- 🔄 BẮT ĐẦU FETCH DỮ LIỆU TỔNG HỢP ---")
        guard let userId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Vui lòng đăng nhập lại"
            return
        }
        
        self.lastSelectedDate = date
        self.isLoading = true
        self.errorMessage = nil
        
        // Sử dụng DispatchGroup để đồng bộ hóa việc tắt Loading
        let group = DispatchGroup()
        
        // 1. Fetch Plan
        group.enter()
        FirebaseService.shared.fetchCurrentPlan(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let plan):
                    if let plan = plan {
                        print("✅ Debug: Đã tìm thấy Plan.")
                        self?.currentPlan = plan
                        self?.hasPlan = true
                    } else {
                        print("⚠️ Debug: Người dùng không có Plan.")
                        self?.currentPlan = nil
                        self?.hasPlan = false
                    }
                case .failure(let error):
                    print("❌ Debug: Lỗi fetch plan: \(error)")
                    self?.hasPlan = false
                }
                group.leave()
            }
        }
        
        // 2. Fetch Foods
        group.enter()
        FirebaseService.shared.fetchMeals(userId: userId, date: date) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let meals):
                    print("✅ Debug: Đã lấy được \(meals.count) bữa ăn.")
                    self.allFoods = meals.flatMap { $0.food }.sorted(by: { $0.createdAt > $1.createdAt })
                    
                    // Tính toán dinh dưỡng thực tế trong ngày
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
                case .failure(let error):
                    print("❌ Debug: Lỗi fetch foods: \(error)")
                    self.errorMessage = error.localizedDescription
                }
                group.leave()
            }
        }
        
        // Sau khi cả 2 task hoàn thành
        group.notify(queue: .main) {
            print("--- 🏁 KẾT THÚC TẤT CẢ FETCH ---")
            self.isLoading = false
        }
    }

    func refreshData() {
        fetchDailyData(for: lastSelectedDate)
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
}

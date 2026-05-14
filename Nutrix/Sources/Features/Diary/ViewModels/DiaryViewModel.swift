//
//  DiaryViewModel.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//
import Foundation
import Combine
import UIKit
import FirebaseAuth

class DiaryViewModel: ObservableObject {
    @Published var isShowingCamera = false
    @Published var isShowingLibrary = false
    @Published var isShowingPermissionAlert = false
    @Published var selectedImage: UIImage?
    
    @Published var allFoods: [Food] = []
    @Published var dailyNutrition: DailyNutrition?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    
    func handleCameraSelection() {
            PermissionManager.shared.checkCameraPermission(
                authorized: {
                    // Đã có quyền -> Mở view camera custom
                    self.isShowingCamera = true
                },
                denied: {
                    // Bị từ chối -> Hiện thông báo dẫn đi Cài đặt
                    self.isShowingPermissionAlert = true
                }
            )
        }
        
    func showLibrary() {
        self.isShowingLibrary = true
    }
    
    func fetchDailyFoods(for date: Date) {
            guard let userId = Auth.auth().currentUser?.uid else {
                self.errorMessage = "Vui lòng đăng nhập lại"
                return
            }
            
            self.isLoading = true
            self.errorMessage = nil
            
            // CHỈ GỌI 1 LẦN DUY NHẤT
            FirebaseService.shared.fetchMeals(userId: userId, date: date) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    switch result {
                    case .success(let meals):
                        // 1. Xử lý danh sách món ăn lẻ để hiển thị List
                        self.allFoods = meals
                            .flatMap { $0.food }
                            .sorted(by: { $0.createdAt > $1.createdAt })
                        
                        // 2. Tận dụng mảng 'meals' để tính tổng dinh dưỡng ngay tại đây
                        let calories = meals.reduce(0) { $0 + $1.totalCalories }
                        let protein = meals.reduce(0) { $0 + $1.totalProtein }
                        let carbs = meals.reduce(0) { $0 + $1.totalCarbs }
                        let fats = meals.reduce(0) { $0 + $1.totalFats }
                        
                        // Cập nhật object DailyNutrition cho Card mục tiêu
                        self.dailyNutrition = DailyNutrition(
                            userId: userId,
                            date: FirebaseService.shared.getDateKey(from: date),
                            totalCalories: calories,
                            totalProtein: protein,
                            totalCarbs: carbs,
                            totalFat: fats,
                            totalWater: 0.0 ,
                            totalBurned: 0.0
                        )
                        
                        print("✅ Fetched & Calculated: \(self.allFoods.count) foods, \(calories) kcal.")
                        
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        print("❌ Error fetching: \(error)")
                    }
                }
            }
        }
}

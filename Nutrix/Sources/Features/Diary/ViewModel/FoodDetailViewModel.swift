//
//  FoodDetailViewModel.swift
//  Nutrix
//
import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
final class FoodDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldDismiss = false
    
    
    // State chỉnh sửa
    @Published var currentWeight: Double = 0
    @Published var currentQuantity: Double = 0
    @Published var lastAction: ActionType = .none
    enum Field { case weight, quantity }
    enum ActionType { case none, update, delete }
    
    private let firebaseService = FirebaseService.shared
    let originalFood: Food
    let mealDate: Date

    init(food: Food, mealDate: Date) {
        self.originalFood = food
        self.mealDate = mealDate
        self.currentWeight = food.servingSize
        self.currentQuantity = food.quantity
    }
    

    // MARK: - Logic Tính Toán
    var hasChanges: Bool {
        abs(currentWeight - originalFood.servingSize) > 0.1 ||
        abs(currentQuantity - originalFood.quantity) > 0.1
    }

    func calculateValue(_ originalValue: Double) -> Double {
        let weightRatio = currentWeight / (originalFood.servingSize != 0 ? originalFood.servingSize : 100)
        let quantityRatio = currentQuantity / (originalFood.quantity != 0 ? originalFood.quantity : 1)
        return originalValue * weightRatio * quantityRatio
    }

    var displayCalories: Int { Int(calculateValue(originalFood.calories)) }
    var displayCarbs: Double { calculateValue(originalFood.carbs) }
    var displayProtein: Double { calculateValue(originalFood.protein) }
    var displayFats: Double { calculateValue(originalFood.fats) }

    // MARK: - Firebase Actions
    func updateFood() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let updatedFood = Food(
            id: originalFood.id,
            name: originalFood.name,
            image: originalFood.imageUrl,
            calories: calculateValue(originalFood.calories),
            protein: calculateValue(originalFood.protein),
            carbs: calculateValue(originalFood.carbs),
            fats: calculateValue(originalFood.fats),
            servingSize: currentWeight,
            servingUnit: originalFood.servingUnit,
            quantity: currentQuantity,
            createdAt: originalFood.createdAt
        )

        isLoading = true
        firebaseService.updateFoodInMeals(userId: userId, mealDate: mealDate, oldFood: originalFood, newFood: updatedFood) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success = result {
                    self?.shouldDismiss = true
                    self?.lastAction = .update
                }
            }
        }
    }

    func deleteFood() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        firebaseService.deleteFoodFromMeal(userId: userId, mealDate: mealDate, foodToDelete: originalFood) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if case .success = result {
                    self?.shouldDismiss = true
                    self?.lastAction = .delete
                }
            }
        }
    }
}

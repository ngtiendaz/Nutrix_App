import Foundation
import FirebaseAuth
import Combine
import SwiftUI

class HistoryFoodListViewModel: ObservableObject {
    @Published var foods: [Food] = []
    @Published var filteredFoods: [Food] = []
    @Published var searchText: String = "" {
        didSet { filterFoods() }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadFoods(for date: Date) {
        isLoading = true
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirebaseService.shared.fetchMeals(userId: userId, date: date) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let meals):
                    // Lấy tất cả đồ ăn từ các bữa ăn trong ngày
                    var allFoods: [Food] = []
                    for meal in meals {
                        allFoods.append(contentsOf: meal.food)
                    }
                    self?.foods = allFoods
                    self?.filterFoods()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func filterFoods() {
        if searchText.isEmpty {
            filteredFoods = foods
        } else {
            filteredFoods = foods.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
}

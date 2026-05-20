//
//  ListFoodViewModel.swift
//  Nutrix
//
//  Created by Daz on 20/5/26.
//

import Foundation
import Combine

class ListFoodViewModel: ObservableObject {
    @Published var foods: [Food] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    
    // Mảng danh sách sau khi đã lọc qua ô Tìm kiếm
    var filteredFoods: [Food] {
        if searchText.isEmpty {
            return foods
        } else {
            return foods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
//    /// Hàm gọi FirebaseService để lấy danh sách món ăn dữ liệu về
//        func loadAllFoods() {
//            self.isLoading = true
//            self.errorMessage = nil
//            
//            print("🔍 [DEBUG] Bắt đầu gọi loadAllFoods()...")
//            
//            FirebaseService.shared.fetchFoods { [weak self] result in
//                DispatchQueue.main.async {
//                    guard let self = self else { return }
//                    self.isLoading = false
//                    
//                    switch result {
//                    case .success(let fetchedFoods):
//                        print("✅ [DEBUG] Thành công! Lấy được tổng cộng: \(fetchedFoods.count) món ăn.")
//                        self.foods = fetchedFoods
//                        
//                    case .failure(let error):
//                        print("❌ [DEBUG] Lỗi từ FirebaseService: \(error.localizedDescription)")
//                        self.errorMessage = "Không thể tải dữ liệu: \(error.localizedDescription)"
//                    }
//                }
//            }
//        }
}

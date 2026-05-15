//
//  NutritionPlanViewModel.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//

import Foundation
import Combine

class NutritionPlanViewModel: ObservableObject {
    @Published var isSaving: Bool = false
    @Published var saveError: String? = nil
    
    func handleSavePlan(
            userId: String,
            plan: NutritionPlan,
            durationMonths: Int,    // Thêm thời hạn
            currentWeight: Double,  // Thêm cân nặng hiện tại
            targetWeight: Double,   // Thêm cân nặng mục tiêu
            completion: @escaping (Bool) -> Void
    ) {
        self.isSaving = true
        self.saveError = nil
        
        // Gọi FirebaseService với đầy đủ các tham số mới
        FirebaseService.shared.saveNutritionPlan(
            userId: userId,
            plan: plan,
            durationMonths: durationMonths,
            currentWeight: currentWeight,
            targetWeight: targetWeight
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSaving = false
                switch result {
                case .success:
                    completion(true)
                case .failure(let error):
                    self?.saveError = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}

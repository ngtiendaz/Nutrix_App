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
    
    func handleSavePlan(userId: String, plan: NutritionPlan, completion: @escaping (Bool) -> Void) {
        self.isSaving = true
        self.saveError = nil
        
        FirebaseService.shared.saveNutritionPlan(userId: userId, plan: plan) { [weak self] result in
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

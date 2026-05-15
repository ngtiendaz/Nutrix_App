//
//  DailySummary.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//

import Foundation
import FirebaseFirestore

struct DailySummary: Codable, Identifiable {
    @DocumentID var id: String? // ID sẽ là định dạng "yyyy-MM-dd"
    let userId: String
    let dateKey: String
    
    // 1. Dinh dưỡng thực nạp (Cộng dồn từ Meals)
    var intakeCalories: Double
    var intakeProtein: Double
    var intakeCarbs: Double
    var intakeFats: Double
    var burnedCalories: Double // Tổng từ UserActivityLog trong ngày
    
    // 2. Snapshot mục tiêu tại thời điểm đó (Copy từ current_plan)
    let targetCalories: Double
    let targetProtein: Double
    let targetCarbs: Double
    let targetFats: Double
    
    let createdAt: Date
    
    // Tiện ích tính toán calo còn lại cho UI
    var netCalories: Double {
        return intakeCalories - burnedCalories
    }
}

//
//  MonthlySummary.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation

struct MonthlySummary: Codable {
    let userId: String
    
    let month: Int  // 1 - 12
    let year: Int   // 2026
    
    let totalCalories: Double
    let avgCalories: Double
    
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    
    let totalMeals: Int
    
    let daysTracked: Int
    
    let createdAt: Date
}

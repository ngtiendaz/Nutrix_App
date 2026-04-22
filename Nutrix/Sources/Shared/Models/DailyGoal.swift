//
//  DailyGoal.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation

struct DailyGoal: Codable {
    let userId: String
    let date: Date
    
    let targetCalories: Double
    let targetProtein: Double
    let targetFat: Double
    let targetCarbs: Double
    
    let targetWater: Double
}

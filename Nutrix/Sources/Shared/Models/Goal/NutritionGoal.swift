//
//  NutritionGoal.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation

struct NutritionGoal: Codable {
    let userIdL: String
    let goalType: String
    let targetWeight: Double
    let duration: Int
    let createdAt: Date
}

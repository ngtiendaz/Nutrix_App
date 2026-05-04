//
//  Meal.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation

struct Meal: Codable {
    let id: String
    let userId: String
    let mealType: MealType
    
    var food: [Food]
    var totalCalories: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFats: Double
    
    let dateKey: String
    let imageUrl: String?
    let createdAt: Date
}

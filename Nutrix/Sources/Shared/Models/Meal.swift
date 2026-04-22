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
    
    let food: [Food]
    
    let quantity: Double
    let mealType: MealType
    
    let imageUrl: String?
    let createdAt: Date
}

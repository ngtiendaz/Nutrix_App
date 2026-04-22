//
//  DailyNutrition.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//
import Foundation

struct DailyNutrition: Codable {
    let userId: String
    let date: String
    
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    
    let totalWater: Double 
}

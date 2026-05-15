//
//  NutritionPlan.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//
import Foundation
import Combine

struct AIPlanInput {
    var targetWeight: Double
    var durationMonths: Int
    var exerciseMinutesPerDay: Int
}

struct NutritionPlan: Codable, Hashable {
    var dailyCalories: Double
    var activityCalories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var advice: String
    var exercisePlan: String
    var startDate: Date? = Date()
    var endDate: Date? = Date()
    var currentWeight: Double?
    var targetWeight: Double?
    var duration: Int?
}
struct PlanSummary {
    let startDate: Date
    let endDate: Date
    let currentWeight: Double
    let targetWeight: Double
    let isActive: Bool
    
    var dailyCalories: Double = 0
    var activityCalories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
}

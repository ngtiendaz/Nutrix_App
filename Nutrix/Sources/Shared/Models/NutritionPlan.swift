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
    var protein: Double
    var carbs: Double
    var fat: Double
    var advice: String
    var exercisePlan: String
    var startDate: Date? = Date() // Thêm giá trị mặc định để tránh lỗi keyNotFound
}

//
//  UserActivityLog.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//
import Combine
import Foundation

struct UserActivityLog: Codable, Identifiable {
    let id: String
    let activityType: Activity
    let durationMinutes: Double 
    let caloriesBurned: Double
    let dateKey: String
    let createdAt: Date
}

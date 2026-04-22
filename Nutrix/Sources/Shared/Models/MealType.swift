//
//  MealType.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation

enum MealType: String, CaseIterable, Codable {
    case breakfast
    case lunch
    case afternoon
    case dinner
    case night
    case snack
    
    var displayName: String {
        switch self {
        case .breakfast: return "Sáng"
        case .lunch: return "Trưa"
        case .afternoon: return "Chiều"
        case .dinner: return "Tối"
        case .night: return "Đêm"
        case .snack: return "Bữa phụ"
        }
    }
}

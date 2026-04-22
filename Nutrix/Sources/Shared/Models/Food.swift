//
//  Food.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation

struct Food : Codable {
    let id: String
    let name: String
    
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
    
    let servingSize: Double
}

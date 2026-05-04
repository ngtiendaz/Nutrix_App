//
//  EdamamResponse.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//

import Foundation

struct EdamamResponse: Codable {
    let text: String?
    let parsed: [ParsedFood]
    let hints: [FoodHint]
}

struct ParsedFood: Codable {
    let food: EdamamFood
}

struct FoodHint: Codable {
    let food: EdamamFood
    let measures: [FoodMeasure]
}

struct EdamamFood: Codable, Identifiable {
    var id: String { foodId }
    let foodId: String
    let label: String
    let knownAs: String?
    let nutrients: Nutrients
    let category: String
    let categoryLabel: String
    let image: String?
}

struct Nutrients: Codable {
    let energyKcal: Double?
    let protein: Double?
    let fat: Double?
    let carbohydrates: Double?
    let fiber: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal = "ENERC_KCAL"
        case protein = "PROCNT"
        case fat = "FAT"
        case carbohydrates = "CHOCDF"
        case fiber = "FIBTG"
    }
}

struct FoodMeasure: Codable {
    let label: String
    let weight: Double
}

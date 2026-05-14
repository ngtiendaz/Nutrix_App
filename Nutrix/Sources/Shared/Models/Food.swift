//
//  Food.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation

import Foundation

struct Food: Codable, Identifiable , Hashable{
    let id: String
    let name: String
    let imageUrl: String?
    var localImageData: Data?
    // Các chỉ số dinh dưỡng chính
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
    
    // Thông tin về khẩu phần
    let servingSize: Double
    let quantity: Double
    let servingUnit: String // Gram
    
    let createdAt: Date
    
    // Hàm khởi tạo tiện ích để chuyển đổi từ Edamam sang Food của NutriX
    init(from edamamFood: EdamamFood, measure: FoodMeasure?) {
        self.id = edamamFood.foodId
        self.name = edamamFood.label
        self.imageUrl = edamamFood.image
        
        self.calories = edamamFood.nutrients.energyKcal ?? 0.0
        self.protein = edamamFood.nutrients.protein ?? 0.0
        self.carbs = edamamFood.nutrients.carbohydrates ?? 0.0
        self.fats = edamamFood.nutrients.fat ?? 0.0
        
        // Mặc định lấy trọng lượng từ measure nếu có, nếu không thì để 100 (đơn vị chuẩn Edamam)
        self.servingSize = measure?.weight ?? 100.0
        self.servingUnit = measure?.label ?? "Gram"
        self.quantity = 1.0
        self.createdAt = Date()
    }
    
    // Giữ lại init mặc định nếu ông cần tạo thủ công
    init(id: String, name: String, image: String? = nil, calories: Double, protein: Double, carbs: Double, fats: Double, servingSize: Double, servingUnit: String, quantity: Double, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.imageUrl = image
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.quantity = quantity
        self.createdAt = createdAt
    }
}

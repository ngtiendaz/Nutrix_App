//
//  FoodAnalysisViewModel.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//

import SwiftUI
import Combine

@MainActor
class FoodAnalysisViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var isAnalyzing = false
    @Published var analyzedFood: Food?
    @Published var errorMessage: String?
    @Published var suggestions: [String] = []
    @Published var confidence: Double = 0.0
    @Published var weight: Double = 100.0 {
            didSet { updateAIAdvice() }
        }
        
        // Mặc định 1 khẩu phần
        @Published var quantity: Double = 1.0 {
            didSet { updateAIAdvice() }
        }
    
    // --- MỚI: Biến để lưu trữ lời khuyên từ AI ---
    @Published var advice: AIAdvice?
    @Published var mealDate: Date = Date() {
        didSet {
            updateMealType()
            updateAIAdvice()
        }
    }

    @Published private(set) var selectedMealType: MealType = .snack
    
    
    let selectedImage: UIImage
    private let visionService = GoogleVisionService()
    private let edamamService = EdamamService()
    private let authService: FirebaseAuthService
    
    private let dailyGoalMock = DailyGoal(userId: "daz123", date: Date(), targetCalories: 2000, targetProtein: 150, targetFat: 60, targetCarbs: 250, targetWater: 2.0)
    private let dailyNutritionMock = DailyNutrition(userId: "daz123", date: "2026-05-03", totalCalories: 1200, totalProtein: 80, totalCarbs: 150, totalFat: 40, totalWater: 1.0, totalBurned: 100.0)
    private let blacklist = ["food", "cuisine", "dish", "ingredient", "recipe", "tableware", "produce", "fast food"]
    
   
    
    init(image: UIImage, authService: FirebaseAuthService) {
            self.selectedImage = image
            self.authService = authService
            updateMealType()
        }
    private var currentUser: User? {
            return authService.currentUser
        }
    
    func updateMealType() {
        let hour = Calendar.current.component(.hour, from: mealDate)
        
        switch hour {
        case 5..<10: selectedMealType = .breakfast
        case 10..<14: selectedMealType = .lunch
        case 14..<18: selectedMealType = .afternoon
        case 18..<22: selectedMealType = .dinner
        case 22..<24: selectedMealType = .night
        default: selectedMealType = .snack
        }
    }
  
    func updateAIAdvice() {
        guard let food = analyzedFood, let user = currentUser else{
            self.advice = nil
            return
        }
        
        let scaledFood = Food(
            id: food.id,
            name: food.name,
            image: food.imageUrl,
            calories: valueFor(food.calories),
            protein: valueFor(food.protein),
            carbs: valueFor(food.carbs),
            fats: valueFor(food.fats),
            servingSize: weight,
            servingUnit: "grams",
            quantity: 1.0
        )
        self.advice = RecommendationService.shared.generateAdvice(
            currentFood: scaledFood,
            quantity: self.quantity,
            dailyNutrition: dailyNutritionMock,
            dailyGoal: dailyGoalMock,
            user: user,
            mealType: selectedMealType // 👈 thêm dòng này
        )
    }
    
    func startAnalysis() async {
        guard !isAnalyzing && analyzedFood == nil else { return }
        isAnalyzing = true
        errorMessage = nil
        self.advice = nil
        
        visionService.analyzeImage(uiImage: selectedImage) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let visionResponse):
                    let filteredLabels = (visionResponse.responses.first?.labelAnnotations ?? [])
                        .filter { label in
                            let desc = label.description.lowercased()
                            return !self.blacklist.contains(desc)
                        }
                        .sorted { $0.score > $1.score }
                    
                    if let topLabel = filteredLabels.first {
                        let topResult = topLabel.description
                        
                        self.confidence = Double(topLabel.score)
                        
                        self.suggestions = filteredLabels
                            .dropFirst()
                            .prefix(5)
                            .compactMap { $0.description }
                        
                        Task {
                            await self.getNutritionData(for: topResult)
                        }
                    } else {
                        self.handleError("Không thể nhận diện cụ thể món ăn này.")
                    }
                    
                case .failure(let error):
                    self.handleError("Lỗi kết nối Vision: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func reAnalyze(with foodName: String) async {
        isAnalyzing = true
        self.advice = nil // Reset advice cũ
        await getNutritionData(for: foodName)
    }
    
    private func getNutritionData(for foodName: String) async {
        isAnalyzing = true
        
        if let edamamData = await edamamService.fetchNutrition(for: foodName) {
            // KIỂM TRA: Nếu cả parsed và hints đều rỗng (như trường hợp "Electronic device")
            if edamamData.parsed.isEmpty && edamamData.hints.isEmpty {
                self.handleError("NutriX không nhận diện được đồ ăn trong ảnh này. Vui lòng thử lại với góc chụp rõ hơn nhé!")
                return
            }
            
            // Nếu có dữ liệu thì xử lý bình thường
            if let parsedItem = edamamData.parsed.first {
                self.analyzedFood = Food(from: parsedItem.food, measure: nil)
                self.isAnalyzing = false
                self.updateMealType()
                updateAIAdvice()
            }
            else if let hintItem = edamamData.hints.first {
                let firstMeasure = hintItem.measures.first
                self.analyzedFood = Food(from: hintItem.food, measure: firstMeasure)
                self.isAnalyzing = false
                self.updateMealType()
                updateAIAdvice()
            }
        } else {
            self.handleError("Lỗi kết nối máy chủ dinh dưỡng.")
        }
    }
    
    private func handleError(_ message: String) {
        self.errorMessage = message
        self.isAnalyzing = false
        self.analyzedFood = nil
        self.advice = nil
    }
    
    func valueFor(_ baseValue: Double) -> Double {
        return (baseValue / 100.0) * weight * quantity
    }
    
    func saveFood(completion: @escaping () -> Void) {
            guard let food = analyzedFood, let user = currentUser else {
                self.errorMessage = "Không tìm thấy thông tin người dùng."
                return
            }
            guard !isSaving else { return }
            
            isSaving = true
            
            FirebaseService.shared.uploadFoodImage(image: selectedImage) { result in
                switch result {
                case .success(let imageUrl):
                    let finalFood = Food(
                        id: food.id,
                        name: food.name,
                        image: imageUrl,
                        calories: self.valueFor(food.calories),
                        protein: self.valueFor(food.protein),
                        carbs: self.valueFor(food.carbs),
                        fats: self.valueFor(food.fats),
                        servingSize: self.weight,
                        servingUnit: "Gram",
                        quantity: self.quantity
                    )
                    
                    FirebaseService.shared.addFoodToMeal(
                        userId: user.userId, 
                        mealType: self.selectedMealType,
                        mealDate: self.mealDate,
                        food: finalFood
                    ) { result in
                        DispatchQueue.main.async {
                            self.isSaving = false
                            switch result {
                            case .success:
                                completion()
                            case .failure(let error):
                                self.errorMessage = error.localizedDescription
                            }
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isSaving = false
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    
}

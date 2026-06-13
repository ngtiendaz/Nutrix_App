//
//  FoodAnalysisViewModel.swift
//  Nutrix
//

import SwiftUI
import Combine
import GoogleGenerativeAI
import FirebaseAuth

@MainActor
class FoodAnalysisViewModel: ObservableObject {
    @Published var isSaving = false
    @Published var isAnalyzing = false
    @Published var analyzedFood: Food?
    @Published var errorMessage: String?
    @Published var suggestions: [String] = []
    @Published var confidence: Double = 0.0
    
    // Khối biến phục vụ hiệu ứng chạy chữ chatbot
    @Published var streamingTimingAnalysis: String = ""
    @Published var streamingMacroBalance: String = ""
    @Published var streamingPortionRecommendation: String = ""
    @Published var streamingActionTip: String = ""
    
    @Published var weight: Double = 100.0
    @Published var quantity: Double = 1.0
    
    enum AnalysisMode: String, CaseIterable {
        case visionEdamam = "Vision + Edamam"
        case gemini = "Gemini AI"
    }
    
    @Published var analysisMode: AnalysisMode = .gemini
    
    // 👉 CÁC BIẾN QUẢN LÝ CHỈNH SỬA DINH DƯỠNG
    let isEditableNutrition: Bool
    @Published var editableCalories: Double = 0.0
    @Published var editableProtein: Double = 0.0
    @Published var editableCarbs: Double = 0.0
    @Published var editableFats: Double = 0.0
    
    @Published var advice: AIAdvice?
    @Published var isAdviceLoading = false
    
    @Published var mealDate: Date = Date() {
        didSet {
            updateMealType()
        }
    }
    
    @Published private(set) var selectedMealType: MealType = .snack
    
    let selectedImage: UIImage?
    private let visionService = GoogleVisionService()
    private let edamamService = EdamamService()
    private let authService: FirebaseAuthService
    
    private let blacklist = ["food", "cuisine", "dish", "ingredient", "recipe", "tableware", "produce", "fast food"]
    private var typingCancellables = Set<AnyCancellable>()
    private var aiAdviceTask: Task<Void, Never>?
    
    private let model = GenerativeModel(
        name: "models/gemini-2.5-flash",
        apiKey: AppConfig.geminiAPIKey,
        requestOptions: RequestOptions(apiVersion: "v1")
    )
    
    // 👉 Init hỗ trợ cả 2 luồng: Nhận diện ảnh và Chọn từ danh sách
    init(food: Food? = nil, image: UIImage? = nil, authService: FirebaseAuthService, isEditableNutrition: Bool = false) {
        self.analyzedFood = food
        self.selectedImage = image
        self.authService = authService
        self.isEditableNutrition = isEditableNutrition
        
        // Nếu có sẵn thức ăn từ danh sách, set giá trị mặc định cho form
        if let preloadedFood = food {
            self.weight = preloadedFood.servingSize
            self.quantity = preloadedFood.quantity
            self.editableCalories = preloadedFood.calories
            self.editableProtein = preloadedFood.protein
            self.editableCarbs = preloadedFood.carbs
            self.editableFats = preloadedFood.fats
        }
        
        updateMealType()
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
    
    func startAnalysis() async {
        guard let imageToAnalyze = selectedImage, !isAnalyzing, analyzedFood == nil else { return }
        switch analysisMode {
        case .visionEdamam:
            await startVisionEdamamAnalysis()
        case .gemini:
            await startGeminiAnalysis()
        }
    }
    
    private func startVisionEdamamAnalysis() async {
        guard let imageToAnalyze = selectedImage else { return }
        isAnalyzing = true
        errorMessage = nil
        self.advice = nil
        cancelAILuongAndEffects()
        
        visionService.analyzeImage(uiImage: imageToAnalyze) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
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
                        self.suggestions = filteredLabels.dropFirst().prefix(5).compactMap { $0.description }
                        
                        Task { await self.getNutritionData(for: topResult) }
                    } else {
                        self.handleError("Không thể nhận diện cụ thể món ăn này.")
                    }
                case .failure(let error):
                    self.handleError("Lỗi kết nối Vision: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func startGeminiAnalysis() async {
        guard let imageToAnalyze = selectedImage else { return }
        isAnalyzing = true
        errorMessage = nil
        self.advice = nil
        cancelAILuongAndEffects()
        
        let prompt = """
        Bạn là chuyên gia dinh dưỡng. Hãy phân tích hình ảnh thức ăn này và trả về kết quả dưới định dạng JSON duy nhất, không chứa bất kỳ markdown, không có text thừa.
        Nếu không phải là thức ăn hoặc không thể nhận diện, hãy trả về JSON:
        {
           "error": "Không thể nhận diện cụ thể món ăn này."
        }
        
        Nếu là thức ăn, hãy trả về JSON:
        {
           "name": "Tên món ăn bằng tiếng Việt",
           "calories": (số Double, calo cho khẩu phần chuẩn),
           "protein": (số Double, gam protein cho khẩu phần chuẩn),
           "carbs": (số Double, gam carbs cho khẩu phần chuẩn),
           "fats": (số Double, gam chất béo cho khẩu phần chuẩn),
           "servingSize": (số Double, trọng lượng khẩu phần chuẩn tính bằng gam, ví dụ 100.0),
           "servingUnit": "Gram"
        }
        """
        
        do {
            let response = try await self.model.generateContent(prompt, imageToAnalyze)
            guard var rawString = response.text else { throw NSError(domain: "EmptyResponse", code: 0) }
            
            rawString = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
            if rawString.hasPrefix("```json") { rawString = String(rawString.dropFirst(7)) }
            else if rawString.hasPrefix("```") { rawString = String(rawString.dropFirst(3)) }
            if rawString.hasSuffix("```") { rawString = String(rawString.dropLast(3)) }
            rawString = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let rawData = rawString.data(using: .utf8) else { throw NSError(domain: "DataConversionError", code: 0) }
            
            if let errorDict = try? JSONDecoder().decode([String: String].self, from: rawData), let errorMsg = errorDict["error"] {
                await MainActor.run {
                    self.handleError(errorMsg)
                }
                return
            }
            
            struct GeminiFoodResult: Codable {
                let name: String
                let calories: Double
                let protein: Double
                let carbs: Double
                let fats: Double
                let servingSize: Double
                let servingUnit: String
            }
            
            let result = try JSONDecoder().decode(GeminiFoodResult.self, from: rawData)
            
            await MainActor.run {
                let foodId = UUID().uuidString
                let food = Food(
                    id: foodId,
                    name: result.name,
                    image: nil,
                    calories: result.calories,
                    protein: result.protein,
                    carbs: result.carbs,
                    fats: result.fats,
                    servingSize: result.servingSize,
                    servingUnit: result.servingUnit,
                    quantity: 1.0
                )
                self.analyzedFood = food
                self.editableCalories = food.calories
                self.editableProtein = food.protein
                self.editableCarbs = food.carbs
                self.editableFats = food.fats
                
                self.isAnalyzing = false
                self.confidence = 0
                self.suggestions = []
                
                self.updateMealType()
                self.updateAIAdvice()
            }
        } catch {
            await MainActor.run {
                self.handleError("Lỗi kết nối Gemini: \(error.localizedDescription)")
            }
        }
    }
    
    func reAnalyze(with foodName: String) async {
        isAnalyzing = true
        self.advice = nil
        cancelAILuongAndEffects()
        await getNutritionData(for: foodName)
    }
    
    private func getNutritionData(for foodName: String) async {
        isAnalyzing = true
        if let edamamData = await edamamService.fetchNutrition(for: foodName) {
            if edamamData.parsed.isEmpty && edamamData.hints.isEmpty {
                self.handleError("NutriX không nhận diện được đồ ăn trong ảnh này. Vui lòng thử lại với góc chụp rõ hơn nhé!")
                return
            }
            
            if let parsedItem = edamamData.parsed.first {
                self.analyzedFood = Food(from: parsedItem.food, measure: nil)
            } else if let hintItem = edamamData.hints.first {
                let firstMeasure = hintItem.measures.first
                self.analyzedFood = Food(from: hintItem.food, measure: firstMeasure)
            }
            
            // Cập nhật lại các biến editable nếu vừa nhận diện xong
            if let food = self.analyzedFood {
                self.editableCalories = food.calories
                self.editableProtein = food.protein
                self.editableCarbs = food.carbs
                self.editableFats = food.fats
            }
            
            self.isAnalyzing = false
            self.updateMealType()
            self.updateAIAdvice()
            
        } else {
            self.handleError("Lỗi kết nối máy chủ dinh dưỡng.")
        }
    }
    
    private func handleError(_ message: String) {
        self.errorMessage = message
        self.isAnalyzing = false
        self.analyzedFood = nil
        self.advice = nil
        cancelAILuongAndEffects()
    }
    
    // 👉 LOGIC TÍNH TOÁN HIỂN THỊ (Hỗ trợ cả edit và base)
    private func calculateValue(baseMacro: Double) -> Double {
        guard let food = analyzedFood else { return 0 }
        let baseServing = food.servingSize != 0 ? food.servingSize : 100.0
        let baseQuantity = food.quantity != 0 ? food.quantity : 1.0
        
        let weightRatio = weight / baseServing
        let quantityRatio = quantity / baseQuantity
        
        return baseMacro * weightRatio * quantityRatio
    }
    
    // Các biến dùng cho UI và lưu trữ cuối cùng
    var displayCalories: Double { calculateValue(baseMacro: isEditableNutrition ? editableCalories : (analyzedFood?.calories ?? 0)) }
    var displayProtein: Double { calculateValue(baseMacro: isEditableNutrition ? editableProtein : (analyzedFood?.protein ?? 0)) }
    var displayCarbs: Double { calculateValue(baseMacro: isEditableNutrition ? editableCarbs : (analyzedFood?.carbs ?? 0)) }
    var displayFats: Double { calculateValue(baseMacro: isEditableNutrition ? editableFats : (analyzedFood?.fats ?? 0)) }
    
    func updateAIAdvice() {
        guard let food = analyzedFood, let userId = Auth.auth().currentUser?.uid else {
            self.advice = nil
            return
        }
        
        self.isAdviceLoading = true
        aiAdviceTask?.cancel()
        
        aiAdviceTask = Task {
            let currentHour = Calendar.current.component(.hour, from: self.mealDate)
            
            FirebaseService.shared.fetchAIContextData(userId: userId, date: mealDate) { [weak self] result in
                guard let self = self else { return }
                if Task.isCancelled { return }
                
                Task {
                    var planTargetCal = 2000.0, planPro = 150.0, planCarb = 200.0, planFat = 70.0
                    var currentEatenCal = 0.0, currentEatenPro = 0.0, currentEatenCarb = 0.0, currentEatenFat = 0.0, currentBurned = 0.0
                    var calculatedGoal = "Duy trì sức khỏe"
                    
                    if case .success(let (plan, summary)) = result {
                        if let plan = plan {
                            planTargetCal = plan.dailyCalories
                            planPro = plan.protein
                            planCarb = plan.carbs
                            planFat = plan.fat
                            
                            let currentW = plan.currentWeight ?? 0.0
                            let targetW = plan.targetWeight ?? 0.0
                            if targetW > currentW && currentW > 0 {
                                calculatedGoal = "Tăng cân"
                            } else if targetW < currentW && targetW > 0 {
                                calculatedGoal = "Giảm cân"
                            } else {
                                calculatedGoal = "Duy trì cân nặng"
                            }
                        }
                        if let summary = summary {
                            currentEatenCal = summary.intakeCalories
                            currentEatenPro = summary.intakeProtein
                            currentEatenCarb = summary.intakeCarbs
                            currentEatenFat = summary.intakeFats
                            currentBurned = summary.burnedCalories
                        }
                    }
                    
                    let prompt = """
                    Bạn là chuyên gia dinh dưỡng. Trả về CHỈ 1 chuỗi JSON (không markdown, không text thừa). Dùng tiếng Việt: "Đạm", "Tinh bột", "Chất béo". Dùng \\n để xuống dòng, KHÔNG dùng Enter vật lý.

                    - Chiến lược: \(calculatedGoal)
                    - Thời điểm: \(currentHour)h (\(self.selectedMealType.displayName))
                    - Mục tiêu ngày: \(Int(planTargetCal)) Kcal | Đã nạp: \(Int(currentEatenCal)) Kcal
                    - Phần ăn này (\(Int(self.weight * self.quantity))g): \(Int(self.displayCalories)) Kcal | Đạm: \(Int(self.displayProtein))g | Tinh bột: \(Int(self.displayCarbs))g | Béo: \(Int(self.displayFats))g

                    Định dạng JSON BẮT BUỘC:
                    {
                      "status": "success" hoặc "warning" hoặc "danger" hoặc "info",
                      "title": "Bữa ăn hợp lý" hoặc "Cần bổ sung thêm" hoặc "Không nên ăn" hoặc "Cần giảm khẩu phần",
                      "timingAnalysis": "Đánh giá ăn lúc \(currentHour)h (1-2 câu).",
                      "macroBalance": "Đánh giá thiếu/thừa lũy kế (1-2 câu).",
                      "portionRecommendation": "Gợi ý tăng/giảm số gram món này (1-2 câu).",
                      "actionTip": "Gợi ý món phụ ăn kèm hoặc món đổi thay thế (1-2 câu)."
                    }
                    """
                    
                    if Task.isCancelled { return }
                    
                    do {
                        let response = try await self.model.generateContent(prompt)
                        guard var rawString = response.text else { throw NSError(domain: "EmptyResponse", code: 0) }
                        
                        // Làm sạch JSON cực mạnh để tránh lỗi Decoder
                        rawString = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
                        if rawString.hasPrefix("```json") { rawString = String(rawString.dropFirst(7)) }
                        else if rawString.hasPrefix("```") { rawString = String(rawString.dropFirst(3)) }
                        if rawString.hasSuffix("```") { rawString = String(rawString.dropLast(3)) }
                        rawString = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        print("🤖 [AI RAW RESPONSE]:\n\(rawString)") // In ra để Debug
                        
                        guard let rawData = rawString.data(using: .utf8) else { throw NSError(domain: "DataConversionError", code: 0) }
                        let decodedAdvice = try JSONDecoder().decode(AIAdvice.self, from: rawData)
                        
                        if Task.isCancelled { return }
                        
                        await MainActor.run {
                            self.clearStreamingStrings()
                            self.advice = decodedAdvice
                            self.isAdviceLoading = false
                            
                            self.startTypingEffect(target: decodedAdvice.timingAnalysis, keyPath: \.streamingTimingAnalysis)
                            self.startTypingEffect(target: decodedAdvice.macroBalance, keyPath: \.streamingMacroBalance)
                            self.startTypingEffect(target: decodedAdvice.portionRecommendation, keyPath: \.streamingPortionRecommendation)
                            self.startTypingEffect(target: decodedAdvice.actionTip, keyPath: \.streamingActionTip)
                        }
                    } catch {
                        if Task.isCancelled { return }
                        
                        print("❌ [AI PARSING ERROR]: \(error.localizedDescription)") // Bắt lỗi để biết tại sao nhảy vào Catch
                        
                        let isOverCalo = (currentEatenCal + self.displayCalories) > planTargetCal
                        await MainActor.run {
                            self.clearStreamingStrings()
                            let fallbackAdvice = AIAdvice(
                                status: isOverCalo ? "danger" : "warning",
                                title: isOverCalo ? "Cần giảm khẩu phần" : "Cần bổ sung thêm",
                                timingAnalysis: "Ăn vào lúc \(currentHour)h cần được kiểm soát tốt định lượng nhằm tránh gây quá tải hệ tiêu hóa.",
                                macroBalance: "Năng lượng ngày gần đạt giới hạn. Hãy chú ý cân bằng Đạm và Tinh bột.",
                                portionRecommendation: "Khuyến nghị giữ năng lượng bữa lẻ ở mức 25-35% calo ngày.",
                                actionTip: "Cân nhắc vận động nhẹ 30 phút cuối ngày hoặc bổ sung thêm rau xanh."
                            )
                            self.advice = fallbackAdvice
                            self.isAdviceLoading = false
                            
                            self.startTypingEffect(target: fallbackAdvice.timingAnalysis, keyPath: \.streamingTimingAnalysis)
                            self.startTypingEffect(target: fallbackAdvice.macroBalance, keyPath: \.streamingMacroBalance)
                            self.startTypingEffect(target: fallbackAdvice.portionRecommendation, keyPath: \.streamingPortionRecommendation)
                            self.startTypingEffect(target: fallbackAdvice.actionTip, keyPath: \.streamingActionTip)
                        }
                    }
                }
            }
        }
    }
    
    private func startTypingEffect(target: String, keyPath: ReferenceWritableKeyPath<FoodAnalysisViewModel, String>) {
        let characters = Array(target)
        var currentIndex = 0
        var cancellableRef: AnyCancellable?
        
        cancellableRef = Timer.publish(every: 0.010, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else {
                    cancellableRef?.cancel()
                    return
                }
                if currentIndex < characters.count {
                    self[keyPath: keyPath].append(characters[currentIndex])
                    currentIndex += 1
                } else {
                    cancellableRef?.cancel()
                }
            }
        if let subscription = cancellableRef {
            self.typingCancellables.insert(subscription)
        }
    }
    
    private func cancelAILuongAndEffects() {
        aiAdviceTask?.cancel()
        aiAdviceTask = nil
        self.typingCancellables.forEach { $0.cancel() }
        self.typingCancellables.removeAll()
    }
    
    private func clearStreamingStrings() {
        self.typingCancellables.forEach { $0.cancel() }
        self.typingCancellables.removeAll()
        self.streamingTimingAnalysis = ""
        self.streamingMacroBalance = ""
        self.streamingPortionRecommendation = ""
        self.streamingActionTip = ""
    }
    
    func validateInputs() -> String? {
        if isEditableNutrition {
            if editableCalories < 0 {
                return "Lượng Calo không được nhỏ hơn 0"
            }
            if editableCarbs < 0 {
                return "Tinh bột không được nhỏ hơn 0"
            }
            if editableProtein < 0 {
                return "Chất đạm không được nhỏ hơn 0"
            }
            if editableFats < 0 {
                return "Chất béo không được nhỏ hơn 0"
            }
        }
        
        if weight <= 0 {
            return "Khối lượng (Grams) phải lớn hơn 0"
        }
        if quantity <= 0 {
            return "Số lượng phải lớn hơn 0"
        }
        
        return nil
    }
    
    func saveFood(completion: @escaping () -> Void) {
        guard let food = analyzedFood, let userId = Auth.auth().currentUser?.uid, !isSaving else {
            self.errorMessage = "Không tìm thấy dữ liệu thức ăn hoặc bạn chưa đăng nhập."
            return
        }
        
        isSaving = true
        cancelAILuongAndEffects()
        self.isAdviceLoading = false
        
        if let imageToUpload = selectedImage {
            FirebaseService.shared.uploadFoodImage(image: imageToUpload) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let imageUrl):
                        self.processFinalSave(food: food, userId: userId, imageUrl: imageUrl, completion: completion)
                    case .failure(let error):
                        self.isSaving = false
                        self.errorMessage = "Lỗi tải ảnh: \(error.localizedDescription)"
                    }
                }
            }
        } else {
            // Lấy nguyên imageUrl có sẵn
            processFinalSave(food: food, userId: userId, imageUrl: food.imageUrl, completion: completion)
        }
    }
    
    private func processFinalSave(food: Food, userId: String, imageUrl: String?, completion: @escaping () -> Void) {
        let finalFood = Food(
            id: food.id,
            name: food.name,
            image: imageUrl,
            calories: self.displayCalories,
            protein: self.displayProtein,
            carbs: self.displayCarbs,
            fats: self.displayFats,
            servingSize: self.weight,
            servingUnit: food.servingUnit,
            quantity: self.quantity
        )
        
        FirebaseService.shared.addFoodToMeal(
            userId: userId,
            mealType: self.selectedMealType,
            mealDate: self.mealDate,
            food: finalFood
        ) { [weak self] mealResult in
            DispatchQueue.main.async {
                self?.isSaving = false
                switch mealResult {
                case .success:
                    completion()
                case .failure(let error):
                    self?.errorMessage = "Lỗi Firestore: \(error.localizedDescription)"
                }
            }
        }
    }
}

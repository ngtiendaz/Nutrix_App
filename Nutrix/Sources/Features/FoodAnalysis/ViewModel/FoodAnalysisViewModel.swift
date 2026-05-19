//
//  FoodAnalysisViewModel.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//

import SwiftUI
import Combine
import GoogleGenerativeAI

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
    
    // ĐÃ FIX: Xóa bỏ didSet gọi AI ở đây để tránh spam API khi nhập số lượng
    @Published var weight: Double = 100.0
    @Published var quantity: Double = 1.0
    
    @Published var advice: AIAdvice?
    @Published var isAdviceLoading = false
    
    // ĐÃ FIX: Chỉ cập nhật loại bữa ăn, không gọi AI
    @Published var mealDate: Date = Date() {
        didSet {
            updateMealType()
        }
    }
    
    @Published private(set) var selectedMealType: MealType = .snack
    
    let selectedImage: UIImage
    private let visionService = GoogleVisionService()
    private let edamamService = EdamamService()
    private let authService: FirebaseAuthService
    
    private let blacklist = ["food", "cuisine", "dish", "ingredient", "recipe", "tableware", "produce", "fast food"]
    private var typingCancellables = Set<AnyCancellable>()
    
    private let model = GenerativeModel(
        name: "models/gemini-2.5-flash",
        apiKey: AppConfig.geminiAPIKey,
        requestOptions: RequestOptions(apiVersion: "v1")
    )
    
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
    
    func startAnalysis() async {
        guard !isAnalyzing && analyzedFood == nil else { return }
        isAnalyzing = true
        errorMessage = nil
        self.advice = nil
        
        visionService.analyzeImage(uiImage: selectedImage) { [weak self] result in
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
        self.advice = nil
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
                self.isAnalyzing = false
                self.updateMealType()
                self.updateAIAdvice()
            }
            else if let hintItem = edamamData.hints.first {
                let firstMeasure = hintItem.measures.first
                self.analyzedFood = Food(from: hintItem.food, measure: firstMeasure)
                self.isAnalyzing = false
                self.updateMealType()
                self.updateAIAdvice()
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
    
    func updateAIAdvice() {
        guard let food = analyzedFood, let user = currentUser else {
            self.advice = nil
            return
        }
        
        let currentMealCalories = valueFor(food.calories)
        let currentMealProtein = valueFor(food.protein)
        let currentMealCarbs = valueFor(food.carbs)
        let currentMealFats = valueFor(food.fats)
        let currentMealWeight = weight * quantity
        
        self.isAdviceLoading = true
        
        FirebaseService.shared.fetchAIContextData(userId: user.userId, date: mealDate) { [weak self] result in
            guard let self = self else { return }
            
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
                            calculatedGoal = "Tăng cân (Mục tiêu: \(targetW)kg từ \(currentW)kg)"
                        } else if targetW < currentW && targetW > 0 {
                            calculatedGoal = "Giảm cân (Mục tiêu: \(targetW)kg từ \(currentW)kg)"
                        } else {
                            calculatedGoal = "Duy trì cân nặng (\(currentW)kg)"
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
                
                let currentHour = Calendar.current.component(.hour, from: self.mealDate)
                
                print("""
                ================ [NUTRIX AI DEBUG CONTEXT] ===============
                • Người dùng: Daz | Chiến lược Plan: \(calculatedGoal)
                • Thời gian chọn ăn: Bữa \(self.selectedMealType.displayName) lúc \(currentHour)h
                • LỘ TRÌNH MỤC TIÊU NGÀY: Calo: \(Int(planTargetCal))kcal | Đạm: \(Int(planPro))g | Tinh bột: \(Int(planCarb))g | Béo: \(Int(planFat))g
                • THỰC TẾ TRƯỚC BỮA ĂN:   Đã nạp: \(Int(currentEatenCal))kcal | Đạm: \(Int(currentEatenPro))g | Tinh bột: \(Int(currentEatenCarb))g | Béo: \(Int(currentEatenFat))g
                • TIÊU HAO ĐÃ ĐỐT (TẬP): \(Int(currentBurned))kcal
                • MÓN ĂN HIỆN TẠI ĐANG XÉT: \(food.name)
                  - Khối lượng tính toán: \(Int(currentMealWeight))g (Trọng lượng nền: \(Int(self.weight))g x Slg: \(self.quantity))
                  - Dinh dưỡng bữa này: Calo: \(Int(currentMealCalories))kcal | Đạm: \(Int(currentMealProtein))g | Tinh bột: \(Int(currentMealCarbs))g | Béo: \(Int(currentMealFats))g
                ===========================================================
                """)
                
                let prompt = """
                Bạn là một chuyên gia phân tích dinh dưỡng lâm sàng tích hợp trong ứng dụng Nutrix. Hãy đưa ra lời khuyên định lượng siêu ngắn gọn cho người dùng tên Daz dựa trên số liệu thực tế dưới đây. 
                Tuyệt đối không viết dài dòng, bỏ qua hoàn toàn các lời chào hỏi và văn phong sáo rỗng. Đi thẳng vào số liệu phân tích cốt lõi.

                [QUY TẮC NGÔN NGỮ BẮT BUỘC]
                - KHÔNG ĐƯỢC DÙNG từ tiếng Anh hoặc từ viết tắt như: Protein, Carbs, Fats, Macro, Macronutrients.
                - BẮT BUỘC DÙNG các từ tiếng Việt chuẩn: Đạm, Tinh bột, Chất béo.

                [BỐI CẢNH LỘ TRÌNH CỦA DAZ]
                - Chiến lược từ lộ trình: \(calculatedGoal)
                - Thời điểm ăn: Lúc \(currentHour) giờ (Bữa \(self.selectedMealType.displayName))
                
                [CHỈ SỐ TOÀN NGÀY CỦA DAZ]
                - Mục tiêu lộ trình ngày: Nạp \(Int(planTargetCal)) Kcal | Đạm: \(Int(planPro))g | Tinh bột: \(Int(planCarb))g | Chất béo: \(Int(planFat))g
                - Đã nạp trước bữa này: \(Int(currentEatenCal)) Kcal | Đạm: \(Int(currentEatenPro))g | Tinh bột: \(Int(currentEatenCarb))g | Chất béo: \(Int(currentEatenFat))g
                - Năng lượng đã đốt qua tập luyện: \(Int(currentBurned)) Kcal

                [THÔNG TIN PHẦN ĂN HIỆN TẠI]
                - Món ăn: \(food.name) | Khối lượng dự định: \(Int(currentMealWeight))g
                - Dinh dưỡng phần này mang lại: \(Int(currentMealCalories)) Kcal | Đạm: \(Int(currentMealProtein))g | Tinh bột: \(Int(currentMealCarbs))g | Chất béo: \(Int(currentMealFats))g

                Hãy thực hiện phân tích theo đúng 4 tiêu chí bắt buộc với văn phong cực kỳ cô đọng (mỗi trường tối đa 1-2 câu ngắn):
                1. THỜI ĐIỂM SINH HỌC: Đánh giá ăn lúc \(currentHour)h có phù hợp đồng hồ sinh học không.
                2. TRẠNG THÁI DINH DƯỠNG LŨY KẾ: Tính toán nhanh cơ thể Daz đang thừa hay thiếu Đạm, Tinh bột, Chất béo lũy kế đến hiện tại so với mục tiêu ngày. Món này bù đắp hay làm dư thừa thêm chất nào?
                3. QUY TẮC PHÂN PHỐI NĂNG LƯỢNG THEO BỮA (ĐIỀU CHỈNH KHẨU PHẦN): Một bữa chính nên chiếm 25-35% calo ngày. Dựa trên năng lượng món hiện tại, hãy gợi ý cụ thể Daz nên điều chỉnh tăng hoặc giảm khối lượng món ăn này từ \(Int(currentMealWeight))g lên hoặc xuống chính xác bao nhiêu gram (hoặc đổi số lượng thành bao nhiêu phần) để vừa vặn với một bữa chính tiêu chuẩn.
                4. GIẢI PHÁP ĐỊNH LƯỢNG CỤ THỂ (DỰ PHÒNG HOẶC ĐỔI MÓN): Đưa ra hướng dẫn hành động nếu Daz giữ nguyên khối lượng hiện tại và KHÔNG tăng khẩu phần món này. Hãy gợi ý rõ Daz cần ăn thêm các món ăn phụ cụ thể nào kèm theo (ghi rõ khối lượng gram) để bù đắp chất đang thiếu hụt, HOẶC có thể đổi sang món ăn tương đương nào khác phù hợp hơn cho chiến lược mục tiêu.

                Yêu cầu định dạng đầu ra:
                Trả về duy nhất một chuỗi JSON Object sạch, không bọc markdown (```json). Ghi bằng tiếng Việt, gọi tên Daz. Các câu văn phải ngắn gọn, đi thẳng vào bản chất:
                CRITICAL: Các giá trị bên trong JSON KHÔNG ĐƯỢC chứa ký tự xuống dòng vật lý (Raw Newline). Nếu muốn xuống dòng phân tách các gạch đầu dòng trong trường "actionTip", bắt buộc phải sử dụng ký tự chữ viết liền '\\\\n' (ví dụ: "Ý một.\\\\n- Ý hai.").
                {
                  "status": "success" hoặc "warning" hoặc "danger" hoặc "info",
                  "title": "CHỈ chọn 1 trong các cụm từ cố định sau: 'Bữa ăn hợp lý' hoặc 'Cần bổ sung thêm' hoặc 'Không nên ăn' hoặc 'Cần giảm khẩu phần' tùy theo trạng thái ăn.",
                  "timingAnalysis": "Phân tích khung giờ ăn ngắn gọn dưới 2 câu.",
                  "macroBalance": "Phân tích thiếu thừa Đạm, Tinh bột, Chất béo lũy kế ngày ngắn gọn dưới 2 câu.",
                  "portionRecommendation": "Gợi ý tăng hoặc giảm khối lượng món ăn hiện tại lên bao nhiêu gram hoặc bao nhiêu phần để đạt chuẩn năng lượng bữa ăn (1-2 câu).",
                  "actionTip": "Gợi ý các thực phẩm phụ kèm khối lượng gram cụ thể nếu giữ nguyên lượng món ăn hiện tại, hoặc gợi ý một món ăn tương đương khác thay thế hoàn toàn."
                }
                """
                
                do {
                    let response = try await self.model.generateContent(prompt)
                    
                    guard var rawString = response.text else {
                        throw NSError(domain: "EmptyResponse", code: 0)
                    }
                    
                    print("[NUTRIX AI RAW RESPONSE]:\n\(rawString)")
                    
                    if rawString.hasPrefix("```json") {
                        rawString = String(rawString.dropFirst(7))
                    } else if rawString.hasPrefix("```") {
                        rawString = String(rawString.dropFirst(3))
                    }
                    if rawString.hasSuffix("```") {
                        rawString = String(rawString.dropLast(3))
                    }
                    rawString = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard let rawData = rawString.data(using: .utf8) else {
                        throw NSError(domain: "ConversionError", code: 0)
                    }
                    
                    let decoder = JSONDecoder()
                    let decodedAdvice = try decoder.decode(AIAdvice.self, from: rawData)
                    
                    await MainActor.run {
                        self.typingCancellables.forEach { $0.cancel() }
                        self.typingCancellables.removeAll()
                        
                        // ĐÃ FIX: Chắc chắn phải làm sạch chuỗi cũ trước khi chạy hiệu ứng mới
                        self.streamingTimingAnalysis = ""
                        self.streamingMacroBalance = ""
                        self.streamingPortionRecommendation = ""
                        self.streamingActionTip = ""
                        
                        self.advice = decodedAdvice
                        self.isAdviceLoading = false
                        
                        self.startTypingEffect(target: decodedAdvice.timingAnalysis, keyPath: \.streamingTimingAnalysis)
                        self.startTypingEffect(target: decodedAdvice.macroBalance, keyPath: \.streamingMacroBalance)
                        self.startTypingEffect(target: decodedAdvice.portionRecommendation, keyPath: \.streamingPortionRecommendation)
                        self.startTypingEffect(target: decodedAdvice.actionTip, keyPath: \.streamingActionTip)
                    }
                    
                } catch {
                    print("[NUTRIX AI ERROR]: Lỗi parse cấu trúc dữ liệu JSON hoặc lỗi kết nối mạng: \(error)")
                    
                    let isOverCalo = (currentEatenCal + currentMealCalories) > planTargetCal
                    await MainActor.run {
                        self.typingCancellables.forEach { $0.cancel() }
                        self.typingCancellables.removeAll()
                        
                        // ĐÃ FIX LỖI Ở KHỐI CATCH: Phải xóa chuỗi cũ đi để nó không bị ghi đè lặp lại vô tận
                        self.streamingTimingAnalysis = ""
                        self.streamingMacroBalance = ""
                        self.streamingPortionRecommendation = ""
                        self.streamingActionTip = ""
                        
                        let fallbackAdvice = AIAdvice(
                            status: isOverCalo ? "danger" : "warning",
                            title: isOverCalo ? "Cần giảm khẩu phần" : "Cần bổ sung thêm",
                            timingAnalysis: "Ăn vào lúc \(currentHour)h cần được kiểm soát tốt định lượng nhằm tránh gây quá tải lên hệ tiêu hóa trước giấc ngủ.",
                            macroBalance: "Năng lượng ngày sắp chạm giới hạn lộ trình. Cần cân đối kỹ lượng Đạm và Tinh bột đã nạp ở các bữa trước đó.",
                            portionRecommendation: "Khuyến nghị Daz giữ năng lượng bữa lẻ ở mức 25-35% calo ngày, nên dùng khoảng \(Int(currentMealWeight * 0.7))g thực phẩm.",
                            actionTip: "Hãy cân nhắc đi bộ thể thao 30-45 phút vào cuối ngày nếu lượng calo bữa này vượt ngưỡng, hoặc bổ sung thêm 100g ức gà luộc nếu thiếu Đạm."
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
        private func startTypingEffect(target: String, keyPath: ReferenceWritableKeyPath<FoodAnalysisViewModel, String>) {
            let characters = Array(target)
            var currentIndex = 0
            
            // Tạo biến tham chiếu để Timer có thể tự gọi hàm cancel() lên chính nó
            var cancellableRef: AnyCancellable?
            
            cancellableRef = Timer.publish(every: 0.010, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in // Dấu "_" thay thế cho Date vì ta không dùng tới thời gian
                    guard let self = self else {
                        cancellableRef?.cancel()
                        return
                    }
                    
                    if currentIndex < characters.count {
                        self[keyPath: keyPath].append(characters[currentIndex])
                        currentIndex += 1
                    } else {
                        // Khi đã gõ xong chuỗi, tự động ngắt kết nối Timer để tiết kiệm CPU
                        cancellableRef?.cancel()
                    }
                }
            
            // Lưu tham chiếu vào Set để có thể chủ động xóa nếu Daz đổi ảnh/món ăn lúc chữ đang chạy
            if let subscription = cancellableRef {
                self.typingCancellables.insert(subscription)
            }
        }
    
    func saveFood(completion: @escaping () -> Void) {
        guard let food = analyzedFood, let user = currentUser else {
            self.errorMessage = "Không tìm thấy thông tin người dùng."
            return
        }
        guard !isSaving else { return }
        isSaving = true
        
        FirebaseService.shared.uploadFoodImage(image: selectedImage) { [weak self] result in
            guard let self = self else { return }
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
                ) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
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

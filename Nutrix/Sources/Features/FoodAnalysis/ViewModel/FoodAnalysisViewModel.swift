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
    
    @Published var weight: Double = 100.0
    @Published var quantity: Double = 1.0
    
    @Published var advice: AIAdvice?
    @Published var isAdviceLoading = false
    
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
    
    // 👉 Quản lý luồng gọi AI để có thể hủy bỏ khi bấm Lưu
    private var aiAdviceTask: Task<Void, Never>?
    
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
        cancelAILuongAndEffects() // Đảm bảo dọn dẹp luồng cũ
        
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
            
            // ✅ TÁCH LUỒNG: Trả kết quả dinh dưỡng thô về UI trước để hiển thị biểu đồ/hình ảnh lập tức
            if let parsedItem = edamamData.parsed.first {
                self.analyzedFood = Food(from: parsedItem.food, measure: nil)
            } else if let hintItem = edamamData.hints.first {
                let firstMeasure = hintItem.measures.first
                self.analyzedFood = Food(from: hintItem.food, measure: firstMeasure)
            }
            
            self.isAnalyzing = false
            self.updateMealType()
            
            // ✅ Đẩy việc phân tích lời khuyên AI sang luồng nền song song, không chặn luồng chính
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
        
        // Hủy task cũ nếu có trước khi tạo task mới
        aiAdviceTask?.cancel()
        
        // 👉 Khởi tạo luồng Task chạy song song phân tích AI
        aiAdviceTask = Task {
            let currentHour = Calendar.current.component(.hour, from: self.mealDate)
            
            // Bọc việc gọi Firebase và Gemini trong một khối đùm bọc an toàn
            FirebaseService.shared.fetchAIContextData(userId: user.userId, date: mealDate) { [weak self] result in
                guard let self = self else { return }
                
                // Kiểm tra xem Task này có bị hủy giữa chừng (do người dùng bấm Lưu) không
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
                    
                    if Task.isCancelled { return }
                    
                    do {
                        let response = try await self.model.generateContent(prompt)
                        guard var rawString = response.text else { throw NSError(domain: "EmptyResponse", code: 0) }
                        
                        if rawString.hasPrefix("```json") { rawString = String(rawString.dropFirst(7)) }
                        else if rawString.hasPrefix("```") { rawString = String(rawString.dropFirst(3)) }
                        if rawString.hasSuffix("```") { rawString = String(rawString.dropLast(3)) }
                        rawString = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard let rawData = rawString.data(using: .utf8) else { throw NSError(domain: "ConversionError", code: 0) }
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
                        print("[NUTRIX AI ERROR]: Lỗi kết nối hoặc cấu trúc: \(error)")
                        
                        let isOverCalo = (currentEatenCal + currentMealCalories) > planTargetCal
                        await MainActor.run {
                            self.clearStreamingStrings()
                            let fallbackAdvice = AIAdvice(
                                status: isOverCalo ? "danger" : "warning",
                                title: isOverCalo ? "Cần giảm khẩu phần" : "Cần bổ sung thêm",
                                timingAnalysis: "Ăn vào lúc \(currentHour)h cần được kiểm soát tốt định lượng nhằm tránh gây quá tải hệ tiêu hóa.",
                                macroBalance: "Năng lượng ngày gần đạt giới hạn. Hãy chú ý cân bằng Đạm và Tinh bột.",
                                portionRecommendation: "Khuyến nghị Daz giữ năng lượng bữa lẻ ở mức 25-35% calo ngày (~ \(Int(currentMealWeight * 0.7))g).",
                                actionTip: "Cân nhắc vận động nhẹ 30 phút cuối ngày hoặc bổ sung thêm đạm sạch từ ức gà."
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
    
    // 👉 Hàm dọn dẹp các luồng chạy chữ và luồng xử lý AI background
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
    
    func saveFood(completion: @escaping () -> Void) {
        print("🎬 [DEBUG SAVE] Bắt đầu gọi hàm saveFood()...")
        
        guard let food = analyzedFood else {
            self.errorMessage = "Lỗi: Không tìm thấy thông tin món ăn đã phân tích."
            print("❌ [DEBUG SAVE] Thất bại: analyzedFood bị nil.")
            return
        }
        
        guard let user = currentUser else {
            self.errorMessage = "Lỗi: Không tìm thấy thông tin người dùng."
            print("❌ [DEBUG SAVE] Thất bại: currentUser bị nil.")
            return
        }
        
        guard !isSaving else {
            print("⚠️ [DEBUG SAVE] Trùng lặp: Nút lưu đang xử lý, chặn bấm liên tục.")
            return
        }
        
        // Bắt đầu trạng thái lưu
        isSaving = true
        
        // 🚨 Ngắt luồng phân tích AI của Gemini ngay lập tức
        cancelAILuongAndEffects()
        self.isAdviceLoading = false
        print("🛑 [DEBUG SAVE] Đã hủy tác vụ Gemini AI và dọn dẹp hiệu ứng chữ thành công.")
        
        let currentWeight = self.weight
        let currentQuantity = self.quantity
        let calculatedCalories = self.valueFor(food.calories)
        let calculatedProtein = self.valueFor(food.protein)
        let calculatedCarbs = self.valueFor(food.carbs)
        let calculatedFats = self.valueFor(food.fats)
        
        print("📸 [DEBUG SAVE] Bắt đầu upload ảnh lên Firebase Storage...")
        
        FirebaseService.shared.uploadFoodImage(image: selectedImage) { [weak self] result in
            // Tách luồng: Đưa toàn bộ xử lý kết quả về Main Thread để an toàn cho UI và ViewModel
            DispatchQueue.main.async {
                guard let self = self else {
                    print("🚨 [DEBUG SAVE] Cảnh báo: ViewModel đã bị giải phóng (deinit) trước khi upload ảnh xong. Callback kết thúc.")
                    return
                }
                
                switch result {
                case .success(let imageUrl):
                    print("✅ [DEBUG SAVE] Upload ảnh thành công. URL: \(imageUrl)")
                    print("📦 [DEBUG SAVE] Đang khởi tạo Object Food final với định lượng thực tế...")
                    
                    let finalFood = Food(
                        id: food.id,
                        name: food.name,
                        image: imageUrl,
                        calories: calculatedCalories,
                        protein: calculatedProtein,
                        carbs: calculatedCarbs,
                        fats: calculatedFats,
                        servingSize: currentWeight,
                        servingUnit: "Gram",
                        quantity: currentQuantity
                    )
                    
                    print("🗄️ [DEBUG SAVE] Bắt đầu ghi dữ liệu món ăn vào Firestore (addFoodToMeal)...")
                    
                    FirebaseService.shared.addFoodToMeal(
                        userId: user.userId,
                        mealType: self.selectedMealType,
                        mealDate: self.mealDate,
                        food: finalFood
                    ) { [weak self] mealResult in
                        
                        DispatchQueue.main.async {
                            guard let self = self else {
                                print("🚨 [DEBUG SAVE] Cảnh báo: ViewModel bị deinit tại bước lưu Firestore. Gọi completion dự phòng.")
                                completion()
                                return
                            }
                            
                            self.isSaving = false
                            
                            switch mealResult {
                            case .success:
                                print("🎉 [DEBUG SAVE] THÀNH CÔNG: Đã lưu nhật ký ăn uống vào Firestore thành công!")
                                completion()
                            case .failure(let error):
                                print("❌ [DEBUG SAVE] Thất bại tại Firestore: \(error.localizedDescription)")
                                self.errorMessage = "Lỗi Firestore: \(error.localizedDescription)"
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("❌ [DEBUG SAVE] Thất bại tại Storage (Upload ảnh): \(error.localizedDescription)")
                    self.isSaving = false
                    self.errorMessage = "Lỗi tải ảnh: \(error.localizedDescription)"
                }
            }
        }
    }
}

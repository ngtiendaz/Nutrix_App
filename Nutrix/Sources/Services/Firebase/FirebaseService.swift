//
//  FirebaseService.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage


final class FirebaseService{
    
    static let shared = FirebaseService()
     let db = Firestore.firestore()
    
    
    private init() {}
    
    func addFoodToMeal(
        userId: String,
        mealType: MealType,
        mealDate: Date,
        food: Food,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let dateKey = getDateKey(from: mealDate)
        
        let mealsRef = db.collection("users")
            .document(userId)
            .collection("meals")
        
        mealsRef
            .whereField("mealType", isEqualTo: mealType.rawValue)
            .whereField("dateKey", isEqualTo: dateKey)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // 👉 Có meal rồi → update
                if let doc = snapshot?.documents.first {
                    self.updateMeal(doc: doc, newFood: food, completion: completion)
                }
                // 👉 Chưa có → tạo mới
                else {
                    self.createNewMeal(
                        userId: userId,
                        mealType: mealType,
                        mealDate: mealDate,
                        food: food,
                        completion: completion
                    )
                }
            }
    }
    private func updateMeal(
            doc: QueryDocumentSnapshot,
            newFood: Food,
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            do {
                // Cố gắng đọc bản ghi Meal cũ từ Firebase
                var meal = try doc.data(as: Meal.self)
                
                meal.food.append(newFood)
                
                meal.totalCalories += newFood.calories
                meal.totalProtein += newFood.protein
                meal.totalCarbs += newFood.carbs
                meal.totalFats += newFood.fats
                
                let data = try Firestore.Encoder().encode(meal)
                
                doc.reference.setData(data, merge: true) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        let changes = ["cal": newFood.calories, "pro": newFood.protein, "carb": newFood.carbs, "fat": newFood.fats]
                        
                        // Hàm summary đã được thiết kế để tự động tạo mới nếu không tồn tại
                        self.updateDailySummary(userId: meal.userId, date: meal.createdAt, intakeChange: changes)
                        
                        completion(.success(()))
                    }
                }
                
            } catch let DecodingError.keyNotFound(key, context) {
                // 👉 BẮT TẬN TAY TRƯỜNG DỮ LIỆU BỊ THIẾU
                let errorMsg = "Bản ghi Meal cũ trên server đang bị thiếu trường: '\(key.stringValue)'. Hãy lên Firebase Console xóa Collection 'meals' của bữa ăn này đi."
                print("❌ [DEBUG DECODE ERROR]: \(errorMsg)")
                print("Chi tiết lỗi: \(context.debugDescription)")
                
                completion(.failure(NSError(domain: "Nutrix", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                
            } catch let DecodingError.typeMismatch(type, context) {
                let errorMsg = "Sai kiểu dữ liệu ở trường nào đó (Cần kiểu \(type)). Hãy xóa Meal cũ trên Firebase."
                print("❌ [DEBUG DECODE ERROR]: \(errorMsg) - \(context.debugDescription)")
                completion(.failure(NSError(domain: "Nutrix", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMsg])))
                
            } catch {
                print("❌ [DEBUG DECODE ERROR]: Lỗi giải mã không xác định: \(error)")
                completion(.failure(error))
            }
        }
    private func createNewMeal(
            userId: String,
            mealType: MealType,
            mealDate: Date, // 👈 thêm
            food: Food,
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            // 1. Tạo DateFormatter để định dạng giờ, ngày thành chuỗi
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timeString = formatter.string(from: mealDate)
            
            // 2. Tạo Document ID theo định dạng: loaiBuaAn_nam-thang-ngay_gio-phut-giay
            let customDocumentId = "\(mealType.rawValue)_\(timeString)"
            
            let meal = Meal(
                id: customDocumentId, // 👈 Đổi từ UUID() sang ID ngày giờ
                userId: userId,
                mealType: mealType,
                food: [food],
                totalCalories: food.calories,
                totalProtein: food.protein,
                totalCarbs: food.carbs,
                totalFats: food.fats,
                dateKey: getDateKey(from: mealDate),
                imageUrl: nil,
                createdAt: mealDate
            )
            
            print("🆕 CREATE NEW MEAL")
            print("Document ID:", meal.id) // In ra ID mới để bạn dễ kiểm tra trong log
            print("MealType:", meal.mealType.rawValue)
            print("DateKey:", meal.dateKey)
            print("CreatedAt:", meal.createdAt)
            print("TotalCalories:", meal.totalCalories)
            print("Food count:", meal.food.count)
            
            do {
                let data = try Firestore.Encoder().encode(meal)
                
                // setData vào document với id mới tạo
                self.db.collection("users").document(userId).collection("meals").document(meal.id).setData(data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        // ✅ CẬP NHẬT SUMMARY
                        let changes = ["cal": food.calories, "pro": food.protein, "carb": food.carbs, "fat": food.fats]
                        self.updateDailySummary(userId: userId, date: mealDate, intakeChange: changes)
                        
                        completion(.success(()))
                    }
                }
                
            } catch {
                completion(.failure(error))
            }
        }
    func getDateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    func uploadFoodImage(
        image: UIImage,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return
        }
        
        let fileName = "food_\(UUID().uuidString).jpg"
        let ref = Storage.storage().reference().child("food_images/\(fileName)")
        
        ref.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            ref.downloadURL { url, error in
                if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(error!))
                }
            }
        }
    }
        func fetchMeals(
            userId: String,
            date: Date,
            completion: @escaping (Result<[Meal], Error>) -> Void
        ) {
            let dateKey = getDateKey(from: date)
            
            db.collection("users")
                .document(userId)
                .collection("meals")
                .whereField("dateKey", isEqualTo: dateKey) // Lọc theo ngày
                .order(by: "createdAt", descending: true) // Món mới thêm hiện lên đầu
                .getDocuments { snapshot, error in
                    
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion(.success([]))
                        return
                    }
                    
                    // Giải mã dữ liệu từ Firestore snapshot sang Model Meal
                    let meals = documents.compactMap { doc -> Meal? in
                        try? doc.data(as: Meal.self)
                    }
                    
                    completion(.success(meals))
                }
        }
    func fetchDailyNutrition(
            userId: String,
            date: Date,
            completion: @escaping (Result<DailyNutrition, Error>) -> Void
        ) {
            // Tận dụng lại hàm fetchMeals để lấy danh sách các bữa ăn trong ngày
            self.fetchMeals(userId: userId, date: date) { result in
                switch result {
                case .success(let meals):
                    // Tính toán tổng các chỉ số
                    let calories = meals.reduce(0) { $0 + $1.totalCalories }
                    let protein = meals.reduce(0) { $0 + $1.totalProtein }
                    let carbs = meals.reduce(0) { $0 + $1.totalCarbs }
                    let fats = meals.reduce(0) { $0 + $1.totalFats }
                    
                    // Giả sử bạn sẽ lấy thêm lượng nước từ một collection khác hoặc
                    // tính từ một logic riêng. Ở đây tạm thời để 0.0 hoặc lấy từ Meal nếu có.
                    let water = 0.0
                    let burned = 0.0
                    
                    let dailyData = DailyNutrition(
                        userId: userId,
                        date: self.getDateKey(from: date),
                        totalCalories: calories,
                        totalProtein: protein,
                        totalCarbs: carbs,
                        totalFat: fats,
                        totalWater: water,
                        totalBurned: burned
                    )
                    
                    completion(.success(dailyData))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }

    func updateFoodInMeals(
        userId: String,
        mealDate: Date,
        oldFood: Food,
        newFood: Food,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        fetchMeals(userId: userId, date: mealDate) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let meals):
                guard let found = self.findMealContainingFood(meals: meals, food: oldFood) else {
                    completion(.failure(NSError(
                        domain: "Nutrix",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy món trong ngày đã chọn."]
                    )))
                    return
                }

                var meal = found.meal
                let index = found.index
                let previous = meal.food[index]

                meal.totalCalories = meal.totalCalories - previous.calories + newFood.calories
                meal.totalProtein = meal.totalProtein - previous.protein + newFood.protein
                meal.totalCarbs = meal.totalCarbs - previous.carbs + newFood.carbs
                meal.totalFats = meal.totalFats - previous.fats + newFood.fats
                meal.food[index] = newFood

                do {
                    let data = try Firestore.Encoder().encode(meal)
                    self.db.collection("users").document(userId).collection("meals").document(meal.id).setData(data, merge: true) { error in
                        if let error {
                            completion(.failure(error))
                        } else {
                            let diffCal = newFood.calories - oldFood.calories
                            let diffPro = newFood.protein - oldFood.protein
                            let diffCarb = newFood.carbs - oldFood.carbs
                            let diffFat = newFood.fats - oldFood.fats
                            
                            let changes = ["cal": diffCal, "pro": diffPro, "carb": diffCarb, "fat": diffFat]
                            self.updateDailySummary(userId: userId, date: mealDate, intakeChange: changes)
                            
                            completion(.success(()))
                        }
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    private func findMealContainingFood(meals: [Meal], food: Food) -> (meal: Meal, index: Int)? {
        for meal in meals {
            if let index = meal.food.firstIndex(where: { $0.id == food.id && $0.createdAt == food.createdAt }) {
                return (meal, index)
            }
        }
        return nil
    }
    /// Xóa một món ăn khỏi Meal và cập nhật lại tổng dinh dưỡng
        func deleteFoodFromMeal(
            userId: String,
            mealDate: Date,
            foodToDelete: Food,
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            fetchMeals(userId: userId, date: mealDate) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let meals):
                    guard let found = self.findMealContainingFood(meals: meals, food: foodToDelete) else {
                        completion(.failure(NSError(domain: "Nutrix", code: 404, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy món ăn để xóa."])))
                        return
                    }

                    var meal = found.meal
                    let index = found.index
                    let food = meal.food[index]

                    // Cập nhật lại chỉ số tổng của Meal
                    meal.totalCalories -= food.calories
                    meal.totalProtein -= food.protein
                    meal.totalCarbs -= food.carbs
                    meal.totalFats -= food.fats
                    
                    // Xóa khỏi mảng
                    meal.food.remove(at: index)

                    do {
                        let data = try Firestore.Encoder().encode(meal)
                        // Nếu sau khi xóa không còn món nào, bạn có thể chọn xóa luôn Document hoặc để mảng trống.
                        // Ở đây ta update Document.
                        self.db.collection("users").document(userId).collection("meals").document(meal.id).setData(data, merge: true) { error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                // ✅ CẬP NHẬT SUMMARY (TRỪ ĐI)
                                let changes = [
                                    "cal": -food.calories,
                                    "pro": -food.protein,
                                    "carb": -food.carbs,
                                    "fat": -food.fats
                                ]
                                self.updateDailySummary(userId: userId, date: mealDate, intakeChange: changes)
                                
                                completion(.success(()))
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        }
    
    func fetchAIContextData(userId: String, date: Date, completion: @escaping (Result<(NutritionPlan?, DailySummary?), Error>) -> Void) {
        let group = DispatchGroup()
        
        var currentPlan: NutritionPlan? = nil
        var dailySummary: DailySummary? = nil
        var fetchError: Error? = nil
        
        // 1. Fetch Plan hiện tại
        group.enter()
        self.fetchCurrentPlan(userId: userId) { result in
            switch result {
            case .success(let plan):
                currentPlan = plan
            case .failure(let error):
                fetchError = error
            }
            group.leave()
        }
        
        // 2. Fetch Summary ngày hôm nay
        group.enter()
        self.fetchDailySummary(userId: userId, date: date) { result in
            switch result {
            case .success(let summary):
                dailySummary = summary
            case .failure(let error):
                // Không chặn app nếu ngày mới chưa có summary record
                print("💡 Note: Chưa có summary cho ngày này.")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
            } else {
                completion(.success((currentPlan, dailySummary)))
            }
        }
    }
    
    func fetchFoods(completion: @escaping (Result<[Food], Error>) -> Void) {
        db.collection("foods")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let foods = documents.compactMap { doc -> Food? in
                    try? doc.data(as: Food.self)
                }
                
                completion(.success(foods))
            }
    }
}

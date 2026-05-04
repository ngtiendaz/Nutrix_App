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
    private let db = Firestore.firestore()
    
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
                    completion(.success(()))
                }
            }
            print("♻️ UPDATE MEAL")
            print("Add food:", newFood.name)
            print("New total calories:", meal.totalCalories)
            print("Food count:", meal.food.count)
            
        } catch {
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
        let meal = Meal(
            id: UUID().uuidString,
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
        print("MealType:", meal.mealType.rawValue)
        print("DateKey:", meal.dateKey)
        print("CreatedAt:", meal.createdAt)
        print("TotalCalories:", meal.totalCalories)
        print("Food count:", meal.food.count)
        do {
            let data = try Firestore.Encoder().encode(meal)
            
            db.collection("users")
                .document(userId)
                .collection("meals")
                .document(meal.id)
                .setData(data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
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
}

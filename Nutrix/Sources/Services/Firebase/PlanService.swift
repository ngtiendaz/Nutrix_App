//
//  PlanService.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//

import Foundation
import FirebaseFirestore

extension FirebaseService {
    
    // MARK: - Save & Update Plan
    /// Lưu plan mới. Nếu đã có plan cũ, nó sẽ tự động được lưu vào lịch sử trước khi ghi đè.
    func saveNutritionPlan(
        userId: String,
        plan: NutritionPlan,
        durationMonths: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 1. Kiểm tra xem có plan hiện tại không để lưu vào lịch sử trước
        fetchCurrentPlan(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            if case .success(let oldPlan) = result, let oldPlan = oldPlan {
                // Lưu plan cũ vào sub-collection 'history_plans' trước khi ghi đè
                self.archivePlanToHistory(userId: userId, plan: oldPlan)
            }
            
            // 2. Tạo dữ liệu plan mới
            let startDate = Date()
            let endDate = Calendar.current.date(byAdding: .month, value: durationMonths, to: startDate) ?? startDate
            
            let planData: [String: Any] = [
                "dailyCalories": plan.dailyCalories,
                "activityCalories": plan.activityCalories,
                "protein": plan.protein,
                "carbs": plan.carbs,
                "fat": plan.fat,
                "advice": plan.advice,
                "exercisePlan": plan.exercisePlan,
                "startDate": Timestamp(date: startDate),
                "endDate": Timestamp(date: endDate),
                "isActive": true,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            // 3. Ghi đè vào document 'current_plan'
            self.db.collection("users")
                .document(userId)
                .collection("plans")
                .document("current_plan")
                .setData(planData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
        }
    }
    
    // MARK: - Fetch Plan
    /// Lấy plan hiện tại và kiểm tra tính hiệu lực (còn trong thời hạn hay không)
    func fetchCurrentPlan(
        userId: String,
        completion: @escaping (Result<NutritionPlan?, Error>) -> Void
    ) {
        db.collection("users")
            .document(userId)
            .collection("plans")
            .document("current_plan")
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data(), let isActive = data["isActive"] as? Bool, isActive else {
                    completion(.success(nil))
                    return
                }
                
                // Kiểm tra ngày hết hạn
                if let endDateTimestamp = data["endDate"] as? Timestamp {
                    let endDate = endDateTimestamp.dateValue()
                    if Date() > endDate {
                        // Plan đã hết hạn -> Chuyển vào lịch sử và trả về nil
                        self.handleExpiredPlan(userId: userId, data: data)
                        completion(.success(nil))
                        return
                    }
                }
                
                // Parse dữ liệu sang Model NutritionPlan
                let plan = NutritionPlan(
                    dailyCalories: data["dailyCalories"] as? Double ?? 0,
                    activityCalories: data["activityCalories"] as? Double ?? 0,
                    protein: data["protein"] as? Double ?? 0,
                    carbs: data["carbs"] as? Double ?? 0,
                    fat: data["fat"] as? Double ?? 0,
                    advice: data["advice"] as? String ?? "",
                    exercisePlan: data["exercisePlan"] as? String ?? "",
                    startDate: (data["startDate"] as? Timestamp)?.dateValue()
                )
                completion(.success(plan))
            }
    }
    
    // MARK: - Delete/Deactivate Plan
    func deleteCurrentPlan(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Thay vì xóa sổ, ta nên lưu nó vào lịch sử với trạng thái "cancelled"
        // để phục vụ thống kê tại sao người dùng bỏ cuộc giữa chừng.
        fetchCurrentPlan(userId: userId) { [weak self] result in
            if case .success(let plan) = result, let plan = plan {
                self?.archivePlanToHistory(userId: userId, plan: plan, status: "cancelled")
            }
            
            self?.db.collection("users")
                .document(userId)
                .collection("plans")
                .document("current_plan")
                .delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Lưu plan vào bộ sưu tập lịch sử
    private func archivePlanToHistory(userId: String, plan: NutritionPlan, status: String = "completed") {
        var historyData: [String: Any] = [
            "dailyCalories": plan.dailyCalories,
            "activityCalories": plan.activityCalories,
            "protein": plan.protein,
            "carbs": plan.carbs,
            "fat": plan.fat,
            "advice": plan.advice,
            "exercisePlan": plan.exercisePlan,
            "startDate": plan.startDate ?? Date(),
            "archivedAt": FieldValue.serverTimestamp(),
            "status": status // completed, cancelled, or expired
        ]
        
        db.collection("users")
            .document(userId)
            .collection("history_plans")
            .addDocument(data: historyData)
    }
    
    /// Xử lý khi plan hết hạn tự động
    private func handleExpiredPlan(userId: String, data: [String: Any]) {
        // Chuyển status isActive về false
        db.collection("users")
            .document(userId)
            .collection("plans")
            .document("current_plan")
            .updateData(["isActive": false])
        
        // Tạo một bản ghi trong history_plans
        db.collection("users")
            .document(userId)
            .collection("history_plans")
            .addDocument(data: data)
    }
}

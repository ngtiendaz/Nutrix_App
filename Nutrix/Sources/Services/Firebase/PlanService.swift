//
//  PlanService.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//

import Foundation
import FirebaseFirestore

extension FirebaseService {
    
        func saveNutritionPlan(
            userId: String,
            plan: NutritionPlan,
            durationMonths: Int,
            currentWeight: Double,  // Thêm tham số này
            targetWeight: Double,   // Thêm tham số này
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            // 1. Kiểm tra xem có plan hiện tại không để lưu vào lịch sử trước
            fetchCurrentPlan(userId: userId) { [weak self] result in
                guard let self = self else { return }
                
                if case .success(let oldPlan) = result, let oldPlan = oldPlan {
                    self.archivePlanToHistory(userId: userId, plan: oldPlan)
                }
                
                // 2. Tính toán ngày
                let startDate = Date()
                let endDate = Calendar.current.date(byAdding: .month, value: durationMonths, to: startDate) ?? startDate
                
                // 3. Tạo dữ liệu plan mới (Đã thêm weight)
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
                    "currentWeight": currentWeight, // Lưu cân nặng hiện tại
                    "targetWeight": targetWeight,   // Lưu cân nặng mục tiêu
                    "isActive": true,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                // 4. Ghi đè vào document 'current_plan'
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
                
                let plan = NutritionPlan(
                    dailyCalories: data["dailyCalories"] as? Double ?? 0,
                    activityCalories: data["activityCalories"] as? Double ?? 0,
                    protein: data["protein"] as? Double ?? 0,
                    carbs: data["carbs"] as? Double ?? 0,
                    fat: data["fat"] as? Double ?? 0,
                    advice: data["advice"] as? String ?? "",
                    exercisePlan: data["exercisePlan"] as? String ?? "",
                    startDate: (data["startDate"] as? Timestamp)?.dateValue(),
                    currentWeight: data["currentWeight"] as? Double ?? 0,
                    targetWeight: data["targetWeight"] as? Double ?? 0
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
            "status": status,
            // Lưu thêm cân nặng vào lịch sử ở đây
            "currentWeight": plan.currentWeight ?? 0,
            "targetWeight": plan.targetWeight ?? 0
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
    // MARK: - Fetch Plan Summary
    func fetchPlanSummary(userId: String, completion: @escaping (Result<PlanSummary?, Error>) -> Void) {
        db.collection("users")
            .document(userId)
            .collection("plans")
            .document("current_plan")
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data() else {
                    completion(.success(nil))
                    return
                }
                
                let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
                let endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
                let isActive = data["isActive"] as? Bool ?? false
                
                // Giả định bạn có lưu weight trong profile hoặc plan
                // Nếu chưa có trong plan, bạn có thể lấy từ Profile document
                let summary = PlanSummary(
                    startDate: startDate,
                    endDate: endDate,
                    currentWeight: data["currentWeight"] as? Double ?? 0.0,
                    targetWeight: data["targetWeight"] as? Double ?? 0.0,
                    isActive: isActive && Date() <= endDate
                )
                
                completion(.success(summary))
            }
    }
    func fetchPlanForDate(userId: String, date: Date, completion: @escaping (Result<PlanSummary?, Error>) -> Void) {
        let targetDate = Calendar.current.startOfDay(for: date)
        
        // 1. Kiểm tra Current Plan trước
        db.collection("users").document(userId).collection("plans").document("current_plan")
            .getDocument { snapshot, error in
                if let data = snapshot?.data(), let start = (data["startDate"] as? Timestamp)?.dateValue(), let end = (data["endDate"] as? Timestamp)?.dateValue() {
                    
                    if targetDate >= Calendar.current.startOfDay(for: start) && targetDate <= Calendar.current.startOfDay(for: end) {
                        let summary = PlanSummary(
                            startDate: start,
                            endDate: end,
                            currentWeight: data["currentWeight"] as? Double ?? 0,
                            targetWeight: data["targetWeight"] as? Double ?? 0,
                            isActive: data["isActive"] as? Bool ?? false,
                            dailyCalories: data["dailyCalories"] as? Double ?? 0, // Thêm dòng này
                            activityCalories: data["activityCalories"] as? Double ?? 0, // Thêm dòng này
                            protein: data["protein"] as? Double ?? 0,
                            carbs: data["carbs"] as? Double ?? 0,
                            fat: data["fat"] as? Double ?? 0
                        )
                        completion(.success(summary))
                        return
                    }
                }
                
                // 2. Nếu không nằm trong Current Plan, tìm trong History
                self.db.collection("users").document(userId).collection("history_plans")
                    .whereField("startDate", isLessThanOrEqualTo: Timestamp(date: date))
                    .getDocuments { querySnapshot, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        // Lọc thủ công vì Firestore không hỗ trợ query range trên 2 field khác nhau hiệu quả
                        let match = querySnapshot?.documents.compactMap { doc -> PlanSummary? in
                            let d = doc.data()
                            guard let start = (d["startDate"] as? Timestamp)?.dateValue(),
                                  let end = (d["endDate"] as? Timestamp)?.dateValue() else { return nil }
                            
                            if targetDate >= Calendar.current.startOfDay(for: start) && targetDate <= Calendar.current.startOfDay(for: end) {
                                return PlanSummary(
                                    startDate: start,
                                    endDate: end,
                                    currentWeight: d["currentWeight"] as? Double ?? 0,
                                    targetWeight: d["targetWeight"] as? Double ?? 0,
                                    isActive: false // Lịch sử thì luôn là false
                                )
                            }
                            return nil
                        }.first
                        
                        completion(.success(match))
                    }
            }
    }
}

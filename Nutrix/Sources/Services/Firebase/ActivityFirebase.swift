//
//  ActivityFirebaseService.swift.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//

import Foundation
import FirebaseFirestore

extension FirebaseService {
    
    func fetchUserBodyMetrics(userId: String, completion: @escaping (Result<(height: Double, weight: Double), Error>) -> Void) {
            db.collection("users").document(userId).getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let data = snapshot?.data() else {
                    completion(.success((height: 0.0, weight: 0.0)))
                    return
                }
                let height = data["height"] as? Double ?? 0.0
                let weight = data["weight"] as? Double ?? 0.0
                completion(.success((height: height, weight: weight)))
            }
        }
    
    // MARK: - 1. Get Activity Dataset (Dành cho User chọn bài tập)
    /// Lấy danh sách các loại hoạt động mẫu do Admin quản lý
    func fetchActivityDataset(completion: @escaping (Result<[Activity], Error>) -> Void) {
        db.collection("activities").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let activities = snapshot?.documents.compactMap { try? $0.data(as: Activity.self) } ?? []
            completion(.success(activities))
        }
    }
    
    // MARK: - 2. Get UserActivities (Lấy nhật ký trong ngày)
    /// Lấy danh sách các hoạt động User đã tập trong một ngày cụ thể
    func fetchUserActivities(userId: String, date: Date, completion: @escaping (Result<[UserActivityLog], Error>) -> Void) {
        let dateKey = getDateKey(from: date)
        db.collection("users")
            .document(userId)
            .collection("userActivities")
            .whereField("dateKey", isEqualTo: dateKey)
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                let logs = snapshot?.documents.compactMap { try? $0.data(as: UserActivityLog.self) } ?? []
                completion(.success(logs))
            }
    }
    
    // MARK: - 3. Add UserActivity (Thêm nhật ký mới)
    /// Tính toán calo dựa trên chỉ số cơ thể và lưu vào nhật ký User
    func addUserActivity(
        userId: String,
        activity: Activity,
        durationMinutes: Double,
        date: Date,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Lấy thông tin cá nhân của User để tính Calo chính xác (image_aeda81.png)
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data(), error == nil else {
                completion(.failure(error ?? NSError(domain: "UserData", code: 404)))
                return
            }
            
            let weight = data["weight"] as? Double ?? 0.0
            let height = data["height"] as? Double ?? 0.0
            let age = data["age"] as? Int ?? 0
            let gender = data["gender"] as? String ?? "Nam"
            
            // Tính Calo theo công thức Corrected MET (BMR-based)
            let burned = self.calculateAccurateCalories(
                met: activity.metValue,
                duration: durationMinutes,
                weight: weight,
                height: height,
                age: age,
                gender: gender
            )
            
            let logId = UUID().uuidString
            let log = UserActivityLog(
                id: logId,
                activityType: activity,
                durationMinutes: durationMinutes,
                caloriesBurned: burned,
                dateKey: self.getDateKey(from: date),
                createdAt: date
            )
            
            do {
                try self.db.collection("users")
                    .document(userId)
                    .collection("userActivities")
                    .document(logId)
                    .setData(from: log) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            // ✅ CẬP NHẬT SUMMARY: Cộng thêm lượng calo vừa đốt
                            self.updateDailySummary(userId: userId, date: date, burnedChange: burned)
                            completion(.success(()))
                        }
                    }
            } catch { completion(.failure(error)) }
        }
    }
    

    func updateUserActivity(
            userId: String,
            logId: String,
            newDuration: Double,
            activity: Activity,
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            // Lấy dữ liệu cũ để tính toán sự chênh lệch (Diff)
            db.collection("users").document(userId).collection("userActivities").document(logId).getDocument { [weak self] logSnapshot, _ in
                guard let self = self, let logData = logSnapshot?.data() else { return }
                let oldBurned = logData["caloriesBurned"] as? Double ?? 0.0
                let dateTimestamp = logData["createdAt"] as? Timestamp
                let activityDate = dateTimestamp?.dateValue() ?? Date()

                // Lấy thông tin user để tính calo mới
                self.db.collection("users").document(userId).getDocument { snapshot, error in
                    guard let data = snapshot?.data(), error == nil else { return }
                    
                    let weight = data["weight"] as? Double ?? 0.0
                    let height = data["height"] as? Double ?? 0.0
                    let age = data["age"] as? Int ?? 0
                    let gender = data["gender"] as? String ?? "Nam"
                    
                    let newBurned = self.calculateAccurateCalories(
                        met: activity.metValue, duration: newDuration,
                        weight: weight, height: height, age: age, gender: gender
                    )
                    
                    // Tính độ chênh lệch (Có thể âm hoặc dương)
                    let burnedDifference = newBurned - oldBurned
                    
                    let updateData: [String: Any] = [
                        "durationMinutes": newDuration,
                        "caloriesBurned": newBurned
                    ]
                    
                    self.db.collection("users").document(userId).collection("userActivities").document(logId)
                        .updateData(updateData) { error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                self.updateDailySummary(userId: userId, date: activityDate, burnedChange: burnedDifference)
                                completion(.success(()))
                            }
                        }
                }
            }
        }
    
    func deleteUserActivity(userId: String, logId: String, completion: @escaping (Result<Void, Error>) -> Void) {
            // Phải lấy lượng calo của log này trước khi xóa để trừ đi trong summary
            db.collection("users").document(userId).collection("userActivities").document(logId).getDocument { [weak self] snapshot, _ in
                guard let self = self, let data = snapshot?.data() else { return }
                
                let burnedToSubtract = data["caloriesBurned"] as? Double ?? 0.0
                let dateTimestamp = data["createdAt"] as? Timestamp
                let activityDate = dateTimestamp?.dateValue() ?? Date()
                
                self.db.collection("users")
                    .document(userId)
                    .collection("userActivities")
                    .document(logId)
                    .delete { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self.updateDailySummary(userId: userId, date: activityDate, burnedChange: -burnedToSubtract)
                            completion(.success(()))
                        }
                    }
            }
        }
    
    // MARK: - Private Logic
    private func calculateAccurateCalories(met: Double, duration: Double, weight: Double, height: Double, age: Int, gender: String) -> Double {
        var bmr: Double = 0
        // Harris-Benedict Equation
        if gender == "Nam" {
            bmr = 66.47 + (13.75 * weight) + (5.003 * height) - (6.755 * Double(age))
        } else {
            bmr = 655.1 + (9.563 * weight) + (1.85 * height) - (4.676 * Double(age))
        }
        // Công thức: (BMR/24h/60p) * MET * Số phút tập
        return (bmr / 1440) * met * duration
    }
    // MARK: - Lấy mục tiêu Calo từ lộ trình hiện tại
    func fetchActivityGoal(userId: String, completion: @escaping (Result<Int, Error>) -> Void) {
        db.collection("users")
            .document(userId)
            .collection("plans")
            .document("current_plan") // Document ID cố định mà AI đã lưu
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = snapshot?.data() else {
                    completion(.success(0)) // Nếu chưa có plan, trả về 0
                    return
                }
                
                // Lấy activityCalories (AI tính toán calo cần đốt từ tập luyện)
                let goal = data["activityCalories"] as? Double ?? 0.0
                completion(.success(Int(goal)))
            }
    }
}

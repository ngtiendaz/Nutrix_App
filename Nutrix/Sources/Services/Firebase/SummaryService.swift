//
//  SummaryService.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//

import Foundation
import FirebaseFirestore

extension FirebaseService {
    
    func updateDailySummary(userId: String, date: Date,
                            intakeChange: [String: Double]? = nil,
                            burnedChange: Double? = nil) {
        
        let dateKey = self.getDateKey(from: date)
        let summaryRef = db.collection("users").document(userId).collection("daily_summaries").document(dateKey)
        
        self.fetchCurrentPlan(userId: userId) { result in
            var currentTarget = (cal: 2000.0, pro: 150.0, carb: 200.0, fat: 70.0)
            
            if case .success(let plan) = result, let plan = plan {
                currentTarget = (plan.dailyCalories, plan.protein, plan.carbs, plan.fat)
            }
            
            summaryRef.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    // --- TRƯỜNG HỢP CẬP NHẬT: TÍNH TOÁN ĐỂ KHÔNG BỊ ÂM ---
                    let data = snapshot.data() ?? [:]
                    
                    var updates: [String: Any] = [:]
                    
                    if let intake = intakeChange {
                        // Lấy giá trị hiện tại, cộng với thay đổi, nếu < 0 thì lấy 0
                        let newCal = max(0, (data["intakeCalories"] as? Double ?? 0) + (intake["cal"] ?? 0))
                        let newPro = max(0, (data["intakeProtein"] as? Double ?? 0) + (intake["pro"] ?? 0))
                        let newCarb = max(0, (data["intakeCarbs"] as? Double ?? 0) + (intake["carb"] ?? 0))
                        let newFat = max(0, (data["intakeFats"] as? Double ?? 0) + (intake["fat"] ?? 0))
                        
                        updates["intakeCalories"] = newCal
                        updates["intakeProtein"] = newPro
                        updates["intakeCarbs"] = newCarb
                        updates["intakeFats"] = newFat
                    }
                    
                    if let burned = burnedChange {
                        let newBurned = max(0, (data["burnedCalories"] as? Double ?? 0) + burned)
                        updates["burnedCalories"] = newBurned
                    }
                    
                    updates["updatedAt"] = FieldValue.serverTimestamp()
                    
                    summaryRef.updateData(updates)
                    
                } else {
                    // --- TRƯỜNG HỢP TẠO MỚI: ĐẢM BẢO KHÔNG LƯU SỐ ÂM NGAY TỪ ĐẦU ---
                    var summaryData: [String: Any] = [
                        "userId": userId,
                        "dateKey": dateKey,
                        "targetCalories": currentTarget.cal,
                        "targetProtein": currentTarget.pro,
                        "targetCarbs": currentTarget.carb,
                        "targetFats": currentTarget.fat,
                        "createdAt": FieldValue.serverTimestamp(),
                        "intakeCalories": max(0, intakeChange?["cal"] ?? 0),
                        "intakeProtein": max(0, intakeChange?["pro"] ?? 0),
                        "intakeCarbs": max(0, intakeChange?["carb"] ?? 0),
                        "intakeFats": max(0, intakeChange?["fat"] ?? 0),
                        "burnedCalories": max(0, burnedChange ?? 0)
                    ]
                    
                    summaryRef.setData(summaryData)
                }
            }
        }
    }
    
    func fetchDailySummary(userId: String, date: Date, completion: @escaping (Result<DailySummary?, Error>) -> Void) {
        let dateKey = self.getDateKey(from: date)
        db.collection("users")
            .document(userId)
            .collection("daily_summaries")
            .document(dateKey)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Nếu không tìm thấy document (ngày mới chưa ăn gì), trả về nil
                guard let snapshot = snapshot, snapshot.exists else {
                    completion(.success(nil))
                    return
                }
                
                do {
                    let summary = try snapshot.data(as: DailySummary.self)
                    completion(.success(summary))
                } catch {
                    completion(.failure(error))
                }
            }
    }
}

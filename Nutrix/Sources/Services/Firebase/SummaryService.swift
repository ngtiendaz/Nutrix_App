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
        
        print("🗄️ [DEBUG SUMMARY] Bắt đầu đồng bộ DailySummary cho ngày: \(dateKey)")
        
        self.fetchCurrentPlan(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            var currentTarget = (cal: 2000.0, pro: 150.0, carb: 200.0, fat: 70.0)
            
            if case .success(let plan) = result, let plan = plan {
                currentTarget = (plan.dailyCalories, plan.protein, plan.carbs, plan.fat)
                print("🎯 [DEBUG SUMMARY] Lấy thông tin mục tiêu lộ trình thành công.")
            } else {
                print("⚠️ [DEBUG SUMMARY] Không lấy được lộ trình riêng, dùng chỉ số mặc định.")
            }
            
            summaryRef.getDocument { snapshot, error in
                if let error = error {
                    print("❌ [DEBUG SUMMARY] Lỗi kiểm tra document: \(error.localizedDescription)")
                    return
                }
                
                if let snapshot = snapshot, snapshot.exists {
                    // --- TRƯỜNG HỢP 1: CẬP NHẬT (DOCUMENT ĐÃ TỒN TẠI) ---
                    print("🔄 [DEBUG SUMMARY] Tìm thấy bản ghi summary cũ, tiến hành cộng dồn tích lũy...")
                    let data = snapshot.data() ?? [:]
                    var updates: [String: Any] = [:]
                    
                    if let intake = intakeChange {
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
                    
                    updates["updatedAt"] = date
                    
                    summaryRef.updateData(updates) { err in
                        if let err = err {
                            print("❌ [DEBUG SUMMARY] Cập nhật thất bại: \(err.localizedDescription)")
                        } else {
                            print("✅ [DEBUG SUMMARY] Cập nhật chỉ số tích lũy thành công!")
                        }
                    }
                    
                } else {
                    // --- TRƯỜNG HỢP 2: TẠO MỚI (CHƯA CÓ HOẶC DO TỰ TAY XÓA) ---
                    print("🆕 [DEBUG SUMMARY] Không tìm thấy bản ghi... Tiến hành tái tạo bản ghi mới...")
                    
                    // 🚨 ĐÃ FIX: Đồng bộ chính xác tên các trường (burnedCalories thay vì totalBurned)
                    let summaryData: [String: Any] = [
                        "userId": userId,
                        "dateKey": dateKey, // Chắc chắn field này map đúng struct
                        "targetCalories": currentTarget.cal,
                        "targetProtein": currentTarget.pro,
                        "targetCarbs": currentTarget.carb,
                        "targetFats": currentTarget.fat,
                        "intakeCalories": max(0, intakeChange?["cal"] ?? 0),
                        "intakeProtein": max(0, intakeChange?["pro"] ?? 0),
                        "intakeCarbs": max(0, intakeChange?["carb"] ?? 0),
                        "intakeFats": max(0, intakeChange?["fat"] ?? 0),
                        "burnedCalories": max(0, burnedChange ?? 0), // 👈 ĐIỂM FIX QUAN TRỌNG NHẤT
                        "totalWater": 0.0,
                        "createdAt": date,
                        "updatedAt": date
                    ]
                    
                    summaryRef.setData(summaryData) { err in
                        if let err = err {
                            print("❌ [DEBUG SUMMARY] Tạo mới bản ghi thất bại: \(err.localizedDescription)")
                        } else {
                            print("🎉 [DEBUG SUMMARY] Khởi tạo bản ghi DailySummary mới thành công sạch sẽ!")
                        }
                    }
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
                    print("❌ [DEBUG FETCH SUMMARY] Lỗi tải dữ liệu: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else {
                    print("💡 [DEBUG FETCH SUMMARY] Ngày mới chưa ăn gì (Document trống), trả về nil an toàn.")
                    completion(.success(nil))
                    return
                }
                
                do {
                    let summary = try snapshot.data(as: DailySummary.self)
                    print("✅ [DEBUG FETCH SUMMARY] Decode dữ liệu DailySummary thành công!")
                    completion(.success(summary))
                } catch {
                    print("❌ [DEBUG FETCH SUMMARY] Crash giải mã dữ liệu (Lỗi cấu trúc trường): \(error)")
                    completion(.failure(error))
                }
            }
    }
}

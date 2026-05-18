//
//  ActivityViewModel.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//
import Foundation
import Combine
import FirebaseFirestore

class ActivityViewModel: ObservableObject {
    @Published var userLogs: [UserActivityLog] = []
    @Published var activityDataset: [Activity] = []
    @Published var isLoading = false
    @Published var goalCalories: Int = 0
    
    // THÀNH PHẦN MỚI: Lưu trữ chỉ số cơ thể lấy từ Firebase Service
    @Published var userHeight: Double = 0.0
    @Published var userWeight: Double = 0.0
    
    private let service = FirebaseService.shared
    
    init() {
        getDataset()
    }
    
    func getDataset() {
        service.fetchActivityDataset { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    print("✅ Đã lấy được \(data.count) hoạt động mẫu")
                    self.activityDataset = data
                case .failure(let error):
                    print("❌ Lỗi lấy dataset: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getUserLogs(userId: String, date: Date) {
        self.isLoading = true
        let dateKey = service.getDateKey(from: date)
        
        let group = DispatchGroup()
        
        // TASK 1: Lấy mục tiêu Calo
        group.enter()
        service.fetchActivityGoal(userId: userId) { [weak self] result in
            defer { group.leave() }
            if case .success(let goal) = result {
                DispatchQueue.main.async { self?.goalCalories = goal }
            }
        }
        
        // TASK MỚI: Lấy cấu hình chiều cao, cân nặng từ Service đổ lên View
        group.enter()
        service.fetchUserBodyMetrics(userId: userId) { [weak self] result in
            defer { group.leave() }
            if case .success(let metrics) = result {
                DispatchQueue.main.async {
                    self?.userHeight = metrics.height
                    self?.userWeight = metrics.weight
                }
            }
        }
        
        // TASK 3: Lấy nhật ký hoạt động
        group.enter()
        service.db.collection("users")
            .document(userId)
            .collection("userActivities")
            .whereField("dateKey", isEqualTo: dateKey)
            .getDocuments { [weak self] snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("❌ Lỗi fetch logs: \(error.localizedDescription)")
                    return
                }
                
                let logs = snapshot?.documents.compactMap { try? $0.data(as: UserActivityLog.self) } ?? []
                let sortedLogs = logs.sorted(by: { $0.createdAt > $1.createdAt })
                
                DispatchQueue.main.async { self?.userLogs = sortedLogs }
            }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    func addLog(userId: String, activity: Activity, duration: Double, date: Date) {
        service.addUserActivity(userId: userId, activity: activity, durationMinutes: duration, date: date) { _ in
            self.getUserLogs(userId: userId, date: date)
        }
    }
    
    func updateLog(userId: String, logId: String, duration: Double, activity: Activity, date: Date) {
        service.updateUserActivity(userId: userId, logId: logId, newDuration: duration, activity: activity) { _ in
            self.getUserLogs(userId: userId, date: date)
        }
    }
    
    func deleteLog(userId: String, logId: String, date: Date) {
        service.deleteUserActivity(userId: userId, logId: logId) { _ in
            self.getUserLogs(userId: userId, date: date)
        }
    }
}

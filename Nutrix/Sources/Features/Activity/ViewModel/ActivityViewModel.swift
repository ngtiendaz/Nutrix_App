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
    @Published var userLogs: [UserActivityLog] = [] // Danh sách đã tập trong ngày
    @Published var activityDataset: [Activity] = [] // Danh sách mẫu để chọn
    @Published var isLoading = false
    @Published var goalCalories: Int = 0
    
    private let service = FirebaseService.shared
    
    init() {
            getDataset() // Gọi luôn ở đây để data được load sẵn từ lúc vào app
        }
    
    // Lấy danh sách hoạt động mẫu từ Firebase
    func getDataset() {
        service.fetchActivityDataset { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    print("✅ Đã lấy được \(data.count) hoạt động mẫu") // Thêm dòng này
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
            
            // TASK 2: Lấy nhật ký hoạt động (Bỏ qua order của Firebase để tránh lỗi Index)
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
                    
                    // Map dữ liệu và sắp xếp thủ công theo thời gian tạo
                    let logs = snapshot?.documents.compactMap { try? $0.data(as: UserActivityLog.self) } ?? []
                    let sortedLogs = logs.sorted(by: { $0.createdAt > $1.createdAt })
                    
                    DispatchQueue.main.async { self?.userLogs = sortedLogs }
                }
            
            group.notify(queue: .main) {
                self.isLoading = false
            }
        }
    
    // Thêm hoạt động mới
    func addLog(userId: String, activity: Activity, duration: Double, date: Date) {
        service.addUserActivity(userId: userId, activity: activity, durationMinutes: duration, date: date) { _ in
            self.getUserLogs(userId: userId, date: date) // Refresh lại list
        }
    }
    
    // Cập nhật hoạt động
    func updateLog(userId: String, logId: String, duration: Double, activity: Activity, date: Date) {
        service.updateUserActivity(userId: userId, logId: logId, newDuration: duration, activity: activity) { _ in
            self.getUserLogs(userId: userId, date: date)
        }
    }
    
    // Xóa hoạt động
    func deleteLog(userId: String, logId: String, date: Date) {
        service.deleteUserActivity(userId: userId, logId: logId) { _ in
            self.getUserLogs(userId: userId, date: date)
        }
    }
}

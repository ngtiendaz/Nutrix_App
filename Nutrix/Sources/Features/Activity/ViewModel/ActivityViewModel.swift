//
//  ActivityViewModel.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//
import Foundation
import Combine

class ActivityViewModel: ObservableObject {
    @Published var userLogs: [UserActivityLog] = [] // Danh sách đã tập trong ngày
    @Published var activityDataset: [Activity] = [] // Danh sách mẫu để chọn
    @Published var isLoading = false
    
    private let service = FirebaseService.shared
    
    // Lấy danh sách hoạt động mẫu từ Firebase
    func getDataset() {
        service.fetchActivityDataset { result in
            DispatchQueue.main.async {
                if case .success(let data) = result { self.activityDataset = data }
            }
        }
    }
    
    // Lấy danh sách User đã tập trong ngày
    func getUserLogs(userId: String, date: Date) {
        isLoading = true
        service.fetchUserActivities(userId: userId, date: date) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                if case .success(let logs) = result { self.userLogs = logs }
            }
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

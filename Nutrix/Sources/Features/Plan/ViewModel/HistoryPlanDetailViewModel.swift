import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct PastDayCompletion: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let isCompleted: Bool
}

class HistoryPlanDetailViewModel: ObservableObject {
    @Published var weightChartData: [WeightChartPoint] = []
    @Published var executionLog: [PastDayCompletion] = []
    @Published var isLoading = false
    
    func loadDetails(for plan: NutritionPlan, allMetrics: [BodyMetrics]) {
        self.isLoading = true
        
        // 1. Dữ liệu cân nặng trong khoảng thời gian lộ trình
        let start = plan.startDate ?? Date()
        let end = plan.endDate ?? Date()
        
        // Cắt bớt giờ phút giây để lọc chính xác trong ngày
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: start)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
        
        let filteredMetrics = allMetrics.filter { metric in
            metric.timestamp >= startOfDay && metric.timestamp <= endOfDay
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        
        var points: [WeightChartPoint] = []
        let sortedMetrics = filteredMetrics.sorted(by: { $0.timestamp < $1.timestamp })
        for metric in sortedMetrics {
            points.append(WeightChartPoint(dateLabel: formatter.string(from: metric.timestamp), weight: metric.weight, type: "Cân nặng"))
        }
        self.weightChartData = points
        
        // 2. Fetch daily_summaries (Nhật ký thực hiện)
        guard let userId = Auth.auth().currentUser?.uid else {
            self.isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        
        let startKey = keyFormatter.string(from: start)
        let endKey = keyFormatter.string(from: end)
        
        db.collection("users").document(userId).collection("daily_summaries")
            .whereField("dateKey", isGreaterThanOrEqualTo: startKey)
            .whereField("dateKey", isLessThanOrEqualTo: endKey)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                var summariesMap: [String: Bool] = [:]
                if let documents = snapshot?.documents {
                    for doc in documents {
                        let data = doc.data()
                        let totalCalories = data["totalCalories"] as? Double ?? data["intakeCalories"] as? Double ?? 0.0
                        summariesMap[doc.documentID] = totalCalories > 0
                    }
                }
                
                // Trải phẳng tất cả các ngày từ startDate đến endDate
                var log: [PastDayCompletion] = []
                var currentDate = startOfDay
                
                // Chống tràn vòng lặp vô tận (giới hạn 90 ngày)
                var limit = 90
                while currentDate <= endOfDay && limit > 0 {
                    let dateKey = keyFormatter.string(from: currentDate)
                    let isCompleted = summariesMap[dateKey] ?? false
                    log.append(PastDayCompletion(
                        date: currentDate,
                        label: formatter.string(from: currentDate),
                        isCompleted: isCompleted
                    ))
                    
                    if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                        currentDate = nextDate
                    } else {
                        break
                    }
                    limit -= 1
                }
                
                DispatchQueue.main.async {
                    self.executionLog = log
                    self.isLoading = false
                }
            }
    }
}

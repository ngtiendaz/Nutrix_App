import Foundation
import FirebaseFirestore

extension FirebaseService {
    
    // MARK: - 1. THỐNG KÊ THEO TUẦN (Luôn đủ 7 cột từ T2 -> CN)
    func fetchWeeklyStatistics(
        userId: String,
        for date: Date,
        completion: @escaping (Result<StatisticsReport, Error>) -> Void
    ) {
        let calendar = Calendar.current
        var calendarWithMonday = calendar
        calendarWithMonday.firstWeekday = 2 // Đặt Thứ 2 là đầu tuần
        
        guard let mondayDate = calendarWithMonday.dateInterval(of: .weekOfYear, for: date)?.start else {
            completion(.failure(NSError(domain: "Nutrix", code: 500, userInfo: [NSLocalizedDescriptionKey: "Không xác định được ngày đầu tuần"])))
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var weekKeys: [String] = []
        var weekDates: [Date] = []
        let weekdayLabels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        
        // Sinh đủ cấu trúc thời gian 7 ngày trong tuần
        for i in 0..<7 {
            if let dayDate = calendarWithMonday.date(byAdding: .day, value: i, to: mondayDate) {
                let key = formatter.string(from: dayDate)
                weekKeys.append(key)
                weekDates.append(dayDate)
            }
        }
        
        guard let startKey = weekKeys.first, let endKey = weekKeys.last else { return }
        
        db.collection("users")
            .document(userId)
            .collection("daily_summaries")
            .whereField("dateKey", isGreaterThanOrEqualTo: startKey)
            .whereField("dateKey", isLessThanOrEqualTo: endKey)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let summaries = snapshot?.documents.compactMap { try? $0.data(as: DailySummary.self) } ?? []
                var points: [MetricPoint] = []
                
                // Vòng lặp map dữ liệu đồng bộ
                for (index, key) in weekKeys.enumerated() {
                    let label = weekdayLabels[index]
                    let currentDate = weekDates[index]
                    
                    if let daySummary = summaries.first(where: { $0.dateKey == key }) {
                        // Trường hợp CÓ dữ liệu ghi chép từ Firebase
                        points.append(MetricPoint(
                            label: label,
                            date: currentDate,
                            intakeCalories: daySummary.intakeCalories,
                            targetCalories: daySummary.targetCalories,
                            burnedCalories: daySummary.burnedCalories,
                            protein: daySummary.intakeProtein,
                            carbs: daySummary.intakeCarbs,
                            fat: daySummary.intakeFats,
                            hasPlan: daySummary.targetCalories > 0 // Có plan nếu target lớn hơn 0
                        ))
                    } else {
                        // Trường hợp KHÔNG CÓ dữ liệu lộ trình / Ngày tương lai trống
                        points.append(MetricPoint(
                            label: label,
                            date: currentDate,
                            intakeCalories: 0,
                            targetCalories: 0,
                            burnedCalories: 0,
                            protein: 0,
                            carbs: 0,
                            fat: 0,
                            hasPlan: false // Đánh dấu false để ẩn % và hiện badge chữ
                        ))
                    }
                }
                completion(.success(StatisticsReport(summaryPoints: points)))
            }
    }
    
    // MARK: - 2. THỐNG KÊ THEO THÁNG (Sinh đủ ngày trong tháng phục vụ phân trang)
    func fetchMonthlyStatistics(
        userId: String,
        month: Int,
        year: Int,
        completion: @escaping (Result<StatisticsReport, Error>) -> Void
    ) {
        let startKey = String(format: "%04d-%02d-01", year, month)
        let endKey = String(format: "%04d-%02d-31", year, month)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        db.collection("users")
            .document(userId)
            .collection("daily_summaries")
            .whereField("dateKey", isGreaterThanOrEqualTo: startKey)
            .whereField("dateKey", isLessThanOrEqualTo: endKey)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let summaries = snapshot?.documents.compactMap { try? $0.data(as: DailySummary.self) } ?? []
                var points: [MetricPoint] = []
                let calendar = Calendar.current
                
                var components = DateComponents(year: year, month: month, day: 1)
                guard let startDate = calendar.date(from: components),
                      let range = calendar.range(of: .day, in: .month, for: startDate) else { return }
                
                for day in 1...range.count {
                    components.day = day
                    guard let currentDate = calendar.date(from: components) else { continue }
                    let currentKey = formatter.string(from: currentDate)
                    let label = String(format: "%02d", day)
                    
                    if let daySummary = summaries.first(where: { $0.dateKey == currentKey }) {
                        points.append(MetricPoint(
                            label: label,
                            date: currentDate,
                            intakeCalories: daySummary.intakeCalories,
                            targetCalories: daySummary.targetCalories,
                            burnedCalories: daySummary.burnedCalories,
                            protein: daySummary.intakeProtein,
                            carbs: daySummary.intakeCarbs,
                            fat: daySummary.intakeFats,
                            hasPlan: daySummary.targetCalories > 0
                        ))
                    } else {
                        points.append(MetricPoint(
                            label: label,
                            date: currentDate,
                            intakeCalories: 0,
                            targetCalories: 0,
                            burnedCalories: 0,
                            protein: 0,
                            carbs: 0,
                            fat: 0,
                            hasPlan: false
                        ))
                    }
                }
                completion(.success(StatisticsReport(summaryPoints: points.sorted { $0.label < $1.label })))
            }
    }
    
    // MARK: - 3. THỐNG KÊ THEO NĂM
    func fetchYearlyStatistics(
        userId: String,
        year: Int,
        completion: @escaping (Result<StatisticsReport, Error>) -> Void
    ) {
        let startKey = "\(year)-01-01"
        let endKey = "\(year)-12-31"
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        db.collection("users")
            .document(userId)
            .collection("daily_summaries")
            .whereField("dateKey", isGreaterThanOrEqualTo: startKey)
            .whereField("dateKey", isLessThanOrEqualTo: endKey)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let summaries = snapshot?.documents.compactMap { try? $0.data(as: DailySummary.self) } ?? []
                var monthlyPoints: [MetricPoint] = []
                
                for month in 1...12 {
                    if year == currentYear && month > currentMonth { continue }
                    
                    let monthString = String(format: "%02d", month)
                    let targetPrefix = "\(year)-\(monthString)-"
                    let daysInMonth = summaries.filter { $0.dateKey.hasPrefix(targetPrefix) }
                    
                    if !daysInMonth.isEmpty {
                        let totalIntake = daysInMonth.reduce(0.0) { $0 + $1.intakeCalories }
                        let totalBurned = daysInMonth.reduce(0.0) { $0 + $1.burnedCalories }
                        let totalTarget = daysInMonth.reduce(0.0) { $0 + $1.targetCalories }
                        let avgTarget = totalTarget / Double(daysInMonth.count)
                        
                        monthlyPoints.append(MetricPoint(
                            label: "T\(month)",
                            date: nil,
                            intakeCalories: totalIntake,
                            targetCalories: avgTarget * Double(daysInMonth.count),
                            burnedCalories: totalBurned,
                            hasPlan: avgTarget > 0
                        ))
                    } else {
                        monthlyPoints.append(MetricPoint(
                            label: "T\(month)",
                            date: nil,
                            intakeCalories: 0,
                            targetCalories: 0,
                            burnedCalories: 0,
                            hasPlan: false
                        ))
                    }
                }
                completion(.success(StatisticsReport(summaryPoints: monthlyPoints)))
            }
    }
}

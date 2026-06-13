import Foundation
import FirebaseAuth
import Combine
import SwiftUI

class StatisticsViewModel: ObservableObject {
    @Published var selectedTab: StatisticsTab = .week
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @Published var currentWeekStartDate: Date = Date()
    @Published var monthSliceIndex: Int = 0
    private let daysPerPage = 7
    
    @Published var report: StatisticsReport? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    init() {
        let calendar = Calendar.current
        var calendarWithMonday = calendar
        calendarWithMonday.firstWeekday = 2
        if let startOfWeek = calendarWithMonday.dateInterval(of: .weekOfYear, for: Date())?.start {
            self.currentWeekStartDate = startOfWeek
        }
    }
    
    var isDataEmpty: Bool {
        guard let points = report?.summaryPoints else { return true }
        return !points.contains(where: { $0.intakeCalories > 0 })
    }
    
    // Kiểm tra xem tuần đang xem có phải tuần hiện tại (hoặc tương lai) không để ẩn nút Next
    var isCurrentOrFutureWeek: Bool {
        let calendar = Calendar.current
        var calendarWithMonday = calendar
        calendarWithMonday.firstWeekday = 2
        guard let realStartOfCurrentWeek = calendarWithMonday.dateInterval(of: .weekOfYear, for: Date())?.start else { return true }
        return currentWeekStartDate >= realStartOfCurrentWeek
    }
    
    var visibleMonthPoints: [MetricPoint] {
        guard let points = report?.summaryPoints, selectedTab == .month else { return [] }
        let startIndex = monthSliceIndex * daysPerPage
        if startIndex >= points.count { return Array(points.suffix(daysPerPage)) }
        let endIndex = min(startIndex + daysPerPage, points.count)
        return Array(points[startIndex..<endIndex])
    }
    
    var maxMonthSliceIndex: Int {
        guard let points = report?.summaryPoints else { return 0 }
        return Int(ceil(Double(points.count) / Double(daysPerPage))) - 1
    }
    
    var monthSliceRangeString: String {
        let points = visibleMonthPoints
        guard let first = points.first, let last = points.last else { return "Giai đoạn" }
        return "Ngày \(first.label)-\(last.label)"
    }
    
    var macroData: [MacroElement] {
        guard let points = report?.summaryPoints, !points.isEmpty else { return [] }
        let activePoints = points.filter { $0.intakeCalories > 0 && $0.hasPlan }
        let targetList = activePoints.isEmpty ? points.filter({ $0.hasPlan }) : activePoints
        
        let totalCarbs = targetList.reduce(0.0) { $0 + $1.carbs }
        let totalProtein = targetList.reduce(0.0) { $0 + $1.protein }
        let totalFat = targetList.reduce(0.0) { $0 + $1.fat }
        let sum = totalCarbs + totalProtein + totalFat
        
        guard sum > 0 else { return [] }
        
        return [
            MacroElement(name: "Tinh bột", value: (totalCarbs / sum) * 100, color: .blue),
            MacroElement(name: "Chất đạm", value: (totalProtein / sum) * 100, color: .red),
            MacroElement(name: "Chất béo", value: (totalFat / sum) * 100, color: .orange)
        ]
    }
    
    var isTrendUp: Bool {
        guard let points = report?.summaryPoints, !points.isEmpty else { return true }
        let validPoints = points.filter { $0.date ?? Date() <= Date() && $0.intakeCalories > 0 && $0.hasPlan }
        if validPoints.isEmpty { return true }
        
        let totalIntake = validPoints.reduce(0.0) { $0 + $1.intakeCalories }
        let totalTarget = validPoints.reduce(0.0) { $0 + $1.targetCalories }
        return totalIntake >= totalTarget
    }
    
    var avgIntakePerDay: Int {
        guard let points = report?.summaryPoints, !points.isEmpty else { return 0 }
        let pointsWithData = points.filter { $0.intakeCalories > 0 }
        if pointsWithData.isEmpty { return 0 }
        return Int(pointsWithData.reduce(0.0) { $0 + $1.intakeCalories } / Double(pointsWithData.count))
    }
    
    var avgBurnedPerDay: Int {
        guard let points = report?.summaryPoints, !points.isEmpty else { return 0 }
        let pointsWithData = points.filter { $0.burnedCalories > 0 }
        if pointsWithData.isEmpty { return 0 }
        return Int(pointsWithData.reduce(0.0) { $0 + $1.burnedCalories } / Double(pointsWithData.count))
    }
    
    var weekRangeString: String {
        let calendar = Calendar.current
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: currentWeekStartDate) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return "\(formatter.string(from: currentWeekStartDate)) - \(formatter.string(from: endOfWeek))"
    }
    
    func changeWeek(by value: Int) {
        let calendar = Calendar.current
        if let newStartDate = calendar.date(byAdding: .weekOfYear, value: value, to: currentWeekStartDate) {
            // Chặn không cho bấm tiến về tuần tương lai
            if value > 0 && isCurrentOrFutureWeek { return }
            
            currentWeekStartDate = newStartDate
            loadStatistics(targetDate: currentWeekStartDate)
        }
    }
    
    func loadStatistics(targetDate: Date) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.isLoading = true
        self.errorMessage = nil
        
        let handler: (Result<StatisticsReport, Error>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let data):
                    self.report = data
                    
                    // MẶC ĐỊNH: Nếu là tháng hiện tại, nhảy đến khung thời gian chứa ngày hôm nay
                    if self.selectedTab == .month {
                        let calendar = Calendar.current
                        let now = Date()
                        let currentMonth = calendar.component(.month, from: now)
                        let currentYear = calendar.component(.year, from: now)
                        
                        if self.selectedMonth == currentMonth && self.selectedYear == currentYear {
                            let today = calendar.component(.day, from: now)
                            self.monthSliceIndex = (today - 1) / self.daysPerPage
                        } else {
                            self.monthSliceIndex = 0
                        }
                    } else {
                        self.monthSliceIndex = 0
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        
        switch selectedTab {
        case .week:
            FirebaseService.shared.fetchWeeklyStatistics(userId: userId, for: currentWeekStartDate, completion: handler)
        case .month:
            FirebaseService.shared.fetchMonthlyStatistics(userId: userId, month: selectedMonth, year: selectedYear, completion: handler)
        case .year:
            FirebaseService.shared.fetchYearlyStatistics(userId: userId, year: selectedYear, completion: handler)
        }
    }
}

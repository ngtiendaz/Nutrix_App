//
//  Statistics.swift
//  Nutrix
//
//  Created by Daz on 18/5/26.
//

import Foundation
import SwiftUI

// MARK: - Chế độ xem thống kê
enum StatisticsTab {
    case week   // Thống kê 7 ngày trong tuần hiện tại
    case month  // Thống kê các ngày trong tháng
    case year   // Thống kê 12 tháng trong năm
}

// MARK: - Trạng thái hoàn thành dinh dưỡng của một ngày
enum CompletionStatus: String {
    case perfect = "Đạt mục tiêu"
    case over = "Vượt mục tiêu"
    case under = "Chưa đạt"
    case noPlan = "Không có lộ trình" // Trạng thái mới giải quyết việc hiển thị sai
}

struct MetricPoint: Identifiable {
    let id = UUID()
    let label: String
    let date: Date?
    var intakeCalories: Double
    var targetCalories: Double
    var burnedCalories: Double
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    
    // Thuộc tính nhận biết ngày này có Plan thực tế từ Firebase hay không
    var hasPlan: Bool = true
    
    var completionRate: Double {
        guard hasPlan && targetCalories > 0 else { return 0 }
        return (intakeCalories / targetCalories) * 100
    }
    
    var status: CompletionStatus {
        if !hasPlan { return .noPlan } // Nếu không có lộ trình, không xét đạt hay thiếu
        
        let rate = completionRate
        if rate >= 90 && rate <= 110 { return .perfect }
        else if rate > 110 { return .over }
        else { return .under }
    }
}
// MARK: - Wrapper tổng hợp cuối cùng trả về cho Thống kê
struct StatisticsReport {
    let summaryPoints: [MetricPoint] // Mảng dữ liệu đã sắp xếp thời gian để đưa vào Chart và List
    
    // Các chỉ số trung bình trong cả chu kỳ (Tháng/Năm) đã chọn
    var avgIntakeCalories: Double {
        guard !summaryPoints.isEmpty else { return 0 }
        return summaryPoints.reduce(0) { $0 + $1.intakeCalories } / Double(summaryPoints.count)
    }
    
    var avgCompletionRate: Double {
        guard !summaryPoints.isEmpty else { return 0 }
        return summaryPoints.reduce(0) { $0 + $1.completionRate } / Double(summaryPoints.count)
    }
}
struct MacroElement: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let color: SwiftUI.Color
}

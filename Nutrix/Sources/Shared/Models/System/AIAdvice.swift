//
//  AIAdvice.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//
import Foundation
import SwiftUI

// Định nghĩa cấu trúc dữ liệu khuyên dùng từ AI khớp với JSON bóc tách
struct AIAdvice: Codable {
    let status: String // "success", "warning", "danger", "info"
    let title: String  // Khóa cứng: 'Bữa ăn hợp lý' | 'Cần bổ sung thêm' | 'Không nên ăn' | 'Cần giảm khẩu phần'
    let timingAnalysis: String
    let macroBalance: String
    let portionRecommendation: String
    let actionTip: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "success": return .green
        case "warning": return .orange
        case "danger": return .red
        default: return .blue
        }
    }
    
    var iconName: String {
        switch status.lowercased() {
        case "success": return "checkmark.circle.fill"
        case "warning": return "exclamationmark.triangle.fill"
        case "danger": return "exclamationmark.octagon.fill"
        default: return "info.circle.fill"
        }
    }
}

//
//  ColorApp.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

extension Color {
    struct App {
            // Màu nền chính của app (màu trắng xám nhẹ - Giữ nguyên)
            static let background = Color(hex: "F7F7F7")
            
            // --- MÀU CHỦ ĐẠO MỚI (Xanh lá dịu mắt) ---
            // Màu xanh này gọi là "Soft Forest Green", nhìn rất chuyên nghiệp và dễ chịu
            static let primary = Color(hex: "4A7C59")
            
            // Màu xanh nhạt để làm highlight (nền cho icon đang chọn)
            static let primaryLight = Color(hex: "E8F0E9")
            // -----------------------------------------

            // Màu nền của thanh Menu
            static let menuBackground = Color.white
            
            // Màu nền phụ (cho các card hoặc ô lịch)
            static let secondaryBackground = Color(hex: "F2F2F2")
            
            // Màu text xám nhạt
            static let lightGray = Color(hex: "A6A6A6")
        }
}

// Helper để dùng mã Hex cho dễ quản lý
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

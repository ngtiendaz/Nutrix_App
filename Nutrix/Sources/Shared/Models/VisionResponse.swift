//
//  VisionResponse.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//

import Foundation

// Model chính hứng trọn JSON trả về
struct VisionResponse: Codable {
    let responses: [AnnotatedResponse]
}

struct AnnotatedResponse: Codable {
    let labelAnnotations: [LabelAnnotation]?
}

struct LabelAnnotation: Codable, Identifiable {
    var id: String { mid } // Dùng mid làm ID để hiển thị trong List SwiftUI
    let mid: String
    let description: String
    let score: Float
    let topicality: Float
    
    // Hàm format điểm số sang phần trăm (ví dụ: 0.98 -> 98%)
    var confidencePercentage: String {
        return String(format: "%.0f%%", score * 100)
    }
}

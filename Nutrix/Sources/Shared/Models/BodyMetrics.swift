//
//  BodyMetrics.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//
import FirebaseFirestore

struct BodyMetrics: Identifiable {
    var id: String
    var height: Double
    var weight: Double
    var status: String
    var timestamp: Date
    
    // Thêm thuộc tính để lưu chênh lệch (sẽ tính toán khi fetch)
    var weightDiff: Double = 0.0
    var percentChange: Double = 0.0

    init(id: String, dictionary: [String: Any]) {
        self.id = id
        self.height = dictionary["height"] as? Double ?? 0.0
        self.weight = dictionary["weight"] as? Double ?? 0.0
        self.status = dictionary["status"] as? String ?? ""
        let firebaseTimestamp = dictionary["timestamp"] as? FirebaseFirestore.Timestamp
        self.timestamp = firebaseTimestamp?.dateValue() ?? Date()
    }
}

//
//  Users.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation
import FirebaseFirestore

struct User: Codable {
    let userId: String
    let email: String
    let name: String
    
    var age: Int?
    var gender: String?
    var height: Double?
    var weight: Double?
    var activityLevel: String?
    var goal: String?
    
    let createdAt: Date
    
    init(dictionary: [String: Any]) {
        self.userId = dictionary["userId"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? "User"
        self.age = dictionary["age"] as? Int
        self.gender = dictionary["gender"] as? String
        self.height = dictionary["height"] as? Double
        self.weight = dictionary["weight"] as? Double
        self.activityLevel = dictionary["activityLevel"] as? String
        self.goal = dictionary["goal"] as? String
        self.createdAt = (dictionary["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}

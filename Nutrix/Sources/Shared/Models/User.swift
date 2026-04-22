//
//  Users.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation

struct User: Codable {
    let userId: String
    let email: String
    let name: String
    
    let age : Int
    let gender : String
    let height : Double
    let weight : Double
    
    let activityLevel : String
    let goal : String
    
    let createdAt: Date
}

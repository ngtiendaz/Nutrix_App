//
//  AIAdvice.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//
import Foundation
import SwiftUI

struct AIAdvice {
    let title: String
    let message: String
    let statusColor: Color
    let iconName: String
}


struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

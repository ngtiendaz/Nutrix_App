//
//  ToastData.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//

import Foundation

struct ToastData: Equatable, Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
}
enum ToastType: Equatable {
    case success
    case error
}

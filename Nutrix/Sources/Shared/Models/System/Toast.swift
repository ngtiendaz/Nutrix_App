//
//  Toast.swift
//  Nutrix
//
//  Created by Daz on 18/5/26.
//

enum ToastType {
    case success, error
}

struct ToastData {
    let message: String
    let type: ToastType
}

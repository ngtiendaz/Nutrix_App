//
//  RollingNumber.swift
//  Nutrix
//
//  Created by Daz on 6/5/26.
//

import SwiftUI

struct RollingNumber: ViewModifier, Animatable {
    var number: Double
    
    // SwiftUI sẽ dùng biến này để tính toán các giá trị trung gian khi chạy animation
    var animatableData: Double {
        get { number }
        set { number = newValue }
    }
    
    func body(content: Content) -> some View {
        Text("\(Int(number))")
    }
}

// Extension để dùng cho tiện
extension View {
    func rollingNumber(value: Double) -> some View {
        self.modifier(RollingNumber(number: value))
    }
}

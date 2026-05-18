//
//  NutrientValue.swift
//  Nutrix
//
//  Created by Daz on 5/5/26.
//

import SwiftUI

struct NutrientSmallView: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.App.tiny)
                .foregroundColor(color.opacity(0.8))
            Text("\(Int(value))g")
                .font(.App.caption)
                .foregroundColor(Color(hex: "555555"))
        }
    }
}

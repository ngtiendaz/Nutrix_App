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
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color.opacity(0.8))
            Text("\(Int(value))g")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "555555"))
        }
    }
}

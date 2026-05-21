//
//  NutrientMiniCard.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//

import SwiftUI

struct NutrientMiniCard: View {
    let title: String
    let value: Double
    let color: Color
    var unit: String = "g"

    private var formattedValue: String {
        unit == "g" ? "\(Int(value))g" : "\(Int(value)) \(unit)"
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(formattedValue)
                .font(.App.bodyBold)
                .foregroundColor(.black)
            ZStack(alignment: .leading) {
                Capsule().frame(height: 4).foregroundColor(color.opacity(0.1))
                Capsule().frame(width: 30, height: 4).foregroundColor(color)
            }
            Text(title).font(.App.captionMedium).foregroundColor(Color.App.lightGray)
        }
        .frame(maxWidth: .infinity)
    }
}



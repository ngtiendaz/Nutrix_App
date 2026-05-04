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
    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(value))g").font(.system(size: 16, weight: .bold)).foregroundColor(.black)
            ZStack(alignment: .leading) {
                Capsule().frame(height: 4).foregroundColor(color.opacity(0.1))
                Capsule().frame(width: 30, height: 4).foregroundColor(color)
            }
            Text(title).font(.system(size: 12)).foregroundColor(Color.App.lightGray)
        }
        .frame(maxWidth: .infinity)
    }
}



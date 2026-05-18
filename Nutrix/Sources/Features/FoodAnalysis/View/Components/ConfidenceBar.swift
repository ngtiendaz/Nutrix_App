//
//  ConfidenceBar.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//

import SwiftUI

struct ConfidenceBar: View {
    let value: Double // 0 → 1

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye.fill")
                .foregroundColor(.gray)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                    
                    Capsule()
                        .fill(Color.green)
                        .frame(width: geo.size.width * value)
                }
            }
            .frame(height: 8)

            Text("\(Int(value * 100))%")
                .foregroundColor(.gray)
                .font(.App.body)
        }
    }
}

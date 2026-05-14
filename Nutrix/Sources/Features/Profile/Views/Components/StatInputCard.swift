//
//  StatInputCard.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//

import SwiftUI

struct StatInputCard: View {
    let title: String
    @Binding var value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                TextField("0", text: $value)
                    .font(.system(size: 24, weight: .bold))
                    .keyboardType(.decimalPad)
                Text(unit)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white) // Giả định background app của bạn hơi xám
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}


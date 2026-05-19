//
//  SelectionCard.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//

import SwiftUI

struct SelectionCard: View {
    let title: String
    let icon: String
    let color: Color
    var iconColor: Color = .white
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(Font.system(size: 32))
                .foregroundColor(iconColor)
            Text(title)
                .font(.App.sectionHeader)
                .foregroundColor(iconColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(color)
        .cornerRadius(25)
    }
}

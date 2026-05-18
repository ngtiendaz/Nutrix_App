//
//  InfoRow.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//
import SwiftUI

struct InfoRow: View {
    let label: String
    @Binding var value: String
    var unit: String? = nil
    let isEditing: Bool
    let placeholder: String
    
    var body: some View {
        HStack(spacing: 0) {
            // Nhãn cố định 100pt
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 100, alignment: .leading)
            
            Text(":")
                .foregroundColor(.black)
                .padding(.trailing, 10)
            
            Group {
                if isEditing {
                    HStack(spacing: 5) {
                        TextField(placeholder, text: $value)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                            .keyboardType(unit != nil ? .decimalPad : .default)
                        
                        if let unit = unit {
                            Text(unit)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 40) // Chiều cao cố định
                    .background(Color.black.opacity(0.04))
                    .cornerRadius(10)
                } else {
                    HStack(spacing: 4) {
                        Text(value.isEmpty ? "--" : value)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                        
                        if let unit = unit, !value.isEmpty {
                            Text(unit)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12) // Padding bằng với lúc Edit
                    .frame(height: 40) // Chiều cao bằng với lúc Edit
                    .background(Color.clear) // Để giữ nguyên diện tích chiếm dụng
                }
            }
        }
    }
}

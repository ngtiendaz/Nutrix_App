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
    var onEditing: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            // Nhãn cố định 100pt
            Text(label)
                .font(.App.headline)
                .foregroundColor(.black)
                .frame(width: 100, alignment: .leading)
            
            Text(":")
                .foregroundColor(.black)
                .padding(.trailing, 10)
            
            Group {
                if isEditing {
                    HStack(spacing: 5) {
                        TextField(placeholder, text: $value, onEditingChanged: { beginning in
                            if beginning {
                                onEditing?()
                            }
                        })
                            .font(.App.headline)
                            .foregroundColor(.black)
                            .keyboardType(unit != nil ? .decimalPad : .default)
                        
                        if let unit = unit {
                            Text(unit)
                                .font(.App.body)
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
                            .font(.App.headline)
                            .foregroundColor(.black)
                        
                        if let unit = unit, !value.isEmpty {
                            Text(unit)
                                .font(.App.body)
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

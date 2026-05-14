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
            // Cố định độ rộng nhãn là 100
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 100, alignment: .leading)
            
            Text(":")
                .foregroundColor(.black)
                .padding(.trailing, 10)
            
            ZStack(alignment: .leading) {
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
                    .padding(.horizontal, 10)
                    .frame(height: 36) // Cố định chiều cao vùng nhập
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    HStack(spacing: 4) {
                        Text(value.isEmpty ? "--" : value)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        if let unit = unit, !value.isEmpty {
                            Text(unit)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer() // Đẩy nội dung về bên trái
                    }
                    .frame(height: 36) // Giữ chiều cao bằng với khi Edit
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

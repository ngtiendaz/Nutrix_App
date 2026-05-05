//
//  CustomSecureField.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//
import SwiftUI


struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @State private var isVisible: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.App.primary.opacity(0.7))
                .frame(width: 25)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.black.opacity(0.8))
                }
                
                HStack {
                    if isVisible {
                        TextField("", text: $text)
                            .autocapitalization(.none)
                            .foregroundColor(.black)
                    } else {
                        SecureField("", text: $text)
                            .foregroundColor(.black)
                    }
                    
                    Button(action: { isVisible.toggle() }) {
                        Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}

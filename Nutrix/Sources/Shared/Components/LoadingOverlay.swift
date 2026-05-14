//
//  LoadingOverlay.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//

import SwiftUI

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 15) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                
                Text("Đang lưu...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(Color.black.opacity(0.6))
            .cornerRadius(16)
        }
    }
}

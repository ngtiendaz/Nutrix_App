//
//  SplashScreenView.swift
//  Nutrix
//
//  Created by Daz on 5/5/26.
//
import SwiftUI

struct SplashScreenView: View {
    @State private var opacity = 0.0
    @State private var scale = 1.05 // Tạo hiệu ứng zoom nhẹ khi xuất hiện
    
    var body: some View {
        ZStack {
          
            Color.App.background.ignoresSafeArea()
            
            Image("AppSplash")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
                .clipped()
                .scaleEffect(scale)
                .opacity(opacity)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0)) {
                self.opacity = 1.0
                self.scale = 1.0
            }
        }
    }
}

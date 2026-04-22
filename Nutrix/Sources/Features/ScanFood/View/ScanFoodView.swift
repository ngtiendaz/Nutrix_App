//
//  NutritionCameraView.swift
//  Nutrix
//
//  Created by Daz on 23/4/26.
//
import SwiftUI

import SwiftUI

struct ScanFoodView: View {
    @StateObject private var scanFoodViewModel = ScanFoodViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var scannerOffset: CGFloat = -140
    
    var body: some View {
        ZStack {
            CameraPreview(session: scanFoodViewModel.session)
                .ignoresSafeArea()
            
            Color.black.opacity(0.4)
                .mask(
                    ZStack {
                        Rectangle()
                        RoundedRectangle(cornerRadius: 25)
                            .frame(width: 280, height: 280)
                            .blendMode(.destinationOut)
                    }
                )
                .compositingGroup()
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Nutrix AI Scanner")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { /* Toggle Flash logic */ }) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 280, height: 280)
                
                    ScannerCorners()
                        .stroke(Color.green, lineWidth: 4)
                        .frame(width: 280, height: 280)
                    
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, .green.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
                            .frame(width: 260, height: 40)
                        
                        Rectangle() // Sợi chỉ sáng ở giữa
                            .fill(Color.green)
                            .frame(width: 260, height: 2)
                            .blur(radius: 1)
                    }
                    .offset(y: scannerOffset)
                }
                
                Text("Đang phân tích món ăn...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.top, 25)
                
                Spacer()
                
                // --- BOTTOM CONTROLS ---
                HStack(spacing: 50) {
                    // Nút Album
                    Spacer()
                    
                    // Nút chụp chính (Haptic feedback)
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()
                        print("Taking photo for AI analysis...")
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 82, height: 82)
                        }
                    }
                    
                    // Nút đổi Camera
                    Button(action: { /* Switch camera logic */ }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            scanFoodViewModel.checkPermissionAndSetup()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                scannerOffset = 140
            }
        }
    }
}

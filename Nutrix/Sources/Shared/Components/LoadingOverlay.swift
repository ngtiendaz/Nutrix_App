//
//  LoadingOverlay.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//
import SwiftUI

struct LoadingOverlay: View {
    var text: String = "Đang tải..."
    
    // State điều khiển góc xoay của hiệu ứng
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Lớp nền mờ nhẹ toàn màn hình giúp cô lập giao diện bên dưới
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Hiệu ứng vòng xoay cá nhân hóa tinh tế
                ZStack {
                    // 1. Vòng tròn tĩnh làm nền mờ phía dưới tạo chiều sâu
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        .frame(width: 50, height: 50)
                    
                    // 2. Vòng nét cắt chuyển màu chạy vô tận sử dụng màu Soft Forest Green
                    Circle()
                        .trim(from: 0.0, to: 0.65) // Độ dài của cung tròn xoay
                        .stroke(
                            LinearGradient(
                                colors: [Color.App.primary, Color.App.primary.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round) // Bo tròn 2 đầu nét cắt
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                }
                .onAppear {
                    // Kích hoạt hiệu ứng quay tuyến tính liên tục
                    withAnimation(.linear(duration: 0.85).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
                
                // Dòng chữ hiển thị - Đã bỏ hoàn toàn khung nền Card thô cứng
                Text(text)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    // Thêm bóng mờ nhẹ cho text để hiển thị cực rõ nét trên mọi loại ảnh nền bên dưới
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
    }
}

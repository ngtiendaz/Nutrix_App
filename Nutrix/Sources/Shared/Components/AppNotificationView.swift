//
//  ToastCard.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//
import SwiftUI

struct AppNotificationView: View {
    let data: ToastData?
    
    var body: some View {
        if let data = data {
            VStack {
                // Nội dung thông báo
                HStack(spacing: 15) {
                    // Icon đại diện cho trạng thái
                    Image(systemName: data.type == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.type == .success ? "Thành công" : "Thông báo")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(data.message)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .frame(maxWidth: UIScreen.main.bounds.width - 32) // Giới hạn chiều rộng để trông giống Banner
                .background(
                    ZStack {
                        // Nền gradient nhẹ để sang trọng hơn
                        LinearGradient(
                            colors: [
                                data.type == .success ? Color.green : Color.red,
                                data.type == .success ? Color.green.opacity(0.8) : Color.red.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Hiệu ứng bắt sáng (Glossy)
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 40)
                            .offset(y: -20)
                            .blur(radius: 10)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: (data.type == .success ? Color.green : Color.red).opacity(0.3), radius: 15, x: 0, y: 8)
                .padding(.top, safeAreaTop)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .scale(scale: 0.8).combined(with: .opacity)
                ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .onAppear {
                triggerHaptic(type: data.type)
            }
        }
    }
    
    // Lấy khoảng cách an toàn phía trên (tai thỏ)
    private var safeAreaTop: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return (windowScene?.windows.first?.safeAreaInsets.top ?? 44) + 8
    }
    
    // Phản hồi rung khi hiện thông báo
    private func triggerHaptic(type: ToastType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type == .success ? .success : .error)
    }
}

// Giả định ToastType của bạn có 2 case này
enum ToastType {
    case success, error
}

struct ToastData {
    let message: String
    let type: ToastType
}

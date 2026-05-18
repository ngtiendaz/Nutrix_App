//
//  ToastCard.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//
import SwiftUI

struct AppNotificationView: View {
    let data: ToastData?
    
    // Sử dụng router để có thể can thiệp ẩn toast khi người dùng vuốt lên
    @EnvironmentObject var router: AppRouter
    
    // State quản lý khoảng cách kéo của ngón tay
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        if let data = data {
            VStack {
                // Toàn bộ khối nội dung Banner thông báo (Đã thu gọn padding)
                HStack(spacing: 12) {
                    // Vùng chứa Icon (Thu nhỏ từ 22x22 padded 10 xuống 15x15 padded 7)
                    Image(systemName: data.type == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.App.headline)
                        .foregroundColor(data.type == .success ? Color.App.primary : Color(hex: "BC4749"))
                        .padding(7)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    
                    // Nội dung Text - Tinh chỉnh size chữ nhỏ gọn, sang trọng hơn
                    VStack(alignment: .leading, spacing: 1) {
                        Text(data.type == .success ? "Thành công" : "Thông báo")
                            .font(.App.tiny)
                            .foregroundColor(.white.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Text(data.message)
                            .font(.App.subheadline) // Giảm từ 15 xuống 13
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // Icon chevrons siêu mảnh thanh lịch
                    Image(systemName: "chevron.compact.up")
                        .font(.App.captionMedium)
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.trailing, 2)
                }
                .padding(.vertical, 10) // Thu hẹp độ dày từ 14 xuống 10
                .padding(.horizontal, 14)
                .frame(maxWidth: UIScreen.main.bounds.width - 40) // Bo gọn chiều rộng hơn một chút
                .background(
                    ZStack {
                        LinearGradient(
                            colors: [
                                data.type == .success ? Color.App.primary : Color(hex: "BC4749"),
                                data.type == .success ? Color.App.primary.opacity(0.92) : Color(hex: "A34848")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Đường bắt sáng nhẹ tinh tế
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 25)
                            .offset(y: -16)
                            .blur(radius: 6)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // Góc bo mượt mà hơn
                .shadow(
                    color: (data.type == .success ? Color.App.primary : Color(hex: "BC4749")).opacity(0.18),
                    radius: 10, x: 0, y: 5
                )
                .padding(.top, safeAreaTop)
                .offset(y: dragOffset)
                // Hiệu ứng di chuyển mượt mà không bị khựng hình
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Chỉ cho phép kéo ngược lên trên
                            if value.translation.height < 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            // Sử dụng predictedEndTranslation để tính toán lực vuốt (Velocity)
                            // Người dùng chỉ cần hất nhẹ (bất kể khoảng cách ngắn) là banner tự bay mất mượt mà
                            let swipeForce = value.predictedEndTranslation.height
                            
                            if swipeForce < -30 || value.translation.height < -20 {
                                // Hiệu ứng biến mất dạng "flick" tốc độ cao cực mượt
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                    dragOffset = -150
                                    router.toast = nil
                                }
                            } else {
                                // Trả về vị trí cũ nếu lực vuốt không đủ
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .onAppear {
                triggerHaptic(type: data.type)
            }
            .onDisappear {
                dragOffset = 0
            }
        }
    }
    
    private var safeAreaTop: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return (windowScene?.windows.first?.safeAreaInsets.top ?? 44) + 4
    }
    
    private func triggerHaptic(type: ToastType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type == .success ? .success : .error)
    }
}

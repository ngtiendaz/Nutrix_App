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
                // Toàn bộ khối nội dung Banner thông báo
                HStack(spacing: 16) {
                    // Vùng chứa Icon với vòng tròn bọc ngoài tăng độ tương phản
                    Image(systemName: data.type == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(data.type == .success ? Color.App.primary : Color(hex: "BC4749"))
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    // Nội dung Text (Tiêu đề & Tin nhắn)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(data.type == .success ? "Thành công" : "Có lỗi xảy ra")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                            .textCase(.uppercase)
                        
                        Text(data.message)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // Icon gợi ý nhỏ để người dùng biết có thể vuốt lên để đóng
                    Image(systemName: "chevron.compact.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.trailing, 4)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(maxWidth: UIScreen.main.bounds.width - 32)
                .background(
                    ZStack {
                        // Nền màu đồng bộ cao cấp dựa trên mã màu App.primary
                        LinearGradient(
                            colors: [
                                data.type == .success ? Color.App.primary : Color(hex: "BC4749"),
                                data.type == .success ? Color.App.primary.opacity(0.9) : Color(hex: "A34848")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Hiệu ứng Glossy/Bắt sáng nhẹ phía trên
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 35)
                            .offset(y: -22)
                            .blur(radius: 8)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                // Đổ bóng mềm hiện đại
                .shadow(
                    color: (data.type == .success ? Color.App.primary : Color(hex: "BC4749")).opacity(0.25),
                    radius: 12, x: 0, y: 6
                )
                .padding(.top, safeAreaTop)
                // Áp dụng khoảng cách ngón tay kéo lên trực tiếp vào ViewY Offset
                .offset(y: dragOffset)
                // Cấu hình hiệu ứng trượt xuất hiện từ đỉnh màn hình và thu nhỏ khi biến mất
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                // Giao thức Gesture xử lý kéo vuốt (Swipe)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Chỉ cho phép vuốt kéo lên trên (translation nhỏ hơn 0)
                            if value.translation.height < 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            // Nếu vuốt lên quá -30pt thì kích hoạt xóa / đóng Toast lập tức
                            if value.translation.height < -30 {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    router.toast = nil
                                }
                            } else {
                                // Nếu vuốt chưa đủ tầm, trả view về vị trí cũ một cách mượt mà
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
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
                // Reset lại toạ độ kéo về 0 chuẩn bị cho lần hiển thị thông báo kế tiếp
                dragOffset = 0
            }
        }
    }
    
    // Lấy khoảng cách an toàn phía trên (Hỗ trợ tốt Tai thỏ / Dynamic Island)
    private var safeAreaTop: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return (windowScene?.windows.first?.safeAreaInsets.top ?? 44) + 6
    }
    
    // Phản hồi rung vật lý chất lượng cao (Haptic Feedback)
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

import SwiftUI

struct AppNotificationView: View {
    let data: ToastData?
    @EnvironmentObject var router: AppRouter
    @State private var dragOffset: CGFloat = 0
    
    // Sử dụng màu chủ đạo từ Color.App
    private var toastColor: Color {
        data?.type == .success ? Color.App.primary : Color(hex: "BC4749")
    }
    
    var body: some View {
        if let data = data {
            VStack {
                HStack(spacing: 12) {
                    // Icon bo tròn trắng
                    Image(systemName: data.type == .success ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(toastColor)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                    
                    // Nội dung Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.type == .success ? "Thành công" : "Thất bại")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(data.message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Thời gian hiển thị
                    Text("bây giờ")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.trailing, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(toastColor)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: toastColor.opacity(0.3), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
                .padding(.top, safeAreaTop)
                .offset(y: dragOffset)
                .transition(.move(edge: .top).combined(with: .opacity))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height < 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height < -20 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    dragOffset = -150
                                    router.toast = nil
                                }
                            } else {
                                withAnimation(.spring()) { dragOffset = 0 }
                            }
                        }
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .onAppear { triggerHaptic(type: data.type) }
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

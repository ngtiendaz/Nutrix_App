import SwiftUI

struct ActivityDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    @ObservedObject var viewModel: ActivityViewModel
    var userId: String
    let log: UserActivityLog
    var date: Date
    
    @State private var duration: String = ""
    @State private var isExpanded = false // Quản lý trạng thái ẩn/hiện công thức chi tiết
    
    // SỬA ĐỔI: Khởi tạo init để cấu hình cứng thanh NavigationBar chữ đen nền trắng mặc định
    init(viewModel: ActivityViewModel, userId: String, log: UserActivityLog, date: Date) {
        self.viewModel = viewModel
        self.userId = userId
        self.log = log
        self.date = date
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white // Nền trắng tinh tế cho header
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.black, // Chữ đen mặc định
            .font: UIFont.systemFont(ofSize: 16, weight: .bold)
        ]
        
        // Áp dụng cấu hình cho toàn bộ trạng thái cuộn của màn hình chi tiết
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // LỚP NỀN: Nhận tương tác Tap để ẩn bàn phím khi bấm ra ngoài
                Color.App.background
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // 1. Header Section (Hiển thị Icon, Tên và Ngày Giờ Tạo)
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.App.primaryLight)
                                        .frame(width: 90, height: 90)
                                    
                                    Image(systemName: log.activityType.icon)
                                        .font(.App.large)
                                        .foregroundColor(Color.App.primary)
                                }
                                .padding(.top, 10)
                                
                                VStack(spacing: 6) {
                                    Text(log.activityType.name)
                                        .font(.App.header)
                                        .foregroundColor(.black)
                                    
                                    // Hiển thị: Ngày giờ ghi nhận hoạt động từ thuộc tính log.createdAt
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar.badge.clock")
                                        Text("Ghi nhận lúc: \(formatLogDate(log.createdAt))")
                                    }
                                    .font(.App.subheadlineRegular)
                                    .foregroundColor(.gray)
                                }
                            }
                            .onTapGesture { hideKeyboard() }
                            
                            // 2. Input & Thông số Card chính
                            VStack(alignment: .leading, spacing: 16) {
                                Text("THỜI GIAN TẬP LUYỆN")
                                    .font(.App.small)
                                    .foregroundColor(Color.App.primary)
                                    .tracking(1)
                                
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(Color.App.primary)
                                    
                                    TextField("0", text: $duration)
                                        .font(.App.header)
                                        .foregroundColor(.black)
                                        .keyboardType(.numberPad)
                                    
                                    Text("phút")
                                        .font(.App.headline)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.App.secondaryBackground.opacity(0.5))
                                .cornerRadius(15)
                                
                                Divider().background(Color.black.opacity(0.04))
                                
                                // Khối hiển thị Calo đốt cháy dự tính thời gian thực
                                if let min = Double(duration), min > 0 {
                                    let currentMet = log.activityType.metValue
                                    let calculatedCalories = (viewModel.userWeight > 0 && viewModel.userHeight > 0) ?
                                        calculateRealtimeCalories(met: currentMet, duration: min) :
                                        log.caloriesBurned * (min / log.durationMinutes)
                                    
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange.opacity(0.15))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "flame.fill")
                                                .foregroundColor(.orange)
                                                .font(.App.bodyLarge)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Năng lượng tiêu thụ")
                                                .font(.App.captionMedium)
                                                .foregroundColor(.gray)
                                            Text("~\(Int(calculatedCalories)) Kcal")
                                                .font(.App.title2)
                                                .foregroundColor(.black)
                                        }
                                        Spacer()
                                    }
                                    .padding(.top, 2)
                                }
                                
                                Divider().background(Color.black.opacity(0.04))
                                
                                // Khối kén màu sắc thể hiện các mốc chỉ số áp dụng từ Service
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Chỉ số áp dụng tính toán:")
                                        .font(.App.caption)
                                        .foregroundColor(.black.opacity(0.7))
                                    
                                    HStack(spacing: 8) {
                                        // Thẻ hệ số MET bài tập
                                        HStack(spacing: 4) {
                                            Image(systemName: "bolt.heart.fill").font(.App.tinyMedium)
                                            Text("MET: \(String(format: "%.1f", log.activityType.metValue))")
                                        }
                                        .font(.App.small)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Color.orange.opacity(0.08)).foregroundColor(.orange).cornerRadius(8)
                                        
                                        // Thẻ Cân nặng lấy từ ViewModel
                                        HStack(spacing: 4) {
                                            Image(systemName: "scalemass.fill").font(.App.tinyMedium)
                                            Text("Nặng: \(viewModel.userWeight > 0 ? "\(Int(viewModel.userWeight)) kg" : "-- kg")")
                                        }
                                        .font(.App.small)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.08)).foregroundColor(.blue).cornerRadius(8)
                                        
                                        // Thẻ Chiều cao lấy từ ViewModel
                                        HStack(spacing: 4) {
                                            Image(systemName: "figure.stand").font(.App.tinyMedium)
                                            Text("Cao: \(viewModel.userHeight > 0 ? "\(Int(viewModel.userHeight)) cm" : "-- cm")")
                                        }
                                        .font(.App.small)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.08)).foregroundColor(.purple).cornerRadius(8)
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            
                            // 3. Khối giải trình thuật toán thu gọn chuyên nghiệp
                            formulaExplanationCard
                                .padding(.horizontal)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 140)
                        .background(
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture { hideKeyboard() }
                        )
                    }
                    
                    // 4. Action Buttons dưới đáy cố định
                    VStack(spacing: 12) {
                        Button(action: handleUpdate) {
                            Text("Lưu thay đổi")
                                .font(.App.bodyBold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.App.primary)
                                .cornerRadius(18)
                                .shadow(color: Color.App.primary.opacity(0.25), radius: 10, x: 0, y: 5)
                        }
                        
                        Button(action: handleDelete) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                Text("Xóa hoạt động khỏi nhật ký")
                            }
                            .font(.App.sectionHeader)
                            .foregroundColor(.red)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .background(Color.clear.shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: -4))
                }
            }
            // ĐÃ CẬP NHẬT CHUẨN XÁC: Tiêu đề trung tâm chữ đen nền trắng mặc định hệ thống
            .navigationTitle("Chi tiết hoạt động")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundColor(.black)
                        .font(.App.headline)
                }
            }
            .onTapGesture { hideKeyboard() }
            .onAppear {
                duration = "\(Int(log.durationMinutes))"
                viewModel.getUserLogs(userId: userId, date: date)
            }
        }
    }
}

// MARK: - Thành phần UI bổ trợ mở rộng
extension ActivityDetailView {
    
    private func formatLogDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm - dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private var formulaExplanationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.App.subheadlineRegular)
                    .foregroundColor(Color.App.primary)
                Text("Cơ sở tính toán khoa học")
                    .font(.App.subheadline)
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Thu gọn" : "Xem thêm")
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .font(.App.caption)
                    .foregroundColor(Color.App.primary)
                }
            }
            
            Text("Lượng tiêu hao được ước tính tự động dựa trên chỉ số trao đổi chất cốt lõi (BMR) kết hợp với cường độ gắng sức (MET) của bài tập:")
                .font(.App.captionMedium)
                .foregroundColor(.gray)
                .lineSpacing(4)
            
            VStack(spacing: 4) {
                Text("Calories = (BMR / 1440) × MET × Thời gian")
                    .font(.App.caption)
                    .foregroundColor(Color.App.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.App.primaryLight.opacity(0.4))
            .cornerRadius(10)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Cách tính chỉ số BMR cụ thể (Harris-Benedict):")
                        .font(.App.caption)
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.blue).frame(width: 6, height: 6)
                            Text("Đối với Nam giới:")
                                .font(.App.small)
                                .foregroundColor(.blue)
                        }
                        Text("66.47 + (13.75 × W) + (5.003 × H) - (6.755 × A)")
                            .font(.App.smallSemibold)
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.leading, 12)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.04))
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("Đối với Nữ giới:")
                                .font(.App.small)
                                .foregroundColor(.red)
                        }
                        Text("655.1 + (9.563 × W) + (1.85 × H) - (4.676 × A)")
                            .font(.App.smallSemibold)
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.leading, 12)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.04))
                    .cornerRadius(8)
                    
                    HStack(spacing: 12) {
                        Text("• W: Cân nặng (kg)").foregroundColor(.gray)
                        Text("• H: Chiều cao (cm)").foregroundColor(.gray)
                        Text("• A: Tuổi của bạn").foregroundColor(.gray)
                    }
                    .font(.App.tinyMedium)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
    
    private func calculateRealtimeCalories(met: Double, duration: Double) -> Double {
        let weight = viewModel.userWeight
        let height = viewModel.userHeight
        var bmr: Double = 0
        
        bmr = 66.47 + (13.75 * weight) + (5.003 * height) - (6.755 * 24.0)
        return (bmr / 1440.0) * met * duration
    }
    
    private func handleUpdate() {
        guard let min = Double(duration) else { return }
        hideKeyboard()
        router.showLoading()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.updateLog(userId: userId, logId: log.id, duration: min, activity: log.activityType, date: date)
            router.hideLoading()
            router.showToast(message: "Đã cập nhật thời gian tập luyện", type: .success)
            dismiss()
        }
    }
    
    private func handleDelete() {
        hideKeyboard()
        router.showLoading()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.deleteLog(userId: userId, logId: log.id, date: date)
            router.hideLoading()
            router.showToast(message: "Đã xóa hoạt động khỏi nhật ký", type: .success)
            dismiss()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

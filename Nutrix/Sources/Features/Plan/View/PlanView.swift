import SwiftUI

struct PlanView: View {
    @Binding var selectedDate: Date
    
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var planViewModel: PlanViewModel
    
    @State private var showAISetup = false
    @State private var showDeleteConfirmation = false // Quản lý đóng mở cửa sổ hủy lộ trình
    
    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Thanh tác vụ đầu trang
                TopBar(selectedTab: .constant(.plan), selectedDate: $selectedDate)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                
                if planViewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.App.primary))
                            .scaleEffect(1.2)
                        Text("Đang tải lộ trình...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.top, 12)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 26) {
                            
                            // 1. KHỐI LỘ TRÌNH ĐANG THỰC HIỆN
                            if let plan = planViewModel.currentPlan {
                                VStack(alignment: .leading, spacing: 18) {                                    
                                    currentPlanDetailedCard(plan: plan)
                                    
                                    // 2. KHỐI NHẬT KÝ TUẦN ĐỘNG (THỰC TẾ TỪ FIREBASE)
                                    miniStreakSection
                                }
                            } else {
                                AIPlanPromoCard {
                                    if planViewModel.user != nil {
                                        showAISetup = true
                                    }
                                }
                            }
                            
                            // 3. KHỐI LỊCH SỬ LỘ TRÌNH GẦN ĐÂY
                            if !planViewModel.historyPlans.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Lịch sử lộ trình gần đây")
                                        .font(.system(size: 20, weight: .black))
                                        .foregroundColor(.black)
                                    
                                    VStack(spacing: 14) {
                                        ForEach(planViewModel.historyPlans, id: \.startDate) { histPlan in
                                            historyPlanDetailedCard(plan: histPlan)
                                        }
                                    }
                                }
                            }
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
            
            // Khắc phục triệt để lỗi nút bấm đơ bằng cách gắn Alert tại cây thư mục ZStack gốc ngoài cùng
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Xác nhận hủy lộ trình"),
                    message: Text("Bạn có chắc chắn muốn dừng lộ trình này không? Toàn bộ mục tiêu cơ thể hiện tại sẽ đóng lại và lưu trữ vào phần lịch sử ứng dụng."),
                    primaryButton: .destructive(Text("Hủy lộ trình")) {
                        planViewModel.abandonCurrentPlan()
                        router.showToast(message: "Đã hủy lộ trình thành công!", type: .success)
                        planViewModel.loadAllData()
                    },
                    secondaryButton: .cancel(Text("Quay lại"))
                )
            }
        }
        .onAppear {
            planViewModel.loadAllData()
        }
        .fullScreenCover(isPresented: $showAISetup, onDismiss: {
            planViewModel.loadAllData()
        }) {
            if let user = planViewModel.user {
                AIPlanSetupView(user: user)
                    .environmentObject(diaryViewModel)
                    .environmentObject(planViewModel)
                    .environmentObject(router)
                    .environmentObject(authService)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func currentPlanDetailedCard(plan: NutritionPlan) -> some View {
        let progress = planViewModel.calculateProgress(startDate: plan.startDate, endDate: plan.endDate ?? Date().addingTimeInterval(30*24*60*60))
        let goalType = planViewModel.getPlanGoalType(current: plan.currentWeight ?? 0.0, target: plan.targetWeight ?? 0.0)
        
        return VStack(spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle().fill(Color.App.primary).frame(width: 8, height: 8)
                        Text(goalType.uppercased())
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color.App.primary)
                    }
                    
                    Text("Mục tiêu: \(String(format: "%.1f", plan.targetWeight ?? 0)) kg")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
                Spacer()
                
                Text("\(progress.daysPassed)/\(progress.totalDays) ngày")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.App.secondaryBackground)
                    .cornerRadius(8)
            }
            
            // Thanh tiến trình thời hạn
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.black.opacity(0.04)).frame(height: 8)
                        Capsule()
                            .fill(LinearGradient(colors: [Color.App.primary, Color.App.primary.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(min(max(progress.percentage, 0), 100) / 100.0), height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Spacer()
                    Text("\(Int(progress.percentage))%")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Color.App.primary)
                }
            }
            
            Divider()
            
            // Khối hiển thị chỉ số dinh dưỡng đa lượng
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                planMetricItem(label: "Mục tiêu Calo", value: $planViewModel.editDailyCalories, unit: "kcal", icon: "flame.fill", color: .orange)
                planMetricItem(label: "Chỉ tiêu Đạm", value: $planViewModel.editProtein, unit: "g", icon: "drop.fill", color: .red)
                planMetricItem(label: "Chỉ tiêu Tinh bột", value: $planViewModel.editCarbs, unit: "g", icon: "leaf.fill", color: .blue)
                planMetricItem(label: "Chỉ tiêu Béo", value: $planViewModel.editFat, unit: "g", icon: "circle.dotted", color: .yellow)
            }
            
            Divider().padding(.vertical, 4)
            
            // HỆ THỐNG BA NÚT ĐIỀU HƯỚNG / HÀNH ĐỘNG
            VStack(spacing: 12) {
                // 1. Nút Đánh giá & hiệu chỉnh dinh dưỡng hàng ngày tự động bằng AI
                Button(action: {
                    router.showToast(message: "Tính năng phân tích hiệu chỉnh dinh dưỡng thiếu hụt bằng AI đang được phát triển!", type: .success)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("ĐÁNH GIÁ TIẾN TRÌNH VỚI AI")
                    }
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.App.primary)
                    .cornerRadius(14)
                    .shadow(color: Color.App.primary.opacity(0.25), radius: 6, y: 3)
                }
                
                HStack(spacing: 12) {
                    // 2. Nút Cập nhật sửa đổi chỉ số
                    Button(action: {
                        if planViewModel.isEditingPlan {
                            planViewModel.savePlanUpdates()
                        } else {
                            planViewModel.setupEditFields(from: plan)
                            planViewModel.isEditingPlan = true
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: planViewModel.isEditingPlan ? "checkmark.circle.fill" : "pencil")
                            Text(planViewModel.isEditingPlan ? "Lưu lại" : "Sửa chỉ số")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(planViewModel.isEditingPlan ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(planViewModel.isEditingPlan ? Color.orange : Color.App.secondaryBackground)
                        .cornerRadius(12)
                    }
                    
                    // 3. Nút Xóa / Huỷ bỏ lộ trình hiện tại
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                            Text("Hủy bỏ")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.02), radius: 15, x: 0, y: 8)
    }
    
    // Khối hiển thị chuỗi ngày thực hiện trong tuần (Dữ liệu thật từ Firebase)
    private var miniStreakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nhật ký thực hiện tuần này")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 4)
            
            HStack(spacing: 0) {
                ForEach(planViewModel.weeklyStreak, id: \.dayName) { day in
                    VStack(spacing: 8) {
                        Text(day.dayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                        
                        ZStack {
                            Circle()
                                .fill(day.isCompleted ? Color.App.primaryLight : Color.black.opacity(0.03))
                                .frame(width: 34, height: 34)
                            
                            Image(systemName: day.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(day.isCompleted ? Color.App.primary : .red.opacity(0.35))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(Color.white)
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.01), radius: 10, y: 4)
        }
    }
    
    private func planMetricItem(label: String, value: Binding<String>, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                if planViewModel.isEditingPlan {
                    TextField("0", text: value)
                        .font(.system(size: 16, weight: .bold))
                        .keyboardType(.numberPad)
                        .foregroundColor(.black)
                        .frame(maxWidth: 65)
                } else {
                    Text(value.wrappedValue)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
                
                Text(unit)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gray)
                    .padding(.bottom, 1.5)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(planViewModel.isEditingPlan ? Color.App.primary.opacity(0.06) : Color.App.background)
            .cornerRadius(10)
        }
    }
    
    private func historyPlanDetailedCard(plan: NutritionPlan) -> some View {
        let goalType = planViewModel.getPlanGoalType(current: plan.currentWeight ?? 0.0, target: plan.targetWeight ?? 0.0)
        let isCancelled = plan.status == "cancelled"
        
        return HStack(spacing: 16) {
            VStack {
                Image(systemName: isCancelled ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isCancelled ? .red.opacity(0.7) : Color.App.primary)
            }
            .frame(width: 42, height: 42)
            .background(isCancelled ? Color.red.opacity(0.06) : Color.App.primaryLight)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goalType)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                
                HStack(spacing: 6) {
                    Text("\(formatDate(plan.startDate)) - \(formatDate(plan.endDate))")
                    Text("•")
                    Text("\(Int(plan.dailyCalories)) kcal")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", plan.targetWeight ?? 0))")
                    .font(.system(size: 17, weight: .black))
                    .foregroundColor(.black)
                Text("kg")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.01), radius: 6, x: 0, y: 3)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "--/--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: date)
    }
}
// MARK: - Helper Views

struct AIPlanPromoCard: View {
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(Color.App.primary)
                .padding(22)
                .background(Color.App.primaryLight)
                .clipShape(Circle())
            
            VStack(spacing: 10) {
                Text("Thiết kế lộ trình với AI")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.black)
                Text("Hãy để Nutrix AI phân tích chỉ số cơ thể chuyên sâu và xây dựng mục tiêu dinh dưỡng cá nhân hoá phù hợp nhất dành riêng cho bạn.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 10)
            
            Button(action: action) {
                HStack(spacing: 8) {
                    Text("Bắt đầu phân tích")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.App.primary)
                .cornerRadius(16)
                .shadow(color: Color.App.primary.opacity(0.25), radius: 10, y: 6)
            }
        }
        .padding(28)
        .background(Color.white)
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.02), radius: 20, x: 0, y: 10)
    }
}

import SwiftUI

struct AIPlanSetupView: View {
    @StateObject var vm = AIPlanViewModel()
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @EnvironmentObject var planViewModel: PlanViewModel
    
    var user: User
    
    // Logic tính toán trạng thái mục tiêu
    private var goalStatus: (text: String, color: Color) {
        guard let targetValue = Double(vm.targetWeight), let current = user.weight else {
            return ("Chờ nhập mục tiêu...", Color.App.lightGray)
        }
        
        if targetValue < current {
            return ("Chế độ: Giảm cân", .red)
        } else if targetValue > current {
            return ("Chế độ: Tăng cân", Color.App.primary)
        } else {
            return ("Chế độ: Duy trì vóc dáng", .green)
        }
    }
    
    var body: some View {
        ZStack { // ZStack gốc quản lý các Overlays toàn màn hình
            Group {
                if let plan = vm.generatedPlan {
                    NutritionPlanView(plan: plan) {
                        withAnimation {
                            vm.generatedPlan = nil
                        }
                    } onApplied: {
                        dismiss()
                    }
                } else {
                    NavigationView {
                        ZStack {
                            Color.App.background.ignoresSafeArea()
                            
                            VStack(spacing: 0) {
                                // Header
                                headerSection
                                    .padding(.top, 10)
                                
                                ScrollView(showsIndicators: false) {
                                    VStack(spacing: 24) {
                                        // Phần chỉ số hiện tại (Read-only)
                                        currentMetricsSection
                                        
                                        // Phần nhập mục tiêu
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("Thiết lập mục tiêu")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 4)
                                            
                                            targetWeightCard
                                            
                                            HStack(spacing: 16) {
                                                exerciseTimeCard
                                                durationCard
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 20)
                                }
                                .onTapGesture { hideKeyboard() }
                                
                                // Nút hành động
                                VStack(spacing: 12) {
                                    createButton
                                    
                                    Text("Dữ liệu được phân tích bởi Nutrix AI dựa trên chỉ số khoa học")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                                .background(Color.App.background)
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Đóng") { dismiss() }
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                    }
                }
            }
            
            // 1. Hiển thị Loading Overlay
            if router.isLoading {
                LoadingOverlay(text: "Nutrix AI đang phân tích...")
                    .zIndex(1)
                    .transition(.opacity)
            }
            
            // 2. HIỂN THỊ TOAST THÔNG BÁO LỖI (Đã thêm mới tại đây)
            if router.toast != nil {
                AppNotificationView(data: router.toast)
                    .zIndex(2) // Đảm bảo nổi hẳn lên trên cùng
            }
        }
        .animation(.easeInOut(duration: 0.2), value: router.isLoading)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: router.toast?.message)
    }
    
    // MARK: - Subviews
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.App.primary)
                    .padding(10)
                    .background(Color.App.primaryLight)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nutrix AI Plan")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.black)
                    Text("Thiết kế lộ trình cá nhân hóa")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Divider().padding(.horizontal, 20).padding(.top, 5)
        }
    }
    
    private var currentMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Chỉ số hiện tại")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            HStack(spacing: 15) {
                metricSmallBox(title: "Cân nặng", value: "\(String(format: "%.1f", user.weight ?? 0))", unit: "kg", icon: "scalemass.fill")
                metricSmallBox(title: "Chiều cao", value: "\(Int(user.height ?? 0))", unit: "cm", icon: "ruler.fill")
                metricSmallBox(title: "Tuổi", value: "\(user.age ?? 0)", unit: "tuổi", icon: "person.fill")
            }
        }
    }
    
    private func metricSmallBox(title: String, value: String, unit: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(Color.App.primary)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
    
    private var targetWeightCard: some View {
        VStack(spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Cân nặng mục tiêu")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                    Text("Số cân nặng bạn muốn đạt được")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                Spacer()
                
                HStack(alignment: .bottom, spacing: 5) {
                    TextField("0.0", text: $vm.targetWeight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.black)
                        .frame(width: 80)
                    
                    Text("kg")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                        .padding(.bottom, 5)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(goalStatus.color)
                Text(goalStatus.text)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(goalStatus.color)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            .background(goalStatus.color.opacity(0.08))
            .cornerRadius(12)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var exerciseTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Tập luyện")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Picker("", selection: $vm.exerciseTime) {
                ForEach(Array(stride(from: 0, through: 120, by: 15)), id: \.self) { minute in
                    Text("\(minute)p").tag("\(minute)")
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(Color.App.background)
            .cornerRadius(12)
            
            Text("phút/ngày")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var durationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Thời hạn")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }
            
            HStack {
                Button { if vm.duration > 1 { vm.duration -= 1 } } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.gray.opacity(0.3))
                }
                
                Spacer()
                Text("\(Int(vm.duration))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                Spacer()
                
                Button { if vm.duration < 12 { vm.duration += 1 } } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color.App.primary)
                }
            }
            .padding(.vertical, 8)
            
            Text("tháng")
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var createButton: some View {
        Button(action: {
            hideKeyboard()
            router.showLoading()
            
            Task { @MainActor in
                await vm.createPlan(user: user)
                router.hideLoading()
                
                if let error = vm.errorMessage {
                    router.showToast(message: error, type: .error)
                }
            }
        }) {
            HStack(spacing: 12) {
                Text("PHÂN TÍCH VỚI AI")
                Image(systemName: "sparkles")
            }
            .font(.system(size: 16, weight: .black))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [Color.App.primary, Color.App.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(18)
            .shadow(color: Color.App.primary.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(vm.targetWeight.isEmpty || router.isLoading)
        .opacity((vm.targetWeight.isEmpty || router.isLoading) ? 0.6 : 1)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

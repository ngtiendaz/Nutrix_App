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
                                                .font(.App.bodyBold)
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 4)
                                            
                                            targetWeightCard
                                            
                                            HStack(spacing: 16) {
                                                exerciseTimeCard
                                                durationCard
                                            }
                                            
                                            healthNoteSection
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
                                        .font(.App.smallSemibold)
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
                                    .font(.App.bodyLarge)
                            }
                        }
                        .onAppear {
                            if vm.healthNote.isEmpty {
                                vm.healthNote = user.healthNote ?? ""
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
                    .font(.App.title2)
                    .foregroundColor(Color.App.primary)
                    .padding(10)
                    .background(Color.App.primaryLight)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nutrix AI Plan")
                        .font(.App.title2)
                        .foregroundColor(.black)
                    Text("Thiết kế lộ trình cá nhân hóa")
                        .font(.App.subheadlineRegular)
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
                .font(.App.sectionHeader)
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
                    .font(.App.tinyMedium)
                    .foregroundColor(Color.App.primary)
                Text(title)
                    .font(.App.smallSemibold)
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.App.title)
                    .foregroundColor(.black)
                Text(unit)
                    .font(.App.smallSemibold)
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
                        .font(.App.headline)
                        .foregroundColor(.black)
                    Text("Số cân nặng bạn muốn đạt được")
                        .font(.App.captionMedium)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                HStack(alignment: .bottom, spacing: 5) {
                    TextField("0.0", text: $vm.targetWeight)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.App.display)
                        .foregroundColor(.black)
                        .frame(width: 80)
                    
                    Text("kg")
                        .font(.App.bodyBold)
                        .foregroundColor(.gray)
                        .padding(.bottom, 5)
                }
            }
            
            Divider()
            
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.App.body)
                    .foregroundColor(goalStatus.color)
                Text(goalStatus.text)
                    .font(.App.subheadline)
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
                    .font(.App.sectionHeader)
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
                .font(.App.smallSemibold)
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
                    .font(.App.sectionHeader)
                    .foregroundColor(.black)
            }
            
            HStack {
                Button { if vm.duration > 1 { vm.duration -= 1 } } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.gray.opacity(0.3))
                }
                
                Spacer()
                Text("\(Int(vm.duration))")
                    .font(.App.title2)
                    .foregroundColor(.black)
                Spacer()
                
                Button { if vm.duration < 12 { vm.duration += 1 } } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color.App.primary)
                }
            }
            .padding(.vertical, 8)
            
            Text("tháng")
                .font(.App.smallSemibold)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    private var healthNoteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.red)
                Text("Ghi chú sức khỏe (Tùy chọn)")
                    .font(.App.headline)
                    .foregroundColor(.black)
            }
            
            TextEditor(text: $vm.healthNote)
                .font(.App.subheadline)
                .foregroundColor(.black)
                .frame(height: 100)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if vm.healthNote.isEmpty {
                            Text("Nhập tình trạng sức khỏe, bệnh lý hoặc lưu ý đặc biệt để AI đưa ra lộ trình phù hợp hơn...")
                                .font(.App.subheadline)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding(20)
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
            .font(.App.bodyLarge)
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

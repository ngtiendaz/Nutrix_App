import SwiftUI

struct AIPlanSetupView: View {
    @StateObject var vm = AIPlanViewModel()
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    
    var user: User
    
    // Logic tính toán trạng thái mục tiêu
    private var goalStatus: (text: String, color: Color) {
        guard let target = Double(vm.targetWeight), let current = user.weight else {
            return ("Nhập mục tiêu để AI phân tích", Color.App.lightGray)
        }
        
        if target < current {
            return ("Chế độ: Giảm cân", .red)
        } else if target > current {
            return ("Chế độ: Tăng cân", Color.App.primary)
        } else {
            return ("Chế độ: Duy trì vóc dáng", .green)
        }
    }
    
    var body: some View {
        Group {
            // ✅ NẾU AI ĐÃ SINH LỘ TRÌNH: Chuyển sang hiển thị NutritionPlanView ngay tại đây
            // Điều này giữ nguyên cây Environment, không sinh thêm Window mới, giải quyết hoàn toàn lỗi crash/xung đột!
            if let plan = vm.generatedPlan {
                NutritionPlanView(plan: plan) {
                    // Trở về giao diện setup cũ nếu muốn
                    vm.generatedPlan = nil
                } onApplied: {
                    // Khi áp dụng thành công, đóng toàn bộ cụm FullScreenCover một cách an toàn
                    dismiss()
                }
            } else {
                // ✅ NẾU CHƯA CÓ LỘ TRÌNH: Hiển thị form điền thông số đầu vào như bình thường
                NavigationView {
                    ZStack {
                        Color.App.background
                            .ignoresSafeArea()
                            .onTapGesture { hideKeyboard() }
                        
                        VStack(spacing: 0) {
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 20) {
                                    headerSection
                                        .padding(.top, 25)
                                        .padding(.bottom, 10)
                                    
                                    VStack(spacing: 18) {
                                        // CARD 1: CÂN NẶNG
                                        inputCard(title: "Chỉ số cân nặng", icon: "scalemass.fill") {
                                            VStack(spacing: 15) {
                                                HStack {
                                                    Text("Cân nặng hiện tại")
                                                        .font(.system(size: 15))
                                                        .foregroundColor(.black.opacity(0.7))
                                                    Spacer()
                                                    Text("\(String(format: "%.1f", user.weight ?? 0)) kg")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.black)
                                                }
                                                
                                                Divider().background(Color.App.primary.opacity(0.1))
                                                
                                                HStack {
                                                    Text("Cân nặng mục tiêu")
                                                        .font(.system(size: 15))
                                                        .foregroundColor(.black.opacity(0.7))
                                                    Spacer()
                                                    TextField("0.0", text: $vm.targetWeight)
                                                        .keyboardType(.decimalPad)
                                                        .multilineTextAlignment(.trailing)
                                                        .font(.system(size: 20, weight: .bold))
                                                        .foregroundColor(.black)
                                                    Text("kg")
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(.black)
                                        }
                                                
                                                HStack {
                                                    Spacer()
                                                    Text(goalStatus.text)
                                                        .font(.system(size: 11, weight: .bold))
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 5)
                                                        .background(goalStatus.color.opacity(0.1))
                                                        .foregroundColor(goalStatus.color)
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                        
                                        // CARD 2: THỜI GIAN TẬP
                                        inputCard(title: "Thời gian tập luyện", icon: "clock.fill") {
                                            HStack {
                                                Text("Thời gian mỗi ngày")
                                                    .font(.system(size: 15))
                                                    .foregroundColor(.black.opacity(0.7))
                                                Spacer()
                                                Picker("", selection: $vm.exerciseTime) {
                                                    ForEach(Array(stride(from: 5, through: 120, by: 5)), id: \.self) { minute in
                                                        Text("\(minute) phút").tag("\(minute)")
                                                    }
                                                }
                                                .pickerStyle(.menu)
                                                .tint(Color.App.primary)
                                            }
                                        }
                                        
                                        // CARD 3: THỜI GIAN CAM KẾT
                                        inputCard(title: "Thời gian thực hiện", icon: "calendar") {
                                            VStack(alignment: .leading, spacing: 12) {
                                                HStack {
                                                    Text("Lộ trình trong")
                                                        .font(.system(size: 15))
                                                        .foregroundColor(.black.opacity(0.7))
                                                    Spacer()
                                                    Text("\(Int(vm.duration)) tháng")
                                                        .font(.system(size: 17, weight: .bold))
                                                        .foregroundColor(Color.App.primary)
                                                }
                                                Stepper("", value: $vm.duration, in: 1...12)
                                                    .labelsHidden()
                                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                                    .tint(Color.App.primary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            createButton
                                .padding(.horizontal, 20)
                                .padding(.bottom, 15)
                        }
                        
                        if vm.isLoading {
                            Color.black.opacity(0.15)
                                .ignoresSafeArea()
                            ProgressView("NutriX AI đang phân tích dữ liệu...")
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.App.primary))
                                .padding(20)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 5)
                                .zIndex(999)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Hủy") { dismiss() }
                                .foregroundColor(.red)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .padding(18)
                .background(Color.App.primary)
                .clipShape(Circle())
                .shadow(color: Color.App.primary.opacity(0.3), radius: 10, y: 5)
            
            VStack(spacing: 5) {
                Text("Cá nhân hóa lộ trình")
                    .font(.system(size: 22, weight: .black)).foregroundColor(.black)
                Text("Nutrix AI sẽ thiết kế thực đơn dựa trên chỉ số của bạn")
                    .font(.system(size: 13))
                    .foregroundColor(Color.App.lightGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    private func inputCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .black))
            }
            .foregroundColor(Color.App.primary)
            content()
        }
        .padding(22)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
    
    private var createButton: some View {
        Button(action: {
            hideKeyboard()
            Task { @MainActor in
                await vm.createPlan(user: user)
            }
        }) {
            HStack(spacing: 10) {
                Text("PHÂN TÍCH VỚI AI")
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
            }
            .font(.system(size: 15, weight: .black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.App.primary)
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: Color.App.primary.opacity(0.3), radius: 10, y: 5)
        }
        .disabled(vm.targetWeight.isEmpty || vm.isLoading)
        .opacity(vm.targetWeight.isEmpty ? 0.3 : 1)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

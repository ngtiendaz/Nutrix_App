import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NutritionPlanView: View {
    let plan: NutritionPlan
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @EnvironmentObject var planViewModel: PlanViewModel
    
    @StateObject private var viewModel = NutritionPlanViewModel()
    
    @State private var displayedAdvice: String = ""
    @State private var selectedDuration: Int = 1
    @State private var showButtons = false
    
    var onBackToSetup: () -> Void
    var onApplied: () -> Void
    
    var body: some View {
        ZStack { // Thêm phần tử loading vào cuối ZStack này
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {
                        
                        // Header
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Kết quả phân tích")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.App.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.App.primaryLight)
                                    .clipShape(Capsule())
                                Spacer()
                            }
                            
                            Text("Lộ trình dinh dưỡng\ncá nhân hóa")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)
                                .lineSpacing(2)
                        }
                        .padding(.top, 50)
                        
                        // 1. Chỉ số đa lượng (Macros)
                        VStack(alignment: .leading, spacing: 18) {
                            Label("Mục tiêu dinh dưỡng", systemImage: "target")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            
                            nutritionHighlights
                        }
                        
                        // 2. Lời khuyên AI
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                                Text("Lời khuyên từ Nutrix AI")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            
                            Text(displayedAdvice)
                                .font(.system(size: 15, design: .rounded))
                                .foregroundColor(.black.opacity(0.8))
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(28)
                        .shadow(color: .black.opacity(0.03), radius: 15, x: 0, y: 5)
                        
                        // 3. Kế hoạch tập luyện
                        VStack(alignment: .leading, spacing: 18) {
                            Label("Hoạt động thể chất", systemImage: "figure.run")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(plan.exercisePlan)
                                .font(.system(size: 15))
                                .foregroundColor(.black.opacity(0.7))
                                .lineSpacing(5)
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.App.primary.opacity(0.05))
                                .cornerRadius(20)
                        }
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 12)
                }
                
                if showButtons {
                    actionButtonsArea
                }
            }
            
            // Hiển thị Loading Overlay đè lên toàn màn hình khi đang lưu dữ liệu Firebase
            if router.isLoading {
                LoadingOverlay(text: "Đang lưu lộ trình mới...")
                    .zIndex(1)
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.2), value: router.isLoading)
        .overlay(alignment: .topLeading) {
            Button(action: onBackToSetup) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 5)
            }
            .padding(.leading, 20)
            .padding(.top, 10)
            .disabled(router.isLoading) // Khóa nút Back khi đang loading
        }
        .onAppear {
            if let planDuration = plan.duration {
                self.selectedDuration = planDuration
            }
            startTypingEffect()
        }
        .alert("Thông báo", isPresented: .init(get: { viewModel.saveError != nil }, set: { _ in viewModel.saveError = nil })) {
            Button("Đóng", role: .cancel) { }
        } message: {
            Text(viewModel.saveError ?? "")
        }
    }
    
    // MARK: - Components
    private var nutritionHighlights: some View {
        VStack(spacing: 12) {
            // Calo Card
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Lượng calo mỗi ngày")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(Int(plan.dailyCalories))")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(Color.App.primary)
                        Text("kcal")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.bottom, 6)
                    }
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
                    .padding(15)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.02), radius: 10, x: 0, y: 5)
            
            // Macros Grid
            HStack(spacing: 12) {
                macroSmallBox(title: "Tinh bột", value: "\(Int(plan.carbs))g", color: .blue, icon: "leaf.fill")
                macroSmallBox(title: "Đạm", value: "\(Int(plan.protein))g", color: .red, icon: "drop.fill")
                macroSmallBox(title: "Béo", value: "\(Int(plan.fat))g", color: .yellow, icon: "circle.dotted")
            }
        }
    }
    
    private func macroSmallBox(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
                .padding(8)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
    
    private var actionButtonsArea: some View {
        VStack(spacing: 12) {
            Button(action: { savePlanWithViewModel() }) {
                HStack {
                    Text("ÁP DỤNG LỘ TRÌNH NÀY")
                        .font(.system(size: 16, weight: .black))
                    Image(systemName: "checkmark.circle.fill")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.App.primary)
                .cornerRadius(20)
                .shadow(color: Color.App.primary.opacity(0.3), radius: 10, y: 5)
            }
            .disabled(router.isLoading)
            .padding(.horizontal, 25)
            
            Button(action: { onApplied() }) {
                Text("Bỏ qua")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.gray)
            }
            .disabled(router.isLoading)
        }
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [Color.App.background.opacity(0), Color.App.background], startPoint: .top, endPoint: .bottom)
                .frame(height: 150)
        )
    }

    private func savePlanWithViewModel() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
//        router.showLoading()
        
        viewModel.handleSavePlan(
            userId: userId,
            plan: plan,
            durationMonths: selectedDuration,
            currentWeight: plan.currentWeight ?? 0.0,
            targetWeight: plan.targetWeight ?? 0.0
        ) { success in
            router.hideLoading()
            
            if success {
                router.showToast(message: "Đã cập nhật lộ trình mới!", type: .success)
                diaryViewModel.refreshData()
                planViewModel.loadAllData()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onApplied()
                }
            }
        }
    }
    
    private func startTypingEffect() {
        let chars = plan.advice.map { String($0) }
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 0.012, repeats: true) { timer in
            if index < chars.count {
                displayedAdvice += chars[index]
                index += 1
            } else {
                timer.invalidate()
                withAnimation(.spring()) { showButtons = true }
            }
        }
    }
}

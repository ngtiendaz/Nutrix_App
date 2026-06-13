import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NutritionPlanView: View {
    let plan: NutritionPlan
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @EnvironmentObject var planViewModel: PlanViewModel
    
    @StateObject private var viewModel = NutritionPlanViewModel()
    
    var onBackToSetup: () -> Void
    var onApplied: () -> Void
    
    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header tinh gọn
                        VStack(alignment: .leading, spacing: 8) {
                            Text("KẾT QUẢ PHÂN TÍCH")
                                .font(.App.captionMedium)
                                .foregroundColor(Color.App.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.App.primaryLight)
                                .cornerRadius(6)
                            
                            Text("Lộ trình đề xuất")
                                .font(.App.title)
                                .foregroundColor(.black)
                        }
                        .padding(.top, 40)
                        
                        // 1. Macros Card (Gom nhóm gọn hơn)
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Năng lượng mỗi ngày")
                                        .font(.App.smallSemibold)
                                        .foregroundColor(.gray)
                                    Text("\(Int(plan.dailyCalories)) kcal")
                                        .font(.App.title)
                                        .foregroundColor(Color.App.primary)
                                }
                                Spacer()
                                Image(systemName: "flame.fill")
                                    .font(.App.title)
                                    .foregroundColor(.orange)
                                    .padding(10)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            Divider()
                            
                            HStack(spacing: 0) {
                                macroMiniBox(title: "Đạm", value: "\(Int(plan.protein))g", color: .red)
                                Divider().frame(height: 20).padding(.horizontal, 10)
                                macroMiniBox(title: "Tinh bột", value: "\(Int(plan.carbs))g", color: .blue)
                                Divider().frame(height: 20).padding(.horizontal, 10)
                                macroMiniBox(title: "Béo", value: "\(Int(plan.fat))g", color: .yellow)
                            }
                        }
                        .padding(18)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.02), radius: 10, y: 4)
                        
                        // 2. Lời khuyên AI (Bỏ hiệu ứng gõ chữ, hiển thị ngay)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                                Text("Đánh giá từ AI")
                                    .font(.App.headline)
                                    .foregroundColor(.black)
                            }
                            
                            Text(plan.advice)
                                .font(.App.subheadline)
                                .foregroundColor(.black.opacity(0.8))
                                .lineSpacing(4)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.02), radius: 10, y: 4)
                        
                        // 3. Kế hoạch tập luyện (Gọn hơn)
                        if !plan.exercisePlan.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Gợi ý vận động", systemImage: "figure.run")
                                    .font(.App.headline)
                                    .foregroundColor(.black)
                                
                                Text(plan.exercisePlan)
                                    .font(.App.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(15)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.App.primary.opacity(0.05))
                                    .cornerRadius(16)
                            }
                        }
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                }
                
                // Nút hành động nổi bật, hiển thị ngay
                actionButtonsArea
            }
            
            if router.isLoading {
                LoadingOverlay(text: "Đang lưu...")
                    .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .overlay(alignment: .topLeading) {
            Button(action: onBackToSetup) {
                Image(systemName: "chevron.left")
                    .font(.App.headline)
                    .foregroundColor(.black)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.05), radius: 5)
            }
            .padding(.leading, 16)
            .padding(.top, 8)
        }
        .onAppear {
            // Removed duration setting
        }
    }
    
    private func macroMiniBox(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.App.tiny)
                .foregroundColor(.gray)
            Text(value)
                .font(.App.bodyBold)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var actionButtonsArea: some View {
        VStack(spacing: 12) {
            Button(action: { savePlanWithViewModel() }) {
                Text("ÁP DỤNG THAY ĐỔI")
                    .font(.App.bodyBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.App.primary)
                    .cornerRadius(14)
                    .shadow(color: Color.App.primary.opacity(0.2), radius: 8, y: 4)
            }
            .padding(.horizontal, 16)
            
            Button(action: { onApplied() }) {
                Text("Giữ nguyên lộ trình cũ")
                    .font(.App.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color.App.background)
    }

    private func savePlanWithViewModel() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        router.showLoading()
        
        viewModel.handleSavePlan(
            userId: userId,
            plan: plan,
            currentWeight: plan.currentWeight ?? 0.0,
            targetWeight: plan.targetWeight ?? 0.0
        ) { success in
            router.hideLoading()
            if success {
                router.showToast(message: "Đã cập nhật!", type: .success)
                diaryViewModel.refreshData()
                planViewModel.loadAllData()
                onApplied()
            }
        }
    }
}


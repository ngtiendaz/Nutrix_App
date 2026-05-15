//
//  NutritionPlanView.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//

import SwiftUI

struct NutritionPlanView: View {
    let plan: NutritionPlan
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var loginViewModel: LoginViewModel
    @StateObject private var viewModel = NutritionPlanViewModel()
    
    @State private var displayedAdvice: String = ""
    @State private var showButtons = false
    
    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phân tích từ Nutrix")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.App.primary)
                                .textCase(.uppercase)
                                .tracking(1.2)
                            
                            Text("Lộ trình dinh dưỡng")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)
                        }
                        .padding(.top, 10)
                        
                        // 1. Grid Chỉ số dinh dưỡng (Thiết kế lại hiện đại hơn)
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Mục tiêu hằng ngày")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                nutritionCard(title: "Năng lượng", value: "\(Int(plan.dailyCalories))", unit: "kcal", icon: "bolt.fill", color: .orange)
                                nutritionCard(title: "Chất đạm", value: "\(Int(plan.protein))", unit: "g", icon: "leaf.fill", color: Color.App.primary)
                                nutritionCard(title: "Tinh bột", value: "\(Int(plan.carbs))", unit: "g", icon: "cup.and.saucer.fill", color: .blue)
                                nutritionCard(title: "Chất béo", value: "\(Int(plan.fat))", unit: "g", icon: "drop.fill", color: .yellow)
                                nutritionCard(
                                    title: "Calo cần tiêu thụ",
                                    value: "\(Int(plan.activityCalories))",
                                    unit: "kcal",
                                    icon: "flame.fill",
                                    color: .red
                                )
                            }
                        }
                        
                        // 2. Lời khuyên AI (Typing Effect Area)
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.orange)
                                Text("Lời khuyên chuyên gia")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            
                            Text(displayedAdvice)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.black.opacity(0.8))
                                .lineSpacing(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                        
                        // 3. Hoạt động đề xuất
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Hoạt động thể chất", systemImage: "figure.run")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(plan.exercisePlan)
                                .font(.system(size: 15))
                                .foregroundColor(.black.opacity(0.6))
                                .lineSpacing(4)
                        }
                        .padding(.bottom, 100) // Tạo khoảng trống cho nút bấm phía dưới
                    }
                    .padding(20)
                }
                
                // Bottom Action Buttons
                if showButtons {
                    actionButtonsArea
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startTypingEffect()
        }
        .alert("Thông báo", isPresented: .init(get: { viewModel.saveError != nil }, set: { _ in viewModel.saveError = nil })) {
            Button("Đóng", role: .cancel) { }
        } message: {
            Text(viewModel.saveError ?? "")
        }
    }
    
    // MARK: - Components
    
    private func nutritionCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.5))
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black.opacity(0.4))
                        .padding(.bottom, 2)
                }
            }
            Spacer()
        }
        .padding(15)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
    
    private var actionButtonsArea: some View {
        HStack(spacing: 15) {
            // NÚT HỦY BỎ
            Button(action: {
                // Hiển thị loading nhẹ trước khi thoát để tạo cảm giác xử lý mượt mà
                router.showLoading()
                
                // Delay cực ngắn để người dùng thấy loading rồi dismiss/pop
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.hideLoading()
                    dismiss() // Đóng fullScreenCover
                }
            }) {
                Text("Hủy bỏ")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(18)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.1), lineWidth: 1))
            }
            .disabled(viewModel.isSaving)
            
            // NÚT ÁP DỤNG NGAY
            Button(action: { savePlanWithViewModel() }) {
                ZStack {
                    if viewModel.isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Áp dụng ngay")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.black)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            }
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            LinearGradient(colors: [Color.App.background.opacity(0), Color.App.background], startPoint: .top, endPoint: .bottom)
                .padding(.top, -20)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Logic cập nhật
    private func savePlanWithViewModel() {
        guard let userId = loginViewModel.authService.currentUser?.userId else { return }
        
        // 1. Hiển thị loading của Router (Lớp phủ giữa màn hình)
        router.showLoading()
        
        viewModel.handleSavePlan(userId: userId, plan: plan) { success in
            // 2. Ẩn loading sau khi xử lý xong
            router.hideLoading()
            
            if success {
                router.showToast(message: "Đã cập nhật lộ trình mới!", type: .success)
                
                // 3. Đóng màn hình fullScreen kết quả
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            }
        }
    }
    
    private func startTypingEffect() {
        let chars = plan.advice.map { String($0) }
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 0.015, repeats: true) { timer in
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

//
//  PlanView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

// ✅ Định nghĩa lại Struct Error ở ngoài để hệ thống luôn tìm thấy
struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

struct PlanView: View {
    @Binding var selectedDate: Date
    
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @EnvironmentObject var router: AppRouter
    @StateObject private var planViewModel: PlanViewModel
    @State private var showAISetup = false
    
    init(selectedDate: Binding<Date>, authService: FirebaseAuthService) {
        self._selectedDate = selectedDate
        self._planViewModel = StateObject(wrappedValue: PlanViewModel(authService: authService))
    }
    
    var body: some View {
        ZStack {
            Color.App.background
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            
            if planViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.App.primary))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        TopBar(selectedTab: .constant(.plan), selectedDate: $selectedDate)
                            .padding(.top, 10)
                        
                        Text("Lộ trình hiện tại")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 4)
                        
                        if let plan = planViewModel.currentPlan {
                            currentPlanCard(plan: plan)
                        } else {
                            // ✅ Chỉ mở màn hình setup nếu thông tin user đã sẵn sàng tải xong
                            AIPlanCard {
                                if planViewModel.user != nil {
                                    showAISetup = true
                                }
                            }
                        }
                        
                        if !planViewModel.historyPlans.isEmpty {
                            Text("Lịch sử lộ trình")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)
                                .padding(.top, 10)
                            
                            VStack(spacing: 14) {
                                ForEach(planViewModel.historyPlans, id: \.startDate) { histPlan in
                                    historyPlanCard(plan: histPlan)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear {
            planViewModel.loadAllData()
        }
        .fullScreenCover(isPresented: $showAISetup, onDismiss: {
            planViewModel.loadAllData()
        }) {
            if let user = planViewModel.user {
                AIPlanSetupView(user: user).environmentObject(diaryViewModel)
                    .environmentObject(planViewModel)
                    .environmentObject(router)
                    .environmentObject(authService)
            }
        }
        .alert(item: Binding(get: { planViewModel.errorMessage.map { IdentifiableError(message: $0) } }, set: { _ in planViewModel.errorMessage = nil })) { error in
            Alert(title: Text("Thông báo"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - 1. CARD LỘ TRÌNH HIỆN TẠI
    @ViewBuilder
    private func currentPlanCard(plan: NutritionPlan) -> some View {
        let progress = planViewModel.calculateProgress(startDate: plan.startDate, endDate: Date().addingTimeInterval(30*24*60*60))
        let goalType = planViewModel.getPlanGoalType(current: plan.currentWeight ?? 0.0, target: plan.targetWeight ?? 0.0)
        
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goalType)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.App.primary)
                    
                    Text("Mục tiêu: \(String(format: "%.1f", plan.targetWeight ?? 0)) kg (Hiện tại: \(String(format: "%.1f", plan.currentWeight ?? 0)) kg)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Button(action: {
                    if planViewModel.isEditingPlan {
                        planViewModel.savePlanUpdates()
                    } else {
                        planViewModel.setupEditFields(from: plan)
                        planViewModel.isEditingPlan = true
                    }
                }) {
                    Text(planViewModel.isEditingPlan ? "Lưu" : "Sửa")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(planViewModel.isEditingPlan ? Color.green : Color.App.primary)
                        .cornerRadius(10)
                }
            }
            
            Divider()
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    editableMetricBox(label: "Kcal/Ngày", value: $planViewModel.editDailyCalories, icon: "flame.fill", isEditing: planViewModel.isEditingPlan)
                    editableMetricBox(label: "Protein", value: $planViewModel.editProtein, unit: "g", icon: "takeoutbag.and.cup.and.straw.fill", isEditing: planViewModel.isEditingPlan)
                }
                HStack(spacing: 12) {
                    editableMetricBox(label: "Carbs", value: $planViewModel.editCarbs, unit: "g", icon: "leaf.fill", isEditing: planViewModel.isEditingPlan)
                    editableMetricBox(label: "Chất béo", value: $planViewModel.editFat, unit: "g", icon: "drop.fill", isEditing: planViewModel.isEditingPlan)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tiến trình lộ trình")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                    Spacer()
                    Text("\(progress.daysPassed)/\(progress.totalDays) ngày (\(Int(progress.percentage))%)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.App.primary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.App.primaryLight)
                            .frame(height: 8)
                        Capsule()
                            .fill(Color.App.primary)
                            .frame(width: geo.size.width * CGFloat(progress.percentage / 100.0), height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(.top, 4)
            
            if !planViewModel.isEditingPlan {
                Button(action: {
                    planViewModel.abandonCurrentPlan()
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Hủy bỏ lộ trình hiện tại")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 6)
    }
    
    // MARK: - 2. CARD LỊCH SỬ LỘ TRÌNH CŨ
    @ViewBuilder
    private func historyPlanCard(plan: NutritionPlan) -> some View {
        let goalType = planViewModel.getPlanGoalType(current: plan.currentWeight ?? 0.0, target: plan.targetWeight ?? 0.0)
        let isCancelled = plan.status == "cancelled"
        
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(goalType)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(isCancelled ? "Đã Hủy" : "Hoàn Thành")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isCancelled ? .red : Color.App.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isCancelled ? Color.red.opacity(0.08) : Color.App.primaryLight)
                        .cornerRadius(6)
                }
                
                Text("\(formatDate(plan.startDate)) - \(formatDate(plan.endDate))")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text("Kcal: \(Int(plan.dailyCalories)) • P: \(Int(plan.protein))g • C: \(Int(plan.carbs))g • F: \(Int(plan.fat))g")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray.opacity(0.9))
            }
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", plan.targetWeight ?? 0)) kg")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                Text("Mục tiêu")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.01), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - 3. REUSABLE BOX
    private func editableMetricBox(label: String, value: Binding<String>, unit: String = "", icon: String, isEditing: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(Color.App.primary)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .bottom, spacing: 2) {
                if isEditing {
                    TextField("0", text: value)
                        .font(.system(size: 16, weight: .bold))
                        .keyboardType(.decimalPad)
                        .foregroundColor(.black)
                } else {
                    Text(value.wrappedValue.isEmpty ? "--" : value.wrappedValue)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                }
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.bottom, 1)
                }
                Spacer()
            }
            .frame(height: 36)
            .padding(.horizontal, 10)
            .background(isEditing ? Color.App.primary.opacity(0.08) : Color.black.opacity(0.02))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEditing ? Color.App.primary.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "--/--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

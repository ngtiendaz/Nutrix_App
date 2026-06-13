import SwiftUI
import Charts

struct PlanView: View {
    @Binding var selectedDate: Date
    
    @EnvironmentObject var authService: FirebaseAuthService
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var planViewModel: PlanViewModel
    
    @State private var showAISetup = false
    @State private var showDeleteConfirmation = false
    @State private var selectedHistoryPlan: NutritionPlan? = nil
    
    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                if planViewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.App.primary))
                            .scaleEffect(1.2)
                        Text("Đang tải lộ trình...")
                            .font(.App.body)
                            .foregroundColor(.gray)
                            .padding(.top, 12)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 26) {
                            
                            TopBar(selectedTab: .constant(.plan), selectedDate: $selectedDate)
                            
                            // 1. KHỐI LỘ TRÌNH ĐANG THỰC HIỆN
                            if let plan = planViewModel.currentPlan {
                                VStack(alignment: .leading, spacing: 18) {
                    
                                    currentPlanDetailedCard(plan: plan)
                                    
                                    // 2. KHỐI NHẬT KÝ TUẦN ĐỘNG
                                    miniStreakSection
                                    
                                    // 3. KHỐI BIỂU ĐỒ XU HƯỚNG CÂN NẶNG
                                    weightTrendChartSection(plan: plan)
                                }
                            } else {
                                AIPlanPromoCard {
                                    if planViewModel.user != nil {
                                        showAISetup = true
                                    }
                                }
                            }
                            
                            // 4. KHỐI LỊCH SỬ LỘ TRÌNH GẦN ĐÂY
                            if !planViewModel.historyPlans.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Lịch sử lộ trình gần đây")
                                        .font(.App.sectionHeader)
                                        .foregroundColor(.black)
                                    
                                    VStack(spacing: 14) {
                                        ForEach(planViewModel.historyPlans, id: \.startDate) { histPlan in
                                            Button {
                                                selectedHistoryPlan = histPlan
                                            } label: {
                                                historyPlanDetailedCard(plan: histPlan)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 12)
                    }
                }
            }
            
            // Khắc phục triệt để lỗi chặn Tap Gesture
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
            
            // 1. Hiển thị Loading Overlay
            if planViewModel.isEvaluating {
                LoadingOverlay(text: "Nutrix AI đang đánh giá tiến trình...")
                    .zIndex(1)
                    .transition(.opacity)
            }
            
            // 2. Hiển thị Toast thông báo lỗi
            if router.toast != nil {
                AppNotificationView(data: router.toast)
                    .zIndex(2)
            }
        }
        .onChange(of: planViewModel.errorMessage) { newValue in
            if let error = newValue {
                router.showToast(message: error, type: .error)
                planViewModel.errorMessage = nil // Reset sau khi hiển thị
            }
        }
        .onAppear {
            planViewModel.loadAllData()
        }
        .sheet(item: $planViewModel.evaluationResult) { plan in
            let _ = print("🎬 [DEBUG SHEET] Đang hiển thị sheet cho plan ID: \(plan.id)")
            NutritionPlanView(plan: plan) {
                planViewModel.evaluationResult = nil
            } onApplied: {
                planViewModel.evaluationResult = nil
                planViewModel.loadAllData()
            }
            .environmentObject(router)
            .environmentObject(diaryViewModel)
            .environmentObject(planViewModel)
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
        .sheet(item: $selectedHistoryPlan) { plan in
            if #available(iOS 16.0, *) {
                HistoryPlanDetailSheet(plan: plan, allMetrics: planViewModel.metricsHistory)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.hidden)
            } else {
                HistoryPlanDetailSheet(plan: plan, allMetrics: planViewModel.metricsHistory)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func currentPlanDetailedCard(plan: NutritionPlan) -> some View {
        let progress = planViewModel.calculateProgress(startDate: plan.startDate, endDate: plan.endDate ?? Date().addingTimeInterval(30*24*60*60))
        let goalType = planViewModel.getPlanGoalType(current: plan.currentWeight ?? 0.0, target: plan.targetWeight ?? 0.0)
        
        return VStack(spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) { // Đã sửa từ withAlignment thành alignment
                    HStack(spacing: 6) {
                        Circle().fill(Color.App.primary).frame(width: 8, height: 8)
                        Text(goalType.uppercased())
                            .font(.App.captionMedium)
                            .foregroundColor(Color.App.primary)
                    }
                    
                    Text("Mục tiêu: \(String(format: "%.1f", plan.targetWeight ?? 0)) kg")
                        .font(.App.title2)
                        .foregroundColor(.black)
                    
                    Text("Thời gian: \(formatFullDate(plan.startDate)) - \(formatFullDate(plan.endDate))")
                        .font(.App.captionMedium)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Text("\(progress.daysPassed + 1)/\(progress.totalDays) ngày")
                    .font(.App.subheadline)
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
                        .font(.App.subheadlineRegular)
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
                Button(action: {
                    print("🔘 [DEBUG UI] Bấm nút Đánh giá tiến trình AI")
                    Task {
                        await planViewModel.evaluateProgressWithAI()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("ĐÁNH GIÁ TIẾN TRÌNH VỚI AI")
                    }
                    .font(.App.sectionHeader)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.App.primary)
                    .cornerRadius(14)
                    .shadow(color: Color.App.primary.opacity(0.25), radius: 6, y: 3)
                }
                .disabled(planViewModel.isEvaluating)
                
                HStack(spacing: 12) {
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
                        .font(.App.subheadline)
                        .foregroundColor(planViewModel.isEditingPlan ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(planViewModel.isEditingPlan ? Color.orange : Color.App.secondaryBackground)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                            Text("Hủy bỏ")
                        }
                        .font(.App.subheadline)
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
    private func weightTrendChartSection(plan: NutritionPlan) -> some View {
            VStack(alignment: .leading, spacing: 14) {
                Text("Biến động cân nặng")
                    .font(.App.sectionHeader)
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                
                VStack(alignment: .leading, spacing: 15) {
                    if planViewModel.weightChartData.count < 1 {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.App.header)
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("Cập nhật cân nặng trong Profile để theo dõi.")
                                    .font(.App.captionMedium)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 30)
                            Spacer()
                        }
                    } else {
                        Chart {
                            // Đường mục tiêu (Goal Line) - Chuyển xuống dưới để không đè lên text
                            if let target = plan.targetWeight {
                                RuleMark(y: .value("Mục tiêu", target))
                                    .foregroundStyle(.orange.opacity(0.4))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            }

                            ForEach(planViewModel.weightChartData) { point in
                                LineMark(
                                    x: .value("Ngày", point.dateLabel),
                                    y: .value("Cân nặng", point.weight)
                                )
                                .foregroundStyle(Color.App.primary)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                                
                                PointMark(
                                    x: .value("Ngày", point.dateLabel),
                                    y: .value("Cân nặng", point.weight)
                                )
                                .foregroundStyle(Color.App.primary)
                                .annotation(position: .top) {
                                    Text("\(String(format: "%.1f", point.weight))")
                                        .font(.App.tinyMedium)
                                        .foregroundColor(.black.opacity(0.8))
                                }
                            }
                        }
                        .frame(height: 150)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel()
                                    .font(.App.tiny)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisGridLine().foregroundStyle(Color.black.opacity(0.02))
                                AxisValueLabel {
                                    if let intValue = value.as(Double.self) {
                                        Text("\(Int(intValue))")
                                            .font(.App.tiny)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Circle().fill(Color.App.primary).frame(width: 6, height: 6)
                            Text("Thực tế")
                                .font(.App.small)
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 6) {
                            Rectangle().fill(Color.orange.opacity(0.4)).frame(width: 10, height: 1.5)
                            Text("Mục tiêu (\(String(format: "%.1f", plan.targetWeight ?? 0))kg)")
                                .font(.App.small)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(18)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.01), radius: 10, y: 4)
            }
        }
    
    private var miniStreakSection: some View {
        VStack(alignment: .leading, spacing: 12) { // Đã sửa từ withAlignment thành alignment
            Text("Nhật ký thực hiện tuần này")
                .font(.App.sectionHeader)
                .foregroundColor(.black)
                .padding(.horizontal, 4)
            
            HStack(spacing: 0) {
                ForEach(planViewModel.weeklyStreak, id: \.dayName) { day in
                    VStack(spacing: 8) {
                        Text(day.dayName)
                            .font(day.isToday ? .App.captionMedium : .App.captionMedium)
                            .foregroundColor(day.isToday ? Color.App.primary : .black.opacity(0.6))
                        
                        ZStack {
                            Circle()
                                .fill(day.isCompleted ? Color.App.primaryLight : Color.black.opacity(0.03))
                                .frame(width: 34, height: 34)
                            
                            Image(systemName: day.isCompleted ? "checkmark.circle.fill" : "xmark.circle")
                                .font(.App.title)
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
                    .font(.App.tinyMedium)
                    .foregroundColor(color)
                Text(label)
                    .font(.App.captionMedium)
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                if planViewModel.isEditingPlan {
                    TextField("0", text: value)
                        .font(.App.bodyBold)
                        .keyboardType(.numberPad)
                        .foregroundColor(.black)
                        .frame(maxWidth: 65)
                } else {
                    Text(value.wrappedValue)
                        .font(.App.bodyBold)
                        .foregroundColor(.black)
                }
                
                Text(unit)
                    .font(.App.smallSemibold)
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
                    .font(.App.title2)
                    .foregroundColor(isCancelled ? .red.opacity(0.7) : Color.App.primary)
            }
            .frame(width: 42, height: 42)
            .background(isCancelled ? Color.red.opacity(0.06) : Color.App.primaryLight)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goalType)
                    .font(.App.headline)
                    .foregroundColor(.black)
                
                HStack(spacing: 6) {
                    Text("\(formatDate(plan.startDate)) - \(formatDate(plan.endDate))")
                    Text("•")
                    Text("\(Int(plan.dailyCalories)) kcal")
                }
                .font(.App.captionMedium)
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", plan.targetWeight ?? 0))")
                    .font(.App.bodyLarge)
                    .foregroundColor(.black)
                Text("kg")
                    .font(.App.smallSemibold)
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
    
    private func formatFullDate(_ date: Date?) -> String {
        guard let date = date else { return "--/--/----" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

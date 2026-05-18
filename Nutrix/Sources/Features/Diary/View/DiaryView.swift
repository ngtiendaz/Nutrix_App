import SwiftUI

struct DiaryView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @EnvironmentObject var planViewModel: PlanViewModel
    @State private var isShowingAddFood = false
    @State private var animateButton = false
    @Binding var selectedDate: Date
    
    @State private var isShowingAISetup = false
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    // Thanh chọn ngày và Header
                    TopBar(selectedTab: .constant(.diary), selectedDate: $selectedDate)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // MARK: - Dashboard Section
                        if diaryViewModel.isLoading {
                            loadingPlaceholder
                        } else {
                            if let nutrition = diaryViewModel.dailyNutrition {
                                
                                if let plan = diaryViewModel.currentPlan {
                                    // --- CASE 1: CÓ LỘ TRÌNH (Dù quá khứ hay hiện tại) ---
                                    VStack(spacing: 16) {
                                        NutritionGoalCard(data: nutrition, goal: plan)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                        
                                        if let summary = diaryViewModel.planSummary {
                                            PlanSummaryCard(summary: summary)
                                                .transition(.opacity)
                                        }
                                    }
                                    
                                } else {
                                    // --- KHÔNG CÓ LỘ TRÌNH ---
                                    if isPastDate {
                                        // CASE 3: QUÁ KHỨ + KHÔNG LỘ TRÌNH
                                        ActualNutritionCard(data: nutrition)
                                            .transition(.opacity)
                                    } else {
                                        // CASE 2: HIỆN TẠI + KHÔNG LỘ TRÌNH
                                        VStack(spacing: 16) {
                                            ActualNutritionCard(data: nutrition)
                                                .transition(.opacity)
                                            
                                            emptyPlanView
                                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                        }
                                    }
                                }
                            }
                        }
                        
                        // MARK: - Food List Section
                        foodList
                        
                        Spacer(minLength: 120)
                    }
                }
                .padding(.horizontal, 12)
            }
            .background(Color.App.background)
            .navigationBarHidden(true)
            
            .fullScreenCover(isPresented: $isShowingAISetup) {
                            if let user = loginViewModel.authService.currentUser {
                                AIPlanSetupView(user: user)
                                    .environmentObject(diaryViewModel)
                                    .environmentObject(planViewModel)
                                    .environmentObject(router)
                                    .environmentObject(loginViewModel)
                            }
                        }
            
            // Nút Floating Action Button
            if !isPastDate {
                plusButtonView
                    .scaleEffect(animateButton ? 1.0 : 0.5)
                    .opacity(animateButton ? 1.0 : 0)
            }
        }
        .onAppear {
            setupView()
        }
        .onChange(of: selectedDate) { newDate in
            diaryViewModel.fetchDailyData(for: newDate)
        }
        .sheet(isPresented: $isShowingAddFood) {
            OptionDetail(isPresented: $isShowingAddFood)
                .environmentObject(router)
                .environmentObject(diaryViewModel)
                .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Subviews & Components
    
    private var loadingPlaceholder: some View {
        VStack {
            ProgressView("Đang cập nhật dữ liệu...")
                .scaleEffect(1.1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.03), radius: 10)
    }
    
    private var foodList: some View {
        VStack(alignment: .leading) {
            Text(dateTitle)
                .font(.App.headline)
                .foregroundColor(.black.opacity(0.8))
            
            if diaryViewModel.isLoading {
                EmptyView()
            } else if diaryViewModel.allFoods.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "takeoutbag.and.cup.and.straw")
                        .font(.App.large)
                        .foregroundColor(Color.App.lightGray)
                    Text("Chưa có món ăn nào")
                        .font(.App.subheadlineRegular)
                        .foregroundColor(Color.App.lightGray)
                    
                    if isPastDate {
                        addPastFoodButton.padding(.top, 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(diaryViewModel.allFoods) { food in
                        FoodItem(food: food)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                router.push(.foodDetail(food, diaryViewModel))
                            }
                    }
                    if isPastDate {
                        addPastFoodButton.padding(.top, 8)
                    }
                }
            }
        }
    }
    
    var plusButtonView: some View {
        Button {
            isShowingAddFood = true
        } label: {
            Image(systemName: "fork.knife")
                .font(.App.header)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.App.primary)
                .clipShape(Circle())
                .shadow(color: Color.App.primary.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 70)
    }
    
    private var addPastFoodButton: some View {
        Button(action: { isShowingAddFood = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Bổ sung món ăn cho ngày này")
            }
            .font(.App.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.App.primary)
            .cornerRadius(12)
        }
    }
    
    private var emptyPlanView: some View {
        VStack(spacing: 15) {
            VStack(spacing: 8) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.App.large)
                    .foregroundColor(.orange)
                
                Text("Chưa có lộ trình dinh dưỡng")
                    .font(.App.headline)
                
                Text("Hãy để AI thiết kế lộ trình cá nhân hóa dựa trên mục tiêu cân nặng của bạn.")
                    .font(.App.subheadlineRegular)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: {
                isShowingAISetup = true
            }) {
                Text("Tạo lộ trình ngay")
                    .font(.App.bodyBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(15)
            }
        }
        .padding(25)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Logic Helpers
    private func setupView() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            animateButton = true
        }
        diaryViewModel.fetchDailyData(for: selectedDate)
    }
    
    private var isPastDate: Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: selectedDate) < calendar.startOfDay(for: Date())
    }
    
    private var dateTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Hôm nay"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, dd MMMM, yyyy"
            formatter.locale = Locale(identifier: "vi_VN")
            return formatter.string(from: selectedDate)
        }
    }
}

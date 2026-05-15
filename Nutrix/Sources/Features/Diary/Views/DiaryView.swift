import SwiftUI

struct DiaryView: View {
    @EnvironmentObject var router: AppRouter
    @State private var isShowingAddFood = false
    @State private var animateButton = false
    @StateObject var diaryViewModel = DiaryViewModel()
    @Binding var selectedDate: Date
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    // Thanh chọn ngày và Header
                    TopBar(selectedTab: .constant(.diary), selectedDate: $selectedDate)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // --- PHẦN DASHBOARD / GOAL CARD ---
                        // Logic: Nếu đang tải thì hiện Loading, tải xong mới check Plan
                        if diaryViewModel.isLoading {
                            VStack {
                                ProgressView("Đang cập nhật dữ liệu...")
                                    .scaleEffect(1.1)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .background(Color.white)
                            .cornerRadius(24)
                            .shadow(color: .black.opacity(0.03), radius: 10)
                        } else {
                            if diaryViewModel.hasPlan {
                                if let nutrition = diaryViewModel.dailyNutrition,
                                   let plan = diaryViewModel.currentPlan {
                                    // Hiển thị Card khi đã có đủ dữ liệu thực tế và mục tiêu
                                    NutritionGoalCard(data: nutrition, goal: plan)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            } else {
                                // Hiển thị nút mời tạo lộ trình nếu Firebase trả về rỗng
                                emptyPlanView
                                    .transition(.opacity)
                            }
                        }
                        // ----------------------------------
                        
                        // Danh sách món ăn trong ngày
                        foodList
                        
                        Spacer(minLength: 120)
                    }
                }
                .padding(.horizontal, 12)
            }
            .background(Color.App.background)
            .navigationBarHidden(true)
            
            // Nút Thêm món ăn nhanh (Floating Action Button)
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
            // Khi người dùng đổi ngày, fetch lại toàn bộ
            diaryViewModel.fetchDailyData(for: newDate)
        }
        .sheet(isPresented: $isShowingAddFood) {
            OptionDetail(isPresented: $isShowingAddFood)
                .environmentObject(router)
                .environmentObject(diaryViewModel)
                .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Helper Methods
    private func setupView() {
        // Animation cho nút FAB
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            animateButton = true
        }
        // Gọi hàm fetch tổng hợp (Foods + Plan)
        diaryViewModel.fetchDailyData(for: selectedDate)
    }
    
    // MARK: - Components
    
    var plusButtonView: some View {
        Button {
            isShowingAddFood = true
        } label: {
            Image(systemName: "fork.knife")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Color.App.primary)
                .clipShape(Circle())
                .shadow(color: Color.App.primary.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 70)
    }
    
    private var foodList: some View {
        VStack(alignment: .leading) {
            Text(dateTitle)
                .font(Font.headline.bold())
                .foregroundColor(.black.opacity(0.8))
                .padding(.top, 8)
            
            if diaryViewModel.isLoading {
                EmptyView() // Đã có loading ở trên Dashboard
            } else if diaryViewModel.allFoods.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "takeoutbag.and.cup.and.straw")
                        .font(.system(size: 40))
                        .foregroundColor(Color.App.lightGray)
                    Text("Chưa có món ăn nào")
                        .font(.subheadline)
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
    
    private var addPastFoodButton: some View {
        Button(action: { isShowingAddFood = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Bổ sung món ăn cho ngày này")
            }
            .font(.subheadline.bold())
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
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("Chưa có lộ trình dinh dưỡng")
                    .font(.headline)
                
                Text("Hãy để AI thiết kế lộ trình cá nhân hóa dựa trên mục tiêu cân nặng của bạn.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: {
//                router.push(.createAIPlan)
            }) {
                Text("Tạo lộ trình ngay")
                    .font(.system(size: 16, weight: .bold))
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

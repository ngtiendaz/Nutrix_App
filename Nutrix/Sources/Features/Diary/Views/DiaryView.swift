//
//  DiaryView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

struct DiaryView: View {
    @EnvironmentObject var router: AppRouter
    @State private var isShowingAddFood = false
    @State private var animateButton = false
    @StateObject var diaryViewModel = DiaryViewModel()
    @Binding var selectedDate: Date
    
    let sampleData = DailyNutrition(
        userId: "123",
        date: "2026-04-16",
        totalCalories: 1200,
        totalProtein: 45,
        totalCarbs: 150,
        totalFat: 30,
        totalWater: 1.5,
        totalBurned: 100
    )
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading) {
                    TopBar(selectedTab: .constant(.diary), selectedDate: $selectedDate)
//                        .padding(.top, 10)
                    VStack(alignment: .leading, spacing: 16) {
                        if let nutrition = diaryViewModel.dailyNutrition {
                            NutritionGoalCard(data: nutrition)
                        } else {
                            ProgressView().frame(height: 150)
                        }
                    
                        foodList
                        
                        Spacer(minLength: 120)
                    }
                }
                .padding(.horizontal, 12)
            }
            .background(Color.App.background)
            .navigationBarHidden(true)
            if !isPastDate {
                plusButtonView
                    .scaleEffect(animateButton ? 1.0 : 0.5)
                    .opacity(animateButton ? 1.0 : 0)
            }
        }
        .onAppear {
            // 1. Animation cho nút Plus
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                animateButton = true
            }
            // 2. Fetch dữ liệu từ ViewModel
            diaryViewModel.fetchDailyFoods(for: selectedDate)
        }
        .onDisappear {
            animateButton = false
        }
        // Tự động load lại khi ngày thay đổi (nếu bạn có bộ chọn ngày)
        .onChange(of: selectedDate) { newDate in
            diaryViewModel.fetchDailyFoods(for: newDate)
        }
        .sheet(isPresented: $isShowingAddFood) {
            OptionDetail()
                .environmentObject(router)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
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
        VStack(alignment: .leading){
            Text(dateTitle)
                .font(Font.headline.bold())
                .foregroundColor(.black.opacity(0.8))
                .padding(.top, 8)
            if diaryViewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Đang tải món ăn...")
                    Spacer()
                }
                .padding()
            } else if diaryViewModel.allFoods.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "takeoutbag.and.cup.and.straw")
                        .font(.system(size: 40))
                        .foregroundColor(Color.App.lightGray)
                    Text("Chưa có món ăn nào được ghi lại")
                        .font(.subheadline)
                        .foregroundColor(Color.App.lightGray)
                    if isPastDate {
                        addPastFoodButton
                            .padding(.top, 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Hiển thị các món ăn lẻ
                VStack(spacing: 12) {
                        ForEach(diaryViewModel.allFoods) { food in
                            FoodItem(food: food)
                                .contentShape(Rectangle()) // Giúp vùng bấm nhạy hơn
                                .onTapGesture {
                                    router.push(.foodDetail(food))
                                }
                        }
                    if isPastDate {
                        addPastFoodButton
                            .padding(.top, 8)
                    }
                }
            }
            
        }
    }
    private var isPastDate: Bool {
            let calendar = Calendar.current
            return calendar.startOfDay(for: selectedDate) < calendar.startOfDay(for: Date())
        }
    private func handleAddPastFood() {
            isShowingAddFood = true
        }
    private var addPastFoodButton: some View {
            Button(action: handleAddPastFood) {
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
                .shadow(color: Color.App.primary.opacity(0.2), radius: 5, x: 0, y: 3)
            }
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

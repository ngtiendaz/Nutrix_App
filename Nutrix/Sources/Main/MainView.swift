//
//  MainView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @EnvironmentObject var authService: FirebaseAuthService
    @State private var selectedDate = Date()
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Lớp 1: Nội dung chính hiển thị toàn màn hình
            contentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Lớp 2: Thanh Menu dưới đáy
            BottomMenuBar(selectedTab: $router.selectedTab)
                .offset(y: 26)
            
            // Lớp 3: Loading Overlay dùng chung (hiển thị đè lên tất cả khi router.isLoading = true)
            if router.isLoading {
                LoadingOverlay() // Sử dụng file LoadingOverlay.swift đã tạo
                    .transition(.opacity)
                    .zIndex(998) // Nằm dưới Notification một chút
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(
            // Lớp 4: Thông báo Notification kiểu mới (Banner Apple Style)
            AppNotificationView(data: router.toast)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: router.toast != nil)
                .zIndex(999) // Luôn nằm trên cùng
        )
        // Animation mượt mà cho toàn bộ MainView khi các trạng thái thay đổi
        .animation(.easeInOut(duration: 0.25), value: router.isLoading)
    }

    var contentView: some View {
        Group {
            switch router.selectedTab {
            case .diary:
                NavigationStack(path: $router.diaryPath) {
                    DiaryView(selectedDate: $selectedDate)
                        .navigationDestination(for: AppDestination.self) { destination in
                            buildDestinationView(destination)
                        }
                }
            case .chart:
                NavigationStack(path: $router.chartPath) {
                    ChartView(selectedDate: $selectedDate)
                        .navigationDestination(for: AppDestination.self) { destination in
                            buildDestinationView(destination)
                        }
                }.environmentObject(authService)
//            case .barcode:
//                NavigationStack(path: $router.barcodePath) {
//                    NutritionView(selectedDate: $selectedDate)
//                        .navigationDestination(for: AppDestination.self) { destination in
//                            buildDestinationView(destination)
//                        }
//                }
            case .profile:
                NavigationStack(path: $router.profilePath) {
                    ProfileView(selectedDate: $selectedDate)
                        .navigationDestination(for: AppDestination.self) { destination in
                            buildDestinationView(destination)
                        }
                }
            case .activity:
                NavigationStack(path: $router.activityPath) {
                    ActivityView(selectedDate: $selectedDate)
                        .navigationDestination(for: AppDestination.self) { destination in
                            buildDestinationView(destination)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    func buildDestinationView(_ destination: AppDestination) -> some View {
        switch destination {
        case .foodDetail(let food, let diaryVM): // Nhận diaryVM từ destination
                FoodDetailView(food: food, mealDate: selectedDate)
                    .environmentObject(router)
                    .environmentObject(diaryVM)
        case .nutritionPlan(let plan):
            NutritionPlanView(plan: plan, onApplied: {

            })
            .environmentObject(router)
            .environmentObject(diaryViewModel)
        default:
            VStack {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.5))
                Text("Màn hình đang phát triển")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }
}

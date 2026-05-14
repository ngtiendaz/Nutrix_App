//
//  MainView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var router: AppRouter
    @State private var selectedDate = Date()
    var body: some View {
        ZStack(alignment: .bottom) {
                // Lớp 1: Content hiển thị tràn toàn màn hình
                contentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all, edges: .bottom) // Để nội dung có thể cuộn xuống dưới thanh menu

                // Lớp 2: BottomMenuBar nằm đè lên trên
                BottomMenuBar(selectedTab: $router.selectedTab)
                .offset(y: 26)
            }
        .overlay(
            ToastView(toast: router.toast)
                .animation(.spring(response: 0.35, dampingFraction: 0.85),
                           value: router.toast != nil)
                .zIndex(999)
            
        ).overlay {
            if router.isLoading {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .animation(.easeInOut, value: router.isLoading)
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
                    ChartView()
                        .navigationDestination(for: AppDestination.self) { destination in
                            buildDestinationView(destination)
                        }
                }
            case .nutrition:
                NavigationStack(path: $router.nutritionPath) {
                    NutritionView()
                        .navigationDestination(for: AppDestination.self) { destination in
                            buildDestinationView(destination)
                        }
                }
            case .profile:
                NavigationStack(path: $router.profilePath) {
                    ProfileView(selectedDate: $selectedDate).navigationDestination(for: AppDestination.self) { destination in
                        buildDestinationView(destination) }
                }
            case .setting:
                NavigationStack(path: $router.settingPath) {
                    SettingView().navigationDestination(for: AppDestination.self) { destination in
                        buildDestinationView(destination) }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    @ViewBuilder
        func buildDestinationView(_ destination: AppDestination) -> some View {
            switch destination {
                case .foodDetail:
                    Text("Chi tiết món ăn")
                default:
                    Text("Màn hình đang phát triển")
                }
        }
    }

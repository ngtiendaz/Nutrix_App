//
//  MainView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var router: AppRouter
    var body: some View {
        ZStack(alignment: .bottom){
            Color.App.background.ignoresSafeArea()
            VStack(alignment: .leading){
                TopBar(selectedTab: $router.selectedTab)
                
                contentView
                
                BottomMenuBar(selectedTab: $router.selectedTab).padding(.bottom, -20)
            }
        }
    }

    var contentView: some View {
        Group {
            switch router.selectedTab {
            case .diary:
                NavigationStack(path: $router.diaryPath) {
                    DiaryView()
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
                    ProfileView().navigationDestination(for: AppDestination.self) { destination in
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

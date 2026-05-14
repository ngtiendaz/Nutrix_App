//
//  ContentView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        ZStack{
            Group {
                switch router.currentRoot {
                case .splash:
                    SplashScreenView()
                case .login:
                    LoginView(viewModel: viewModel)
                case .main:
                    MainView()
                        .environmentObject(viewModel)
                }
            }
            .onAppear {
                viewModel.setRouter(router)
                DispatchQueue.main.async {
                    viewModel.authService.checkLoginStatus()
                }
            }
            AppNotificationView(data: router.toast)
                    .zIndex(999)
                
                // LỚP LOADING (Phủ toàn bộ app)
                if router.isLoading {
                    LoadingOverlay()
                        .zIndex(998)
                        .transition(.opacity)
                }
        }.animation(.linear(duration: 0.1), value: router.isLoading) // Tốc độ phản hồi ẩn/hiện cực nhanh
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: router.toast != nil) // Thông báo hiện ra có độ nảy

    }
}
#Preview {
    ContentView().environmentObject(AppRouter())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

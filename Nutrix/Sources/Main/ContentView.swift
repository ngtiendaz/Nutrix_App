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
    }
}
#Preview {
    ContentView().environmentObject(AppRouter())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

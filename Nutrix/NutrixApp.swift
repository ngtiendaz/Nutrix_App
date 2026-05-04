//
//  NutrixApp.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
import FirebaseCore // Import thư viện lõi

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure() // Lệnh kích hoạt Firebase
    return true
  }
}

@main
struct NutrixApp: App {
    // Đăng ký AppDelegate để Firebase khởi tạo đúng cách
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject  var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(router)
        }
    }
}

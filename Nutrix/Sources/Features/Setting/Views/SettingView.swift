//
//  SettingView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
struct SettingView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var router: AppRouter
    @State private var showingLogoutAlert = false
    var body: some View {
        ZStack{
            Color.App.background
            Button {
                showingLogoutAlert = true
            } label: {
                Text("SettingView").foregroundColor(.black)
            }
        }.alert(isPresented: $showingLogoutAlert) {
            Alert(
                title: Text("Xác nhận đăng xuất"),
                message: Text("Bạn có chắc chắn muốn thoát khỏi ứng dụng Nutrix không?"),
                primaryButton: .destructive(Text("Đăng xuất")) {
                    loginViewModel.logout()
//                    router.popToRoot()
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        }
    }
}

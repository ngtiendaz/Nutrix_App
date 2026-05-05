//
//  ProfileView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
struct ProfileView: View {
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    var body: some View {
            VStack {
                if let user = loginViewModel.authService.currentUser {
                    Text("Xin chào, \(user.name)!")
                        .font(.title)
                    Text("Email: \(user.email)")
                } else {
                    Text("Đang tải thông tin...")
                }
            }
        }
}

//
//  ProfileView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
struct ProfileView: View {
    
    @EnvironmentObject var loginViewModel: LoginViewModel
    @Binding var selectedDate: Date
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.App.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading) {
                    TopBar(selectedTab: .constant(.profile), selectedDate: $selectedDate)
                    
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
                .padding(.horizontal, 12)
            }
        }
    }
}

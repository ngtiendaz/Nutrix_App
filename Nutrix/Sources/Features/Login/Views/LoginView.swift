//
//  LoginView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

//
//  LoginView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    
    var body: some View {
        ZStack {
            // Nền app - Tap vào đây để ẩn bàn phím
            Color.App.background.ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // MARK: - Logo & Tiêu đề
                    headerSection
                    
                    // MARK: - Form nhập liệu
                    VStack(spacing: 18) {
                        customTextField(placeholder: "Email", text: $email, icon: "envelope.fill")
                        
                        // Ô mật khẩu chính
                        CustomSecureField(placeholder: "Mật khẩu", text: $password, icon: "lock.fill")
                        
                        // Chỉ hiển thị ô xác nhận mật khẩu khi ở chế độ Đăng ký
                        if isSignUp {
                            CustomSecureField(placeholder: "Xác nhận mật khẩu", text: $confirmPassword, icon: "checkmark.circle.fill")
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale),
                                    removal: .opacity
                                ))
                        }
                        
                        // Hiển thị thông báo lỗi từ ViewModel
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.App.captionMedium)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 5)
                        }
                    }
                    .padding(.horizontal, 25)
                    
                    actionButton
                    
                    googleLoginSection
                    
                    toggleModeSection
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") {
                        hideKeyboard()
                    }
                    .foregroundColor(Color.App.primary)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.fill")
                .font(.App.extraLarge)
                .foregroundColor(Color.App.primary)
            
            Text("Nutrix")
                .font(.App.large)
                .foregroundColor(Color.App.primary)
            
            Text(isSignUp ? "Bắt đầu hành trình dinh dưỡng" : "Quản lý dinh dưỡng cá nhân")
                .font(.App.subheadlineRegular)
                .foregroundColor(Color.App.lightGray)
        }
        .padding(.top, 40)
    }
    
    private var actionButton: some View {
        Button(action: {
            hideKeyboard()
            withAnimation {
                if isSignUp {
                    if password == confirmPassword {
                        viewModel.register(email: email, password: password)
                    } else {
                        viewModel.errorMessage = "Mật khẩu xác nhận không khớp"
                    }
                } else {
                    viewModel.login(email: email, password: password)
                }
            }
        }) {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(isSignUp ? "Đăng ký tài khoản" : "Đăng nhập")
                        .font(.App.headline)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.isLoading ? Color.App.primary.opacity(0.6) : Color.App.primary)
            .cornerRadius(15)
            .shadow(color: Color.App.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.isLoading)
        .padding(.horizontal, 25)
    }
    
    private var googleLoginSection: some View {
        VStack(spacing: 15) {
            HStack {
                Rectangle().frame(height: 1).foregroundColor(Color.App.lightGray.opacity(0.3))
                Text("Hoặc").font(.App.tinyMedium).foregroundColor(Color.App.lightGray)
                Rectangle().frame(height: 1).foregroundColor(Color.App.lightGray.opacity(0.3))
            }
            .padding(.horizontal, 25)
            
            Button(action: {
                hideKeyboard()
                viewModel.loginWithGoogle()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "g.circle.fill")
                        .font(.App.title3)
                    Text("Tiếp tục với Google")
                        .font(.App.bodyBold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, 25)
        }
    }
    
    private var toggleModeSection: some View {
        HStack(spacing: 5) {
            Text(isSignUp ? "Đã có tài khoản?" : "Chưa có tài khoản?")
                .foregroundColor(Color.App.lightGray)
            
            Button(action: {
                withAnimation(.spring()) {
                    isSignUp.toggle()
                    viewModel.errorMessage = nil // Xóa lỗi cũ khi đổi mode
                }
            }) {
                Text(isSignUp ? "Đăng nhập ngay" : "Đăng ký ngay")
                    .fontWeight(.bold)
                    .foregroundColor(Color.App.primary)
            }
        }
        .font(.App.tinyMedium)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    func customTextField(placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.App.primary.opacity(0.7))
                .frame(width: 25)
            
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.black.opacity(0.8))
                }
                TextField("", text: text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .foregroundColor(.black)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
    }
}


extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

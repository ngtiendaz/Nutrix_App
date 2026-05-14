//
//  ProfileView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @StateObject private var vm = ProfileViewModel()
    @Binding var selectedDate: Date
    
    var body: some View {
        ZStack {
            Color.App.background
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    TopBar(selectedTab: .constant(.profile), selectedDate: $selectedDate)
                    
                    // MARK: - Main User Card
                    VStack(spacing: 20) {
                        HStack(alignment: .center, spacing: 15) {
                            if let photoURL = loginViewModel.authService.userPhotoURL?.absoluteString {
                                CachedImage(urlString: photoURL, width: 66, height: 66, cornerRadius: 33)
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.blue.opacity(0.8))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(loginViewModel.authService.currentUser?.name ?? "Người dùng")
                                    .font(.title3.bold())
                                    .foregroundColor(.black)
                                
                                Text(loginViewModel.authService.currentUser?.email ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                if vm.isEditing {
                                    vm.saveProfile(authService: loginViewModel.authService)
                                    hideKeyboard()
                                } else {
                                    vm.isEditing.toggle()
                                }
                            }) {
                                Image(systemName: vm.isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(vm.isEditing ? .green : .blue)
                            }
                        }
                        
                        Divider().background(Color.gray.opacity(0.2))
                        
                        // MARK: - Information Rows (Đã bổ sung các trường)
                        VStack(alignment: .leading,spacing: 18) {
                            InfoRow(label: "Họ và tên", value: $vm.name, isEditing: vm.isEditing, placeholder: "Nhập tên")
                            
                            InfoRow(label: "Tuổi", value: $vm.age, unit: "tuổi", isEditing: vm.isEditing, placeholder: "0")
                            
                            // Giới tính Row - Fix Nhảy Layout
                            HStack(spacing: 0) {
                                Text("Giới tính")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(width: 100, alignment: .leading)
                                
                                Text(":")
                                    .foregroundColor(.black)
                                    .padding(.trailing, 10)
                                
                                ZStack(alignment: .leading) {
                                    if vm.isEditing {
                                        Picker("", selection: $vm.gender) {
                                            ForEach(vm.genders, id: \.self) { Text($0) }
                                        }
                                        .pickerStyle(.menu)
                                        .labelsHidden()
                                        .frame(height: 36)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    } else {
                                        Text(vm.gender)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)
                                            .frame(height: 36)
                                        Spacer()
                                    }
                                }
                            }
                            
                            InfoRow(label: "Chiều cao", value: $vm.height, unit: "cm", isEditing: vm.isEditing, placeholder: "0")
                            
                            InfoRow(label: "Cân nặng", value: $vm.weight, unit: "kg", isEditing: vm.isEditing, placeholder: "0")
                            
                            // Vận động Row - Fix Nhảy Layout
                            HStack(spacing: 0) {
                                Text("Vận động")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(width: 100, alignment: .leading)
                                
                                Text(":")
                                    .foregroundColor(.black)
                                    .padding(.trailing, 10)
                                
                                ZStack(alignment: .leading) {
                                    if vm.isEditing {
                                        Picker("", selection: $vm.activityLevel) {
                                            ForEach(vm.activityLevels, id: \.self) { Text($0) }
                                        }
                                        .pickerStyle(.menu)
                                        .labelsHidden()
                                        .frame(height: 36)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                    } else {
                                        Text(vm.activityLevel)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black)
                                            .frame(height: 36)
                                        Spacer()
                                    }
                                }
                            }
                        }.padding(.vertical, 5)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .onAppear {
                        vm.setupFields(user: loginViewModel.authService.currentUser)
                    }

                    // MARK: - Plan Section (Giữ nguyên)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Mục tiêu & Kế hoạch")
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Button(action: { print("Tạo plan mới") }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tạo kế hoạch dinh dưỡng")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("AI sẽ giúp bạn tính toán lượng Calo dựa trên chỉ số cơ thể.")
                                        .font(.caption)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title2)
                            }
                            .padding(24)
                            .background(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

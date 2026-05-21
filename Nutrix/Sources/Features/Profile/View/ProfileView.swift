//
//  ProfileView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var router: AppRouter
    @StateObject private var profileViewModel = ProfileViewModel()
    @Binding var selectedDate: Date
    @State private var isShowingHistory = false
    @State private var isShowingAISetup = false
    @State private var showingLogoutAlert = false
    
    enum FieldSection {
        case basicInfo
        case metrics
    }
    @State private var scrollTarget: FieldSection?
    
    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        TopBar(selectedTab: .constant(.profile), selectedDate: $selectedDate)
                        
                        // 1. Profile Card (Tên, Tuổi, Giới tính, Vận động)
                        mainUserCard
                            .id(FieldSection.basicInfo)
                        
                        BodyMetricsCard(
                            vm: profileViewModel,
                            onUpdate: { handleBodyMetricsUpdate() },
                            onShowHistory: {
                                profileViewModel.fetchHistory(authService: loginViewModel.authService)
                                isShowingHistory = true
                            },
                            onEditing: { scrollTarget = .metrics }
                        )                        .id(FieldSection.metrics)
                        
                        // 4. Settings List
                        VStack(spacing: 12) {
                            settingItem(icon: "bell.fill", title: "Thông báo", color: .orange)
                            settingItem(icon: "lock.shield.fill", title: "Bảo mật", color: .blue)
                            Button(action: { showingLogoutAlert = true }) {
                                settingItem(icon: "door.right.hand.open", title: "Đăng xuất", color: .red, isLast: true)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 12)
                }
                .onChange(of: scrollTarget) { newValue in
                    if let section = newValue {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            proxy.scrollTo(section, anchor: .center)
                        }
                    }
                }
                .onChange(of: profileViewModel.isEditingBasic) { newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo(FieldSection.basicInfo, anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: profileViewModel.isEditingMetrics) { newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo(FieldSection.metrics, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .alert("Đăng xuất", isPresented: $showingLogoutAlert) {
            Button("Hủy", role: .cancel) { }
            Button("Đăng xuất", role: .destructive) {
                loginViewModel.logout()
            }
        } message: {
            Text("Bạn có chắc chắn muốn đăng xuất không?")
        }
        .sheet(isPresented: $isShowingHistory) {
            BodyMetricsHistorySheet(history: profileViewModel.metricsHistory)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .contentShape(Rectangle())
        .onTapGesture { hideKeyboard() }
        .onAppear { profileViewModel.setupFields(user: loginViewModel.authService.currentUser) }
    }
    
    private func handleBodyMetricsUpdate() {
            if profileViewModel.isEditingMetrics {
                router.showLoading()
                profileViewModel.saveBodyMetrics(authService: loginViewModel.authService) { success in
                    router.hideLoading()
                    if success {
                        router.showToast(message: "Đã cập nhật chỉ số cơ thể", type: .success)
                        profileViewModel.fetchHistory(authService: loginViewModel.authService)
                    }
                }
                hideKeyboard()
            } else {
                withAnimation { profileViewModel.isEditingMetrics = true }
            }
        }

    private var mainUserCard: some View {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    avatarSection
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loginViewModel.authService.currentUser?.name ?? "Người dùng")
                            .font(.App.title2).foregroundColor(.black)
                        Text(loginViewModel.authService.currentUser?.email ?? "")
                            .font(.App.body).foregroundColor(.gray)
                    }
                    Spacer()
                    editBasicInfoButton // Nút này chỉ quản lý InfoRow bên dưới
                }
                
                Divider().background(Color.black.opacity(0.05))
                
                VStack(alignment: .leading, spacing: 10) {
                    InfoRow(label: "Họ và tên", value: $profileViewModel.name, isEditing: profileViewModel.isEditingBasic, placeholder: "Tên", onEditing: { scrollTarget = .basicInfo })
                    InfoRow(label: "Tuổi", value: $profileViewModel.age, unit: "tuổi", isEditing: profileViewModel.isEditingBasic, placeholder: "0", onEditing: { scrollTarget = .basicInfo })
                    genderPickerRow
                    activityPickerRow
                }
            }
            .padding(20).background(Color.white).cornerRadius(24).shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 8)
        }

    private var editBasicInfoButton: some View {
            Button(action: {
                if profileViewModel.isEditingBasic {
                    router.showLoading()
                    profileViewModel.saveBasicInfo(authService: loginViewModel.authService) { success in
                        router.hideLoading()
                        if success { router.showToast(message: "Đã cập nhật hồ sơ", type: .success) }
                    }
                    hideKeyboard()
                } else {
                    withAnimation { profileViewModel.isEditingBasic.toggle() }
                }
            }) {
                Text(profileViewModel.isEditingBasic ? "Lưu" : "Sửa")
                    .font(.App.subheadline)
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(profileViewModel.isEditingBasic ? Color.green.opacity(0.1) : Color.App.primary.opacity(0.1))
                    .foregroundColor(profileViewModel.isEditingBasic ? .green : Color.App.primary)
                    .clipShape(Capsule())
            }
        }
    
    private var avatarSection: some View {
            ZStack {
                if let photoURL = loginViewModel.authService.userPhotoURL?.absoluteString {
                    CachedImage(urlString: photoURL, width: 68, height: 68, cornerRadius: 34)
                } else {
                    Circle().fill(Color.App.primaryLight).frame(width: 68, height: 68)
                    Image(systemName: "person.fill").font(.App.display).foregroundColor(Color.App.primary)
                }
            }
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.08), radius: 4)
        }
    
    private var genderPickerRow: some View {
            HStack(spacing: 0) {
                Text("Giới tính").font(.App.headline).frame(width: 100, alignment: .leading).foregroundColor(.black)
                Text(":").padding(.trailing, 10).foregroundColor(.black)
                if profileViewModel.isEditingBasic {
                    Picker("", selection: $profileViewModel.gender) { ForEach(profileViewModel.genders, id: \.self) { Text($0) } }
                        .pickerStyle(.menu).labelsHidden().frame(height: 40).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.04)).cornerRadius(10)
                } else {
                    Text(profileViewModel.gender).font(.App.headline).foregroundColor(.black).padding(.horizontal, 12).frame(height: 40)
                    Spacer()
                }
            }
        }
    
    private var activityPickerRow: some View {
            HStack(spacing: 0) {
                Text("Vận động").font(.App.headline).frame(width: 100, alignment: .leading).foregroundColor(.black)
                Text(":").padding(.trailing, 10).foregroundColor(.black)
                if profileViewModel.isEditingBasic {
                    Picker("", selection: $profileViewModel.activityLevel) { ForEach(profileViewModel.activityLevels, id: \.self) { Text($0) } }
                        .pickerStyle(.menu).labelsHidden().frame(height: 40).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.04)).cornerRadius(10)
                } else {
                    Text(profileViewModel.activityLevel).font(.App.headline).foregroundColor(.black).padding(.horizontal, 12).frame(height: 40)
                    Spacer()
                }
            }
        }
    
    private func settingItem(icon: String, title: String, color: Color, isLast: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.App.sectionHeader).foregroundColor(color).frame(width: 32, height: 32).background(color.opacity(0.1)).cornerRadius(10)
            Text(title).font(.App.headline).foregroundColor(.black.opacity(0.8))
            Spacer()
            if !isLast { Image(systemName: "chevron.right").font(.App.caption).foregroundColor(.gray.opacity(0.3)) }
        }
        .padding(12).background(Color.white).cornerRadius(16).shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

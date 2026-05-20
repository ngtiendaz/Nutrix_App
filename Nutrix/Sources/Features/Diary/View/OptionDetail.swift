//
//  AddFoodView.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//

import SwiftUI

struct OptionDetail: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject  var diaryViewModel: DiaryViewModel
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    
    @State private var isShowingListFood = false
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 25) {
            // Header (Giữ nguyên của bạn)
            headerView
            
            // Cards chọn nguồn ảnh
            HStack(spacing: 20) {
                Button {
                    diaryViewModel.handleCameraSelection()
                } label: {
                    SelectionCard(title: "Chụp ảnh", icon: "camera.fill", color: Color.App.primary)
                }
                
                Button {
                    diaryViewModel.showLibrary()
                } label: {
                    SelectionCard(title: "Thư viện", icon: "photo.on.rectangle.angled",
                                  color: Color.App.primary.opacity(0.1), iconColor: Color.App.primary)
                }
            }
            
            dividerView
            quickSelectBarcodeButton
//            quickSelectButton
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.App.background.ignoresSafeArea())
        
        .sheet(isPresented: $diaryViewModel.isShowingLibrary) {
            ImagePicker(image: $diaryViewModel.selectedImage, sourceType: .photoLibrary)
                .ignoresSafeArea()
        }

        // 2. Mở Camera hệ thống
        .fullScreenCover(isPresented: $diaryViewModel.isShowingCamera) {
            ImagePicker(image: $diaryViewModel.selectedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $isShowingListFood) {
//            ListFood()
        }
        // Sửa lại đoạn FullScreenCover
        .fullScreenCover(isPresented: Binding(
            get: { diaryViewModel.selectedImage != nil },
            set: { if !$0 { diaryViewModel.selectedImage = nil } }
        )) {
            if let uiImage = diaryViewModel.selectedImage {
                FoodAnalysisView(
                    image: uiImage,
                    authService: loginViewModel.authService,
                    onSaveSuccess: {
                        isPresented = false
                        diaryViewModel.refreshData()
                    }
                )
                .environmentObject(router)         // Tiêm router vào đây
                .environmentObject(diaryViewModel) // Tiêm VM vào đây
            }
        }
        .alert("Cấp quyền Camera", isPresented: $diaryViewModel.isShowingPermissionAlert) {
                    Button("Để sau", role: .cancel) { }
                    Button("Đi tới Cài đặt") {
                        PermissionManager.shared.openAppSettings()
                    }
        } message: {
            Text("Nutrix cần truy cập Camera để nhận diện món ăn. Vui lòng bật quyền này trong Cài đặt.")
        }
    }
    
    // MARK: - Subviews cho gọn code
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Thêm món").font(.App.title2).foregroundColor(.black)
                Text("Chụp ảnh món ăn của bạn").font(.App.bodyLarge).foregroundColor(.gray)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.App.title2).foregroundColor(.gray.opacity(0.3))
            }
        }.padding(.top, 30)
    }

    private var dividerView: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
            Text("hoặc chọn nhanh").font(.App.body).foregroundColor(.gray).padding(.horizontal, 8).layoutPriority(1)
            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
        }
    }

    private var quickSelectButton: some View {
        Button { } label: {
            HStack(spacing: 15) {
                Text("🍜").font(.App.display)
                VStack(alignment: .leading) {
                    Text("Món ăn có sẵn").font(.App.title).foregroundColor(.black)
                    Text("24 món phổ biến").font(.App.body).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding().background(Color.white).cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
    // Sửa lại thuộc tính View này của bạn
        private var quickSelectBarcodeButton: some View {
            Button {
                isShowingListFood = true // 🌟 Kích hoạt bật màn hình
            } label: {
                HStack(spacing: 15) {
                    Text("🍝").font(.App.display)
                    VStack(alignment: .leading) {
                        Text("Danh sách có sẵn").font(.App.headline).foregroundColor(.black)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.gray)
                }
                .padding().background(Color.white).cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            }
        }
}


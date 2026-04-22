//
//  AddFoodView.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//

import SwiftUI

struct AddFoodView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var addFoodViewModel = AddFoodViewModel()
    @EnvironmentObject var router: AppRouter

    
    var body: some View {
        VStack(spacing: 25) {
            // Header (Giữ nguyên của bạn)
            headerView
            
            // Cards chọn nguồn ảnh
            HStack(spacing: 20) {
                Button {
                    addFoodViewModel.handleCameraSelection()
                } label: {
                    SelectionCard(title: "Chụp ảnh", icon: "camera.fill", color: Color.App.primary)
                }
                
                Button {
                    addFoodViewModel.showLibrary()
                } label: {
                    SelectionCard(title: "Thư viện", icon: "photo.on.rectangle.angled",
                                  color: Color.App.primary.opacity(0.1), iconColor: Color.App.primary)
                }
            }
            
            dividerView
            quickSelectButton
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.App.background.ignoresSafeArea())
        
        .fullScreenCover(isPresented: $addFoodViewModel.isShowingCamera) {
            ScanFoodView()
        }
        .sheet(isPresented: $addFoodViewModel.isShowingLibrary) {
            ImagePicker(image: .constant(nil), sourceType: .photoLibrary)
                .ignoresSafeArea()
        }
        .alert("Cấp quyền Camera", isPresented: $addFoodViewModel.isShowingPermissionAlert) {
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
                Text("Thêm món").font(.system(size: 28, weight: .bold)).foregroundColor(.black)
                Text("Chụp ảnh món ăn của bạn").font(.system(size: 16)).foregroundColor(.gray)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle").font(.system(size: 30)).foregroundColor(.gray.opacity(0.3))
            }
        }.padding(.top, 30)
    }

    private var dividerView: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
            Text("hoặc chọn nhanh").font(.system(size: 14)).foregroundColor(.gray).padding(.horizontal, 8).layoutPriority(1)
            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.2))
        }
    }

    private var quickSelectButton: some View {
        Button { } label: {
            HStack(spacing: 15) {
                Text("🍜").font(.system(size: 30))
                VStack(alignment: .leading) {
                    Text("Món ăn có sẵn").font(.system(size: 18, weight: .bold)).foregroundColor(.black)
                    Text("24 món phổ biến").font(.system(size: 14)).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding().background(Color.white).cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
}

struct SelectionCard: View {
    let title: String
    let icon: String
    let color: Color
    var iconColor: Color = .white
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(iconColor)
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(iconColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(color)
        .cornerRadius(25)
    }
}

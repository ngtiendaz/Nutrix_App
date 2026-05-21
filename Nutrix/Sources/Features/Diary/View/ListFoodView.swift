//
//  ListFood.swift
//  Nutrix
//

import SwiftUI

struct ListFoodView: View {
    @StateObject private var listFoodViewModel = ListFoodViewModel() // Hãy đảm bảo tên ViewModel đúng với project của bạn
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    
    // 👉 THÊM: State quản lý món ăn được chọn để mở Fullscreen
    @State private var selectedFood: Food?
    
    var onSaveSuccess: (() -> Void)? = nil
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBarView
                
                if listFoodViewModel.isLoading {
                    ProgressView("Đang tải danh sách món ăn...")
                        .padding(.top, 40)
                        .tint(Color.App.primary)
                    Spacer()
                } else if let error = listFoodViewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text("❌").font(.largeTitle)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(Color.App.lightGray)
                            .multilineTextAlignment(.center)
                        
                        Button("Thử lại") { listFoodViewModel.loadFoods() }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.App.primary)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    Spacer()
                } else if listFoodViewModel.filteredFoods.isEmpty {
                    VStack(spacing: 8) {
                        Text("🔍").font(.largeTitle)
                        Text("Không tìm thấy món ăn nào.")
                            .foregroundColor(Color.App.lightGray)
                    }
                    .padding(.top, 40)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(listFoodViewModel.filteredFoods) { food in
                                
                                // 👉 THAY ĐỔI: Đổi NavigationLink thành Button
                                Button {
                                    selectedFood = food
                                } label: {
                                    foodRowCard(for: food)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Danh sách có sẵn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.App.lightGray)
                            .font(.title3)
                    }
                }
            }
            .background(Color.App.background.ignoresSafeArea())
            .onAppear {
                listFoodViewModel.loadFoods()
            }
            // 👉 THÊM: Kích hoạt Fullscreen Cover khi selectedFood có giá trị
            .fullScreenCover(item: $selectedFood) { food in
                FoodAnalysisView(
                    food: food,
                    image: nil,
                    authService: FirebaseAuthService(),
                    isEditableNutrition: true,
                    onSaveSuccess: {
                        onSaveSuccess?()
                        dismiss()
                    }
                )
                .environmentObject(router)
                .environmentObject(diaryViewModel)
            }
        }
    }
    
    // MARK: - Subviews
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.App.lightGray)
            
            TextField("Tìm kiếm món ăn...", text: $listFoodViewModel.searchText)
                .disableAutocorrection(true)
                .foregroundColor(.black)
            
            if !listFoodViewModel.searchText.isEmpty {
                Button { listFoodViewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.App.lightGray)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
    }
    
    private func foodRowCard(for food: Food) -> some View {
        HStack(spacing: 16) {
            if let urlString = food.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        ZStack {
                            Color.App.secondaryBackground
                            Text("🍲")
                        }
                    }
                }
                .frame(width: 55, height: 55)
                .cornerRadius(10)
                .clipped()
            } else {
                ZStack {
                    Color.App.secondaryBackground
                    Text("🍜").font(.title3)
                }
                .frame(width: 55, height: 55)
                .cornerRadius(10)
            }
            
            Text(food.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.App.lightGray)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(14)
    }
}

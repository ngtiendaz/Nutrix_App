//
//  ListFood.swift
//  Nutrix
//

import SwiftUI

struct ListFoodView: View {
    @StateObject private var listFoodViewModel = ListFoodViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel

    @State private var selectedFood: Food?

    var onSaveSuccess: (() -> Void)? = nil

    init(onSaveSuccess: (() -> Void)? = nil) {
        self.onSaveSuccess = onSaveSuccess

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.App.background)
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.App.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBarView
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    contentView
                }
            }
            .navigationTitle("Danh sách có sẵn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "333333"))
                            .frame(width: 32, height: 32)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .onAppear {
                listFoodViewModel.loadFoods()
            }
            .fullScreenCover(item: $selectedFood) { food in
                FoodAnalysisView(
                    food: food,
                    image: nil,
                    authService: FirebaseAuthService(),
                    isEditableNutrition: true,
                    mealDate: diaryViewModel.lastSelectedDate,
                    onSaveSuccess: {
                        selectedFood = nil
                        DispatchQueue.main.async {
                            onSaveSuccess?()
                        }
                    }
                )
                .environmentObject(router)
                .environmentObject(diaryViewModel)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if listFoodViewModel.isLoading {
            loadingView
        } else if let error = listFoodViewModel.errorMessage {
            errorView(message: error)
        } else if listFoodViewModel.filteredFoods.isEmpty {
            emptyView
        } else {
            foodListView
        }
    }

    private var foodListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(listFoodViewModel.searchText.isEmpty ? "Món ăn phổ biến" : "Kết quả tìm kiếm")
                        .font(.App.title3)
                        .foregroundColor(.black)

                    Spacer()

                    Text("\(listFoodViewModel.filteredFoods.count) món")
                        .font(.App.captionMedium)
                        .foregroundColor(Color.App.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.App.primaryLight)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 4)

                LazyVStack(spacing: 12) {
                    ForEach(listFoodViewModel.filteredFoods) { food in
                        Button {
                            selectedFood = food
                        } label: {
                            foodRowCard(for: food)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.App.primary)
            Text("Đang tải danh sách món ăn...")
                .font(.App.subheadlineRegular)
                .foregroundColor(Color.App.lightGray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(Color.App.lightGray)

            Text(message)
                .font(.App.subheadlineRegular)
                .foregroundColor(Color(hex: "555555"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Thử lại") {
                listFoodViewModel.loadFoods()
            }
            .font(.App.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.App.primary)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(Color.App.lightGray)

            Text("Không tìm thấy món ăn nào")
                .font(.App.bodyBold)
                .foregroundColor(.black)

            Text("Thử từ khóa khác hoặc kiểm tra kết nối mạng")
                .font(.App.captionMedium)
                .foregroundColor(Color.App.lightGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Subviews

    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.App.lightGray)
                .font(.App.body)

            TextField(
                "",
                text: $listFoodViewModel.searchText,
                prompt: Text("Tìm kiếm món ăn...").foregroundColor(Color.App.lightGray)
            )
            .disableAutocorrection(true)
            .foregroundColor(.black)
            .font(.App.bodyLarge)

            if !listFoodViewModel.searchText.isEmpty {
                Button {
                    listFoodViewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.App.lightGray)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private func foodRowCard(for food: Food) -> some View {
        HStack(spacing: 14) {
            foodThumbnail(for: food)

            VStack(alignment: .leading, spacing: 6) {
                Text(food.name)
                    .font(.App.headline)
                    .foregroundColor(Color(hex: "333333"))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(Int(food.servingSize)) \(food.servingUnit)")
                    .font(.App.captionMedium)
                    .foregroundColor(Color.App.lightGray)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.App.tiny)
                        .foregroundColor(Color.App.primary)

                    Text(String(format: "%.0f", food.calories))
                        .font(.App.caption)
                        .foregroundColor(Color.App.primary)

                    Text("Kcal")
                        .font(.App.tinyMedium)
                        .foregroundColor(Color.App.lightGray)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.App.lightGray.opacity(0.7))
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private func foodThumbnail(for food: Food) -> some View {
        Group {
            if food.imageUrl != nil {
                CachedImage(urlString: food.imageUrl, width: 64, height: 64, cornerRadius: 12)
            } else {
                ZStack {
                    Color.App.primaryLight
                    Text("🍽️")
                        .font(.title2)
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

//
//  FoodAnalysisView.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//

import SwiftUI

struct FoodAnalysisView: View {
    @StateObject var foodAnalysisViewModel: FoodAnalysisViewModel
    
    @Environment(\.dismiss) var dismiss
    @State private var scanAnimation = false
    @FocusState private var focusedField: Field?
    
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var loginViewModel: LoginViewModel
    
    init(image: UIImage, authService: FirebaseAuthService, onSaveSuccess: (() -> Void)? = nil) {
            _foodAnalysisViewModel = StateObject(wrappedValue: FoodAnalysisViewModel(image: image, authService: authService))
            self.onSaveSuccess = onSaveSuccess // Gán giá trị vào đây
        }
    
    var onSaveSuccess: (() -> Void)? = nil
    
    enum Field {
        case weight
        case quantity
    }
    
    var body: some View {
        ZStack { // Đổi alignment thành mặc định để Loading nằm chính giữa
                // 1. NỀN TRÀN TOÀN BỘ
                Color.App.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                        .ignoresSafeArea(.all, edges: .top)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            imageSection
                            
                            if foodAnalysisViewModel.isAnalyzing {
                                loadingView
                            }
                            else if let error = foodAnalysisViewModel.errorMessage {
                                errorView(message: error)
                            }
                            else if let food = foodAnalysisViewModel.analyzedFood {
                                foodContent(food: food)
                            }
                        }
                        .padding(.bottom, 160)
                    }
                }
                
                // Action Buttons nằm ở dưới cùng
                if !foodAnalysisViewModel.isAnalyzing && foodAnalysisViewModel.analyzedFood != nil {
                    actionButtons
                }

                // --- PHẦN THÊM VÀO: LOADING OVERLAY KHI LƯU ---
                if foodAnalysisViewModel.isSaving {
                    LoadingOverlay()
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .onTapGesture { focusedField = nil }
            .navigationBarHidden(true)
            .task {
                if foodAnalysisViewModel.analyzedFood == nil {
                    await foodAnalysisViewModel.startAnalysis()
                }
                if foodAnalysisViewModel.analyzedFood != nil {
                    foodAnalysisViewModel.updateAIAdvice()
                }
            }
            .onChange(of: foodAnalysisViewModel.quantity) { _ in
                foodAnalysisViewModel.updateAIAdvice()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") { focusedField = nil }
                }
            }
        .onTapGesture {
            focusedField = nil
        }
        .navigationBarHidden(true)
        .task {
            if foodAnalysisViewModel.analyzedFood == nil {
                    await foodAnalysisViewModel.startAnalysis()
                }
            if foodAnalysisViewModel.analyzedFood != nil {
                foodAnalysisViewModel.updateAIAdvice()
            }
        }
        .onChange(of: foodAnalysisViewModel.quantity) { _ in
            foodAnalysisViewModel.updateAIAdvice()
            
        }.ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") {
                        focusedField = nil
                    }
                }
            }
        
    }
    
    private var headerView: some View {
        ZStack {
            Text("Phân tích dinh dưỡng")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.App.primary)
                        .padding(8)
                        .background(Color.App.primaryLight.opacity(0.5))
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.top, 50) // Khoảng cách an toàn với tai thỏ
        .background(Color.App.background)
    }

    private var imageSection: some View {
        let imageShape = RoundedRectangle(cornerRadius: 30)

        return ZStack {
            imageShape
                .fill(Color.white)
                .frame(width: UIScreen.main.bounds.width - 40, height: 280)
                .shadow(color: .black.opacity(0.05), radius: 10)

            Image(uiImage: foodAnalysisViewModel.selectedImage)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width - 40, height: 280)
                .clipShape(imageShape)
                .overlay {
                    if foodAnalysisViewModel.isAnalyzing {
                        scanEffect
                            .clipShape(imageShape)
                    }
                }
        }
        .padding(.top, 10)
    }
    private var scanEffect: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.App.primary.opacity(0.5),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 60)
                .offset(y: scanAnimation ? geo.size.height : -60)
                .onAppear {
                    withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                        scanAnimation = true
                    }
                }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 15) {
            ProgressView().tint(Color.App.primary)
            Text("NutriX AI đang phân tích...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.App.lightGray)
        }
        .padding(.top, 40)
    }

    private func foodHeader(food: Food) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(food.name.uppercased())
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.black)
            ConfidenceBar(value: foodAnalysisViewModel.confidence)
            if !foodAnalysisViewModel.suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(foodAnalysisViewModel.suggestions, id: \.self) { suggestion in
                            Button {
                                Task {
                                    await foodAnalysisViewModel.reAnalyze(with: suggestion)
                                    // Sau khi reAnalyze xong, cần cập nhật advice mới
                                    foodAnalysisViewModel.updateAIAdvice()
                                }
                            } label: {
                                Text(suggestion)
                                    .font(.system(size: 13, weight: .medium))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 8)
                                    .background(Color.App.primaryLight)
                                    .foregroundColor(Color.App.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func nutritionCards(food: Food) -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(foodAnalysisViewModel.valueFor(food.calories)))")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(Color.App.primary)
                    Text("Tổng Kcal")
                        .font(.system(size: 14))
                        .foregroundColor(Color.App.lightGray)
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange.opacity(0.8))
            }
            Divider()
            HStack(spacing: 15) {
                NutrientMiniCard(title: "Carbs", value: foodAnalysisViewModel.valueFor(food.carbs), color: Color.blue)
                NutrientMiniCard(title: "Protein", value: foodAnalysisViewModel.valueFor(food.protein), color: Color.red)
                NutrientMiniCard(title: "Fat", value: foodAnalysisViewModel.valueFor(food.fats), color: Color.orange)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.03), radius: 10)
        .padding(.horizontal)
    }
    
    private var portionInputSection: some View {
        HStack(spacing: 15) {
            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Image(systemName: "scalemass") // Biểu tượng quả cân
                        .foregroundColor(.gray)
                    
                    TextField("", value: $foodAnalysisViewModel.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                }
                
                Text("Grams")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.gray)
                    
                    TextField("", value: $foodAnalysisViewModel.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .quantity)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(12).foregroundColor(.black)
                }
                
                Text("Số lượng")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 10)
        .padding(.horizontal)
        .onChange(of: foodAnalysisViewModel.weight) { _ in foodAnalysisViewModel.updateAIAdvice() }
    }

    @ViewBuilder
    private func smartRecommendation(food: Food) -> some View {
        if let advice = foodAnalysisViewModel.advice {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 12) {
                    Image(systemName: advice.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(advice.statusColor)
                        .padding(10)
                        .background(advice.statusColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Khuyến nghị từ NutriX")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(advice.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(advice.statusColor)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                Text(advice.message)
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.8))
                    .lineSpacing(6)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.03), radius: 10)
            .padding(.horizontal)
        }
    }
    
    private var actionButtons: some View {
        VStack {
            Spacer()
            HStack(spacing: 15) {
                Button { dismiss() } label: {
                    Text("Hủy")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.08), radius: 5)
                }
                
                Button {
                  
                    focusedField = nil
                    router.showLoading()
                    
                    foodAnalysisViewModel.saveFood {
                        // Logic sau khi lưu thành công
                        DispatchQueue.main.async {
                            router.hideLoading()
                            onSaveSuccess?()
                            router.showToast(message: "Đã lưu vào nhật ký!", type: .success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                dismiss()
                            }
                        }
                    }
                } label: {
                    Text("Lưu nhật ký")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .background(Color.App.primary)
                .cornerRadius(15)
                .disabled(foodAnalysisViewModel.isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                LinearGradient(colors: [Color.App.background.opacity(0), Color.App.background],
                               startPoint: .top, endPoint: .bottom)
                    .padding(.top, -20)
            )
        }
        .ignoresSafeArea(.keyboard)
    }
    @ViewBuilder
        private func errorView(message: String) -> some View {
            VStack(spacing: 25) {
                VStack(spacing: 15) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(Color.App.lightGray)
                        .padding(.top, 20)
                    
                    Text("Không nhận diện được")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(message)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
                
                Button {
                    dismiss() // Quay lại để chụp ảnh mới
                } label: {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Thử lại với ảnh khác")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.App.primary)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.App.primaryLight)
                    .cornerRadius(15)
                }
            }
            .padding(.top, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    @ViewBuilder
        private func foodContent(food: Food) -> some View {
            VStack(spacing: 20) {
                foodHeader(food: food)
                nutritionCards(food: food)
                portionInputSection
                mealTimeAndTypeSelector
                smartRecommendation(food: food)
            }
        }
    
    
    private var mealTimeAndTypeSelector: some View {
        HStack(spacing: 12) {
            
            // 👉 chọn giờ
            DatePicker(
                "",
                selection: $foodAnalysisViewModel.mealDate,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.05))
            .cornerRadius(12)
            
            // 👉 hiển thị mealType (AUTO)
            HStack(spacing: 6) {
                Image(systemName: getIconForMeal(foodAnalysisViewModel.selectedMealType))
                
                Text(foodAnalysisViewModel.selectedMealType.displayName)
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color.App.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.App.primaryLight.opacity(0.5))
            .clipShape(Capsule())
            
            Spacer()
        }
        .padding(.horizontal)
    }

    // Helper function để lấy icon phù hợp cho từng bữa
    private func getIconForMeal(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "sun.and.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .afternoon: return "leaf.fill"
        case .dinner: return "moon.fill"
        case .night: return "moon.stars.fill"
        case .snack: return "birthday.cake.fill"
        }
    }
}

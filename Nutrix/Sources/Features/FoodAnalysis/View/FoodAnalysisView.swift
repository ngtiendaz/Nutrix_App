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
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    
    init(image: UIImage, authService: FirebaseAuthService, onSaveSuccess: (() -> Void)? = nil) {
        _foodAnalysisViewModel = StateObject(wrappedValue: FoodAnalysisViewModel(image: image, authService: authService))
        self.onSaveSuccess = onSaveSuccess
    }
    
    var onSaveSuccess: (() -> Void)? = nil
    
    enum Field {
        case weight
        case quantity
    }
    
    var body: some View {
        ZStack {
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

            // LOADING OVERLAY KHI LƯU
            if foodAnalysisViewModel.isSaving {
                LoadingOverlay()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .onTapGesture {
            focusedField = nil
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Xong") { focusedField = nil }
            }
        }
        .task {
            // Chỉ gọi Start Analysis 1 lần duy nhất khi màn hình mới mở
            if foodAnalysisViewModel.analyzedFood == nil {
                await foodAnalysisViewModel.startAnalysis()
            }
            // Không cần gọi thủ công updateAIAdvice() ở đây nữa vì trong
            // ViewModel hàm getNutritionData đã tự gọi khi thành công.
        }
    }
    
    private var headerView: some View {
        ZStack {
            Text("Phân tích dinh dưỡng")
                .font(.App.headline)
                .foregroundColor(.black)
            
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.App.title2)
                        .foregroundColor(Color.App.primary)
                        .padding(8)
                        .background(Color.App.primaryLight.opacity(0.5))
                        .clipShape(Circle())
                }
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.top, 50)
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
                .font(.App.headline)
                .foregroundColor(Color.App.lightGray)
        }
        .padding(.top, 40)
    }

    private func foodHeader(food: Food) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(food.name.uppercased())
                .font(.App.title2)
                .foregroundColor(.black)
            ConfidenceBar(value: foodAnalysisViewModel.confidence)
            if !foodAnalysisViewModel.suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(foodAnalysisViewModel.suggestions, id: \.self) { suggestion in
                            Button {
                                Task {
                                    // Khi đổi món ăn khác thì ViewModel sẽ gọi lại getNutritionData
                                    // và lấy AI Advice mới.
                                    await foodAnalysisViewModel.reAnalyze(with: suggestion)
                                }
                            } label: {
                                Text(suggestion)
                                    .font(.App.subheadlineRegular)
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
                        .font(.App.large)
                        .foregroundColor(Color.App.primary)
                    Text("Tổng Kcal")
                        .font(.App.body)
                        .foregroundColor(Color.App.lightGray)
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.App.large)
                    .foregroundColor(.orange.opacity(0.8))
            }
            Divider()
            HStack(spacing: 15) {
                NutrientMiniCard(title: "Tinh bột", value: foodAnalysisViewModel.valueFor(food.carbs), color: Color.blue)
                NutrientMiniCard(title: "Chất đạm", value: foodAnalysisViewModel.valueFor(food.protein), color: Color.red)
                NutrientMiniCard(title: "Chất béo", value: foodAnalysisViewModel.valueFor(food.fats), color: Color.orange)
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
                    Image(systemName: "scalemass")
                        .foregroundColor(.gray)
                    
                    TextField("", value: $foodAnalysisViewModel.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .font(.App.title2)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                }
                
                Text("Grams")
                    .font(.App.captionMedium)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.gray)
                    
                    TextField("", value: $foodAnalysisViewModel.quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .quantity)
                        .font(.App.title2)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                }
                
                Text("Số lượng")
                    .font(.App.captionMedium)
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 10)
        .padding(.horizontal)
        // ĐÃ XÓA .onChange ở đây để không load lại AI
    }

    @ViewBuilder
    private func smartRecommendation(food: Food) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            if foodAnalysisViewModel.isAdviceLoading {
                HStack(spacing: 12) {
                    ProgressView().tint(Color.App.primary)
                    Text("NutriX AI đang phân tích dữ liệu...")
                        .font(.App.subheadlineRegular)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity, alignment: .center)
                
            } else if let advice = foodAnalysisViewModel.advice {
                HStack(spacing: 12) {
                    Image(systemName: advice.iconName)
                        .font(.App.title2)
                        .foregroundColor(advice.statusColor)
                        .padding(10)
                        .background(advice.statusColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nutrix AI")
                            .font(.App.captionMedium)
                            .foregroundColor(.gray)
                            .kerning(0.5)
                        Text(advice.title)
                            .font(.App.bodyBold)
                            .foregroundColor(advice.statusColor)
                    }
                    Spacer()
                }
                
                Divider()
                
                if !foodAnalysisViewModel.streamingTimingAnalysis.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(.blue)
                                .font(.subheadline)
                            Text("Thời gian:")
                                .font(.App.bodyBold)
                                .foregroundColor(.black)
                        }
                        Text(foodAnalysisViewModel.streamingTimingAnalysis)
                            .font(.App.subheadlineRegular)
                            .foregroundColor(.black.opacity(0.75))
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 4)
                    .transition(.opacity)
                }
                
                if !foodAnalysisViewModel.streamingMacroBalance.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .foregroundColor(.purple)
                                .font(.subheadline)
                            Text("Dinh dưỡng:")
                                .font(.App.bodyBold)
                                .foregroundColor(.black)
                        }
                        Text(foodAnalysisViewModel.streamingMacroBalance)
                            .font(.App.subheadlineRegular)
                            .foregroundColor(.black.opacity(0.75))
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 4)
                    .transition(.opacity)
                }
                
                if !foodAnalysisViewModel.streamingPortionRecommendation.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(.orange)
                                .font(.subheadline)
                            Text("Phân bổ định lượng:")
                                .font(.App.bodyBold)
                                .foregroundColor(.black)
                        }
                        Text(foodAnalysisViewModel.streamingPortionRecommendation)
                            .font(.App.subheadlineRegular)
                            .foregroundColor(.black.opacity(0.75))
                            .lineSpacing(4)
                    }
                    .padding(.vertical, 4)
                    .transition(.opacity)
                }
                
                if !foodAnalysisViewModel.streamingActionTip.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.message.fill")
                            .foregroundColor(Color.App.primary)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gợi ý:")
                                .font(.App.bodyBold)
                                .foregroundColor(Color.App.primary)
                            Text(foodAnalysisViewModel.streamingActionTip)
                                .font(.App.subheadlineRegular)
                                .foregroundColor(.black.opacity(0.85))
                                .lineSpacing(4)
                        }
                    }
                    .padding(12)
                    .background(Color.App.primaryLight.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.top, 5)
                    .transition(.opacity)
                }
                
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "brain.headset")
                        .foregroundColor(.gray)
                    Text("Vui lòng đợi cấu trúc dữ liệu hoặc kiểm tra lại kết nối mạng.")
                        .font(.App.subheadlineRegular)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.03), radius: 10)
        .padding(.horizontal)
        .animation(.linear(duration: 0.15), value: foodAnalysisViewModel.isAdviceLoading)
    }

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 25) {
            VStack(spacing: 15) {
                Image(systemName: "camera.viewfinder")
                    .font(.App.huge)
                    .foregroundColor(Color.App.lightGray)
                    .padding(.top, 20)
                
                Text("Không nhận diện được")
                    .font(.App.title2)
                    .foregroundColor(.black)
                
                Text(message)
                    .font(.App.headline)
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
                .font(.App.bodyBold)
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
            
            HStack(spacing: 6) {
                Image(systemName: getIconForMeal(foodAnalysisViewModel.selectedMealType))
                Text(foodAnalysisViewModel.selectedMealType.displayName)
            }
            .font(.App.bodyLarge)
            .foregroundColor(Color.App.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.App.primaryLight.opacity(0.5))
            .clipShape(Capsule())
            
            Spacer()
        }
        .padding(.horizontal)
    }

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

    private var actionButtons: some View {
        VStack {
            Spacer()
            HStack(spacing: 15) {
                Button { dismiss() } label: {
                    Text("Hủy")
                        .font(.App.bodyBold)
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
                        .font(.App.bodyBold)
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
}

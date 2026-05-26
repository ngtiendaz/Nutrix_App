//
//  FoodAnalysisView.swift
//  Nutrix
//

import SwiftUI

struct FoodAnalysisView: View {
    @StateObject var foodAnalysisViewModel: FoodAnalysisViewModel
    
    @Environment(\.dismiss) var dismiss
    @State private var scanAnimation = false
    @FocusState private var focusedField: Field?
    @State private var keyboardHeight: CGFloat = 0
    
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    
    // 👉 Thay đổi Init để hỗ trợ cả Food có sẵn, Ảnh, và Cờ chỉnh sửa
    init(food: Food? = nil, image: UIImage? = nil, authService: FirebaseAuthService, isEditableNutrition: Bool = false, onSaveSuccess: (() -> Void)? = nil) {
        _foodAnalysisViewModel = StateObject(wrappedValue: FoodAnalysisViewModel(food: food, image: image, authService: authService, isEditableNutrition: isEditableNutrition))
        self.onSaveSuccess = onSaveSuccess
    }
    
    var onSaveSuccess: (() -> Void)? = nil
    
    // Thêm các trường phục vụ focus bàn phím
    enum Field {
        case weight, quantity, calories, protein, carbs, fats
    }
    
    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(showsIndicators: false) {
                    ScrollViewReader { proxy in
                        VStack(spacing: 20) {
                            imageSection
                            
                            if foodAnalysisViewModel.isAnalyzing {
                                loadingView
                            }
                            else if let error = foodAnalysisViewModel.errorMessage {
                                errorView(message: error)
                            }
                            else if let food = foodAnalysisViewModel.analyzedFood {
                                VStack(spacing: 20) {
                                    foodHeader(food: food)
                                    nutritionCards
                                        .id("nutritionCards")
                                    portionInputSection
                                        .id("inputs")

                                    mealTimeAndTypeSelector
                                    smartRecommendation(food: food)
                                }
                            }
                        }
                        .padding(.bottom, scrollBottomPadding)
                        .onChange(of: focusedField) { field in
                            scrollToFocusedField(field, proxy: proxy)
                        }
                        .onChange(of: keyboardHeight) { _ in
                            scrollToFocusedField(focusedField, proxy: proxy)
                        }
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        hideKeyboard()
                    }
                )
            }
            
            if !foodAnalysisViewModel.isAnalyzing && foodAnalysisViewModel.analyzedFood != nil {
                actionButtons
            }

            if foodAnalysisViewModel.isSaving {
                LoadingOverlay()
                    .transition(.opacity)
                    .zIndex(2)
            }

            if router.toast != nil {
                AppNotificationView(data: router.toast)
                    .zIndex(999)
            }
        }
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
            withAnimation(.easeOut(duration: duration)) {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
            withAnimation(.easeOut(duration: duration)) {
                keyboardHeight = 0
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Xong") { hideKeyboard() }
            }
        }
        .task {
            // 👉 KIỂM TRA LUỒNG
            if foodAnalysisViewModel.selectedImage != nil && foodAnalysisViewModel.analyzedFood == nil {
                // Có ảnh mới chưa phân tích -> Chạy phân tích AI Vision
                await foodAnalysisViewModel.startAnalysis()
            } else if foodAnalysisViewModel.analyzedFood != nil && foodAnalysisViewModel.advice == nil {
                // Đã có Food sẵn từ danh sách -> Bỏ qua Vision, chỉ lấy lời khuyên dinh dưỡng
                foodAnalysisViewModel.updateAIAdvice()
            }
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
        .padding(.vertical, 12)
        .background(Color.App.background)
        .contentShape(Rectangle())
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func hideKeyboard() {
        focusedField = nil
    }

    private var imageSection: some View {
        let imageShape = RoundedRectangle(cornerRadius: 30)
        let imageWidth = UIScreen.main.bounds.width - 40
        let imageHeight: CGFloat = 280

        return ZStack {
            imageShape
                .fill(Color.white)
                .frame(width: imageWidth, height: imageHeight)
                .shadow(color: .black.opacity(0.05), radius: 10)

            if let uiImage = foodAnalysisViewModel.selectedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageWidth, height: imageHeight)
                    .clipShape(imageShape)
            } else if let imageUrl = foodAnalysisViewModel.analyzedFood?.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        ZStack {
                            Color.App.secondaryBackground
                            Text("🍲").font(.system(size: 60))
                        }
                    }
                }
                .frame(width: imageWidth, height: imageHeight)
                .clipShape(imageShape)
            }
            
            // Hiệu ứng scan chỉ chạy lúc đang phân tích Vision
            if foodAnalysisViewModel.isAnalyzing {
                scanEffect
                    .clipShape(imageShape)
            }
        }
        .padding(.top, 10)
    }
    
    private var scanEffect: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.App.primary.opacity(0.5), .clear],
                        startPoint: .top, endPoint: .bottom
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

    private var scrollBottomPadding: CGFloat {
        keyboardHeight > 0 ? keyboardHeight + 24 : 160
    }

    private func scrollToFocusedField(_ field: Field?, proxy: ScrollViewProxy) {
        guard let field else { return }
        let fieldId = "field_\(fieldIdSuffix(field))"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                proxy.scrollTo(fieldId, anchor: .center)
            }
        }
    }

    private func fieldIdSuffix(_ field: Field) -> String {
        switch field {
        case .weight: return "weight"
        case .quantity: return "quantity"
        case .calories: return "calories"
        case .protein: return "protein"
        case .carbs: return "carbs"
        case .fats: return "fats"
        }
    }

    private func foodHeader(food: Food) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(food.name.uppercased())
                .font(.App.title2)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Chỉ hiển thị thanh Confidence nếu có gợi ý phân tích từ Vision
            if foodAnalysisViewModel.confidence > 0 {
                ConfidenceBar(value: foodAnalysisViewModel.confidence)
            }
            
            if !foodAnalysisViewModel.suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(foodAnalysisViewModel.suggestions, id: \.self) { suggestion in
                            Button {
                                Task {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    private var nutritionCards: some View {
        let isEditable = foodAnalysisViewModel.isEditableNutrition

        return VStack(spacing: 20) {
            if isEditable {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.App.caption)
                        .foregroundColor(Color.App.primary)
                    Text("Chạm các ô bên dưới để chỉnh sửa dinh dưỡng")
                        .font(.App.captionMedium)
                        .foregroundColor(Color.App.lightGray)
                    Spacer(minLength: 0)
                }
            }

            HStack {
                VStack(alignment: .leading) {
                    if isEditable {
                        TextField("", text: $foodAnalysisViewModel.editableCalories.doubleToString())
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .calories)
                            .font(.App.large)
                            .foregroundColor(Color.App.primary)
                            .frame(minWidth: 80)
                            .editableFieldStyle(field: .calories, focusedField: focusedField)
                            .id("field_calories")
                    } else {
                        Text("\(Int(foodAnalysisViewModel.displayCalories))")
                            .font(.App.large)
                            .foregroundColor(Color.App.primary)
                    }
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
                if isEditable {
                    editableNutrientMiniCard(
                        title: "Tinh bột",
                        value: $foodAnalysisViewModel.editableCarbs,
                        color: .blue,
                        field: .carbs
                    )
                    editableNutrientMiniCard(
                        title: "Chất đạm",
                        value: $foodAnalysisViewModel.editableProtein,
                        color: .red,
                        field: .protein
                    )
                    editableNutrientMiniCard(
                        title: "Chất béo",
                        value: $foodAnalysisViewModel.editableFats,
                        color: .orange,
                        field: .fats
                    )
                } else {
                    NutrientMiniCard(title: "Tinh bột", value: foodAnalysisViewModel.displayCarbs, color: .blue)
                    NutrientMiniCard(title: "Chất đạm", value: foodAnalysisViewModel.displayProtein, color: .red)
                    NutrientMiniCard(title: "Chất béo", value: foodAnalysisViewModel.displayFats, color: .orange)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.03), radius: 10)
        .padding(.horizontal)
    }

    private func editableNutrientMiniCard(
        title: String,
        value: Binding<Double>,
        color: Color,
        field: Field
    ) -> some View {
        VStack(spacing: 8) {
            TextField("", text: value.doubleToString())
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: field)
                .font(.App.bodyBold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .editableFieldStyle(field: field, focusedField: focusedField)
                .id("field_\(fieldIdSuffix(field))")
            ZStack(alignment: .leading) {
                Capsule().frame(height: 4).foregroundColor(color.opacity(0.1))
                Capsule().frame(width: 30, height: 4).foregroundColor(color)
            }
            Text(title)
                .font(.App.captionMedium)
                .foregroundColor(Color.App.lightGray)
        }
        .frame(maxWidth: .infinity)
    }

    private var portionInputSection: some View {
        HStack(spacing: 15) {
            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundColor(.gray)

                    TextField("", text: $foodAnalysisViewModel.weight.doubleToString())
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .font(.App.title2)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                        .id("field_weight")
                }
                Text("Grams")
                    .font(.App.captionMedium)
                    .foregroundColor(.gray)
            }

            VStack(alignment: .center, spacing: 8) {
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.gray)

                    TextField("", text: $foodAnalysisViewModel.quantity.doubleToString())
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .quantity)
                        .font(.App.title2)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                        .id("field_quantity")
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
                dismiss() // Quay lại để thử cách khác
            } label: {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("Trở lại")
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let validationError = foodAnalysisViewModel.validateInputs() {
                            router.showToast(message: validationError, type: .error)
                            return
                        }
                        foodAnalysisViewModel.saveFood {
                            DispatchQueue.main.async {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                onSaveSuccess?()
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
            .padding(.bottom, keyboardHeight > 0 ? 12 : 20)
            .background(
                LinearGradient(colors: [Color.App.background.opacity(0), Color.App.background],
                               startPoint: .top, endPoint: .bottom)
                    .padding(.top, -20)
            )
        }
        .padding(.bottom, keyboardHeight)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .allowsHitTesting(keyboardHeight == 0)
        .opacity(keyboardHeight > 0 ? 0 : 1)
    }
}

// MARK: - Editable field style (danh sách có sẵn)

private struct EditableFieldModifier: ViewModifier {
    let field: FoodAnalysisView.Field
    let focusedField: FoodAnalysisView.Field?

    func body(content: Content) -> some View {
        let isFocused = focusedField == field
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.App.primaryLight.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isFocused ? Color.App.primary : Color.App.primary.opacity(0.4),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
    }
}

private extension View {
    func editableFieldStyle(
        field: FoodAnalysisView.Field,
        focusedField: FoodAnalysisView.Field?
    ) -> some View {
        modifier(EditableFieldModifier(field: field, focusedField: focusedField))
    }
}

private extension Binding where Value == Double {
    func doubleToString() -> Binding<String> {
        Binding<String>(
            get: {
                let formatted = String(format: "%.1f", self.wrappedValue)
                if formatted.hasSuffix(".0") {
                    return String(formatted.dropLast(2))
                }
                return formatted
            },
            set: { newValue in
                let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
                if let val = Double(cleaned) {
                    self.wrappedValue = val
                } else if newValue.isEmpty {
                    self.wrappedValue = 0.0
                }
            }
        )
    }
}

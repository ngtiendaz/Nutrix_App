import SwiftUI

struct FoodDetailView: View {
    @StateObject var foodDetailViewModel: FoodDetailViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    @FocusState private var focusedField: FoodDetailViewModel.Field?
    @State private var showDeleteConfirmation = false
    
    init(food: Food, mealDate: Date) {
        _foodDetailViewModel = StateObject(wrappedValue: FoodDetailViewModel(food: food, mealDate: mealDate))
    }
    
    var body: some View {
        ZStack {
            // 1. Nền chính
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            imageSection
                            
                            VStack(alignment: .leading, spacing: 20) {
                                // Tên món ăn và ngày giờ sử dụng
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(foodDetailViewModel.originalFood.name.uppercased())
                                        .font(.system(size: 24, weight: .black))
                                        .foregroundColor(.black)
                                    
                                    // SECTION MỚI: Hiển thị ngày giờ dùng món
                                    timeSection
                                }
                                .padding(.horizontal)
                                
                                nutritionCards
                                
                                portionInputSection
                                    .id("inputs")
                                
                                deleteButton
                                
                                Spacer().frame(height: focusedField != nil ? 150 : 10)
                            }
                        }
                        .padding(.bottom, 70)
                    }
                    .onChange(of: focusedField) { newValue in
                        if newValue != nil {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                proxy.scrollTo("inputs", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // 2. Loading Overlay
            if foodDetailViewModel.isLoading {
                LoadingOverlay()
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .navigationBarHidden(true)
        .onTapGesture { focusedField = nil }
        .ignoresSafeArea(.all, edges: .top)
        .onChange(of: foodDetailViewModel.shouldDismiss) { newValue in
            if newValue {
                if foodDetailViewModel.lastAction == .delete {
                    router.showToast(message: "Đã xóa món ăn khỏi nhật ký", type: .success)
                } else {
                    router.showToast(message: "Cập nhật thành công", type: .success)
                }
                diaryViewModel.refreshData()
                dismiss()
            }
        }
        .alert("Xác nhận xóa", isPresented: $showDeleteConfirmation) {
            Button("Hủy", role: .cancel) {}
            Button("Xóa", role: .destructive) { foodDetailViewModel.deleteFood() }
        } message: {
            Text("Bạn có chắc chắn muốn xóa món này khỏi nhật ký không?")
        }
    }
}

// MARK: - Subviews
extension FoodDetailView {
    
    // View con hiển thị thời gian ăn uống
    private var timeSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: 13))
                .foregroundColor(Color.App.primary.opacity(0.8))
            
            Text(formattedDateString)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
    }
    
    // Helper format ngày giờ bằng Tiếng Việt
    private var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        // Định dạng xuất ra: "15:30 - Thứ Hai, 15/04/2026"
        formatter.dateFormat = "HH:mm - EEEE, dd/MM/yyyy"
        return formatter.string(from: foodDetailViewModel.originalFood.createdAt)
    }

    private var headerView: some View {
        HStack {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.App.primary)
                        .padding(10)
                        .background(Color.App.primaryLight.opacity(0.5))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .frame(width: 80)
            
            Spacer()
            
            Text("Chi tiết món ăn")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
            
            Spacer()
            
            HStack {
                Spacer()
                if foodDetailViewModel.hasChanges {
                    Button {
                        focusedField = nil
                        foodDetailViewModel.updateFood()
                    } label: {
                        Text("Lưu")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.App.primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(width: 80)
        }
        .padding(.horizontal)
        .padding(.top, safeAreaTop)
        .padding(.bottom, 12)
        .background(Color.App.background)
    }

    private var safeAreaTop: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.top ?? 44
    }

    private var imageSection: some View {
        AsyncImage(url: URL(string: foodDetailViewModel.originalFood.imageUrl ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.gray.opacity(0.1).overlay(ProgressView())
        }
        .frame(width: UIScreen.main.bounds.width - 32, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }

    private var nutritionCards: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(foodDetailViewModel.displayCalories)")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(Color.App.primary)
                    Text("Tổng Calo (Kcal)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.orange.opacity(0.8))
            }
            Divider()
            HStack(spacing: 12) {
                NutrientMiniCard(title: "Carbs", value: foodDetailViewModel.displayCarbs, color: .blue)
                NutrientMiniCard(title: "Protein", value: foodDetailViewModel.displayProtein, color: .red)
                NutrientMiniCard(title: "Fat", value: foodDetailViewModel.displayFats, color: .orange)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .padding(.horizontal, 16)
    }

    private var portionInputSection: some View {
        HStack(spacing: 16) {
            inputField(title: "Khối lượng (g)", value: $foodDetailViewModel.currentWeight, icon: "scalemass", field: .weight)
            inputField(title: "Số lượng", value: $foodDetailViewModel.currentQuantity, icon: "number", field: .quantity)
        }
        .padding(.horizontal, 16)
    }

    private func inputField(title: String, value: Binding<Double>, icon: String, field: FoodDetailViewModel.Field) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                TextField("", value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: field)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .background(Color.black.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == field ? Color.App.primary.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: focusedField)
    }

    private var deleteButton: some View {
        Button { showDeleteConfirmation = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "trash.fill")
                Text("Xóa khỏi nhật ký")
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red.opacity(0.08))
            .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

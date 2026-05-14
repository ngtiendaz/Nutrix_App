import SwiftUI

struct FoodDetailView: View {
    @StateObject var foodDetailViewModel: FoodDetailViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: FoodDetailViewModel.Field?
    @State private var showDeleteConfirmation = false
    
    // Alias để gọi cho gọn trong View
    enum Field { case weight, quantity }

    init(food: Food, mealDate: Date) {
        _foodDetailViewModel = StateObject(wrappedValue: FoodDetailViewModel(food: food, mealDate: mealDate))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        imageSection
                        
                        VStack(alignment: .leading, spacing: 20) {
                            Text(foodDetailViewModel.originalFood.name.uppercased())
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            
                            nutritionCards
                            portionInputSection
                            deleteButton
                        }
                    }
                    .padding(.bottom, 70)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            
            if foodDetailViewModel.isLoading {
                Color.black.opacity(0.15).ignoresSafeArea()
                ProgressView().tint(Color.App.primary)
            }
        }
        .navigationBarHidden(true)
        .onTapGesture { hideKeyboard() }
        .onChange(of: foodDetailViewModel.shouldDismiss) { _ in dismiss() }
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
    private var headerView: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.App.primary)
                    .padding(10)
                    .background(Color.App.primaryLight.opacity(0.5))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Chi tiết món ăn").font(.system(size: 18, weight: .bold)).foregroundColor(.black)
            Spacer()
            
            if foodDetailViewModel.hasChanges {
                Button { foodDetailViewModel.updateFood() } label: {
                    Text("Lưu").font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(Color.App.primary).clipShape(Capsule())
                }
            } else {
                Color.clear.frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal).padding(.top, 50).padding(.bottom, 15)
        .background(Color.App.background)
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
                        .font(.system(size: 38, weight: .bold)).foregroundColor(Color.App.primary)
                    Text("Tổng Calo (Kcal)").font(.system(size: 14, weight: .medium)).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "flame.fill").font(.system(size: 36)).foregroundColor(.orange.opacity(0.8))
            }
            Divider()
            HStack(spacing: 12) {
                NutrientMiniCard(title: "Carbs", value: foodDetailViewModel.displayCarbs, color: .blue)
                NutrientMiniCard(title: "Protein", value: foodDetailViewModel.displayProtein, color: .red)
                NutrientMiniCard(title: "Fat", value: foodDetailViewModel.displayFats, color: .orange)
            }
        }
        .padding(20).background(Color.white).cornerRadius(24).padding(.horizontal, 16)
    }

    private var portionInputSection: some View {
        HStack(spacing: 16) {
            inputField(title: "Khối lượng (g)", value: $foodDetailViewModel.currentWeight, icon: "scalemass")
            inputField(title: "Số lượng", value: $foodDetailViewModel.currentQuantity, icon: "number")
        }
        .padding(.horizontal, 16)
    }

    private func inputField(title: String, value: Binding<Double>, icon: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(.gray)
                TextField("", value: value, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .bold)).foregroundColor(.black)
            }
            .padding(14).background(Color.black.opacity(0.04)).cornerRadius(12)
            Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private var deleteButton: some View {
        Button { showDeleteConfirmation = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "trash.fill")
                Text("Xóa khỏi nhật ký")
            }
            .font(.system(size: 16, weight: .bold)).foregroundColor(.red)
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(Color.red.opacity(0.08)).cornerRadius(16)
        }
        .padding(.horizontal, 16).padding(.top, 10)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

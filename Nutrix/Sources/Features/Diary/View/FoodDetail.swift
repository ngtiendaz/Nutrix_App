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
                                VStack(alignment: .leading, spacing: 6) {
                                        Text(foodDetailViewModel.originalFood.name.uppercased())
                                            .font(.App.header)
                                            .foregroundColor(.black)
                                            .lineLimit(2) // Tránh việc tên quá dài làm vỡ layout
                                        
                                        HStack(spacing: 6) {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.App.captionMedium)
                                                .foregroundColor(.gray)
                                            
                                            // Sử dụng cú pháp định dạng Date mới của iOS 15+ tự động theo vùng/quốc gia
                                            Text(foodDetailViewModel.mealDate.formatted(date: .abbreviated, time: .shortened))
                                                .font(.App.body)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.horizontal, 16) // Đưa padding ra ngoài để cả cụm chữ thẳng hàng nhau
                                
                                nutritionCards
                                
                                portionInputSection
                                    .id("inputs")
                                
                                deleteButton
                                
                                
                                Spacer().frame(height: focusedField != nil ? 30 : 10)
                            }
                        }
                        .padding(.bottom, 70) // Giảm padding thừa khi đã có xử lý phím
                    }
                    .onChange(of: focusedField) { newValue in
                        if newValue != nil {
                            
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                // Anchor là .bottom giúp đẩy nội dung lên sát trên bàn phím
                                proxy.scrollTo("inputs", anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // 2. Loading Overlay (Hiển thị khi ViewModel đang xử lý)
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
                        dismiss() // Đóng màn hình chi tiết
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
    private var headerView: some View {
        HStack {
            // Nút bên trái - Cố định frame 80px
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.App.bodyBold)
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
                .font(.App.bodyBold)
                .foregroundColor(.black)
                .lineLimit(1)
            
            Spacer()
            
            // Nút bên phải - Cố định frame 80px để cân bằng với bên trái
            HStack {
                Spacer()
                if foodDetailViewModel.hasChanges {
                    Button {
                        focusedField = nil // Ẩn phím trước khi lưu
                        foodDetailViewModel.updateFood()
                    } label: {
                        Text("Lưu")
                            .font(.App.sectionHeader)
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
        .padding(.top, safeAreaTop) // Sử dụng biến helper hoặc chuẩn hóa padding
        .padding(.bottom, 12)
        .background(Color.App.background)
    }

    private var safeAreaTop: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.top ?? 44
    }

    private var imageSection: some View {
        CachedImage(
                urlString: foodDetailViewModel.originalFood.imageUrl,
                width: UIScreen.main.bounds.width - 32, // Tự động lấy toàn bộ chiều rộng màn hình (trừ đi padding 2 bên)
                height: 250 // Tăng chiều cao lên 220 để ảnh to và rõ nét hơn
            )
            .aspectRatio(contentMode: .fill) // Ép ảnh lấp đầy khung hình mà không bị mất tỉ lệ
            .frame(width: UIScreen.main.bounds.width - 32, height: 250) // Đảm bảo khung hình cố định đúng kích thước
            .cornerRadius(16) // Bo góc nhẹ cho hài hòa với giao diện hiện tại
            .clipped() // Cắt bỏ các phần ảnh thừa bị tràn ra ngoài khung bo
            .padding(.horizontal, 16)
    }

    private var nutritionCards: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(foodDetailViewModel.displayCalories)")
                        .font(.App.large)
                        .foregroundColor(Color.App.primary)
                    Text("Tổng Calo (Kcal)")
                        .font(.App.body)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.App.display)
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
                        .font(.App.body)
                        .foregroundColor(.gray)
                    TextField("", value: value, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: field)
                        .font(.App.title)
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
                    .font(.App.captionMedium)
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
            .font(.App.bodyBold)
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

import SwiftUI

struct HistoryFoodListView: View {
    let date: Date
    @StateObject private var viewModel = HistoryFoodListViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var diaryViewModel: DiaryViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Thanh kéo & Nút đóng
            VStack {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                HStack {
                    Text("Danh sách món ăn")
                        .font(.App.title3)
                        .foregroundColor(.black)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.App.lightGray)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .background(Color.white)
            
            // Thanh tìm kiếm
            searchBarView
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.white)
            
            // Nội dung chính
            ZStack {
                Color.App.background.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Đang tải dữ liệu...")
                        .tint(Color.App.primary)
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red).font(.App.body)
                } else if viewModel.filteredFoods.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(Color.App.lightGray)
                        Text(viewModel.searchText.isEmpty ? "Không có dữ liệu cho ngày này" : "Không tìm thấy món ăn nào")
                            .font(.App.bodyBold)
                            .foregroundColor(.black)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredFoods) { food in
                                Button {
                                    dismiss()
                                    // Chờ sheet đóng xong thì chuyển màn hình
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        router.push(.foodDetail(food, diaryViewModel))
                                    }
                                } label: {
                                    FoodItem(food: food)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadFoods(for: date)
        }
    }
    
    private var searchBarView: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.App.lightGray)
                .font(.App.body)
            
            TextField(
                "",
                text: $viewModel.searchText,
                prompt: Text("Tìm kiếm món ăn...").foregroundColor(Color.App.lightGray)
            )
            .disableAutocorrection(true)
            .foregroundColor(.black)
            .font(.App.bodyLarge)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.App.lightGray)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.App.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

import SwiftUI

struct AddActivitySheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var router: AppRouter
    @ObservedObject var viewModel: ActivityViewModel
    let userId: String
    let date: Date
    @State private var isExpanded = false
    @State private var searchText = ""
    @State private var selectedActivity: Activity?
    @State private var duration: Int = 30
    
    var filteredActivities: [Activity] {
        if searchText.isEmpty {
            return viewModel.activityDataset
        } else {
            return viewModel.activityDataset.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    init(viewModel: ActivityViewModel, userId: String, date: Date) {
        self.viewModel = viewModel
        self.userId = userId
        self.date = date
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.App.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. Thanh tìm kiếm
                    searchBar
                        .padding(.top, 15)
                        .padding(.bottom, 20)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            
                            // 2. Section: Chọn loại hoạt động
                            VStack(alignment: .leading, spacing: 16) {
                                Text(searchText.isEmpty ? "Hoạt động phổ biến" : "Kết quả tìm kiếm")
                                    .font(.App.title3)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 4)
                                
                                if filteredActivities.isEmpty {
                                    emptySearchView
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 14) {
                                            ForEach(filteredActivities) { activity in
                                                ActivityTypeItem(
                                                    title: activity.name,
                                                    icon: activity.icon,
                                                    isSelected: selectedActivity?.id == activity.id
                                                )
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                        // Cơ chế Toggle: Bấm lại mục cũ thì hủy chọn hoàn toàn
                                                        if selectedActivity?.id == activity.id {
                                                            selectedActivity = nil
                                                        } else {
                                                            selectedActivity = activity
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                            
                            // 3. Section: Tùy chỉnh thời gian
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Tùy chỉnh thời gian")
                                    .font(.App.title3)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 4)
                                
                                timeAdjustmentCard
                            }
                            
                            // 4. Section: Hiển thị Calo dự kiến & Khối Chú thích Công thức hệ thống
                            if selectedActivity != nil {
                                VStack(alignment: .leading, spacing: 14) {
                                    estimatedCaloriesView
                                    
                                    formulaExplanationCard
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 120)
                    }
                }
                
                // Nút Lưu cố định dưới đáy với dải màu mờ nền
                VStack {
                    Spacer()
                    saveButton
                        .background(
                            LinearGradient(colors: [Color.App.background.opacity(0), Color.App.background], startPoint: .top, endPoint: .bottom)
                                .frame(height: 120)
                        )
                }
                .ignoresSafeArea()
            }
            .navigationTitle("Thêm hoạt động")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            // Đảm bảo đồng bộ và tải lại chỉ số cơ thể sạch ngay từ đầu chu kỳ mở bạt sheet
            viewModel.getUserLogs(userId: userId, date: date)
        }
    }
}

// MARK: - Components mở rộng Giao Diện
extension AddActivitySheet {
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.App.title)
            
            TextField("", text: $searchText, prompt: Text("Tìm kiếm hoạt động...").foregroundColor(.gray))
                .foregroundColor(.black)
                .font(.App.bodyLarge)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    private var timeAdjustmentCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Tổng thời gian")
                    .font(.App.body)
                    .foregroundColor(.gray)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(duration)")
                        .font(.App.display)
                        .foregroundColor(Color.App.primary)
                    Text("phút")
                        .font(.App.bodyBold)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                Button(action: { if duration > 5 { duration -= 5 } }) {
                    Image(systemName: "minus")
                        .font(.App.title)
                        .frame(width: 44, height: 44)
                        .background(Color.App.secondaryBackground)
                        .foregroundColor(.black)
                }
                
                Divider().frame(height: 30)
                
                Button(action: { duration += 5 }) {
                    Image(systemName: "plus")
                        .font(.App.title)
                        .frame(width: 44, height: 44)
                        .background(Color.App.secondaryBackground)
                        .foregroundColor(.black)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    // TỐI ƯU MỚI: Hiển thị minh bạch Kcal, hệ số MET, và số liệu chiều cao cân nặng thực tế
    private var estimatedCaloriesView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.App.title)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Năng lượng tiêu thụ")
                        .font(.App.captionMedium)
                        .foregroundColor(.gray)
                    
                    let calories = (selectedActivity?.metValue ?? 5.0) * Double(duration)
                    Text("~\(Int(calories)) Kcal")
                        .font(.App.title2)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Text("Dự tính")
                    .font(.App.small)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.App.secondaryBackground)
                    .cornerRadius(6)
            }
            
            Divider().background(Color.black.opacity(0.04))
            
            // Bộ ba khối kén màu sắc thể hiện các mốc chỉ số áp dụng
            VStack(alignment: .leading, spacing: 8) {
                Text("Chỉ số áp dụng tính toán:")
                    .font(.App.caption)
                    .foregroundColor(.black.opacity(0.7))
                
                HStack(spacing: 8) {
                    // Thẻ MET của bài tập
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.heart.fill").font(.App.tinyMedium)
                        Text("MET: \(String(format: "%.1f", selectedActivity?.metValue ?? 5.0))")
                    }
                    .font(.App.small)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.orange.opacity(0.08)).foregroundColor(.orange).cornerRadius(8)
                    
                    // Thẻ Cân nặng từ ViewModel
                    HStack(spacing: 4) {
                        Image(systemName: "scalemass.fill").font(.App.tinyMedium)
                        Text("Nặng: \(viewModel.userWeight > 0 ? "\(Int(viewModel.userWeight)) kg" : "-- kg")")
                    }
                    .font(.App.small)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.blue.opacity(0.08)).foregroundColor(.blue).cornerRadius(8)
                    
                    // Thẻ Chiều cao từ ViewModel
                    HStack(spacing: 4) {
                        Image(systemName: "figure.stand").font(.App.tinyMedium)
                        Text("Cao: \(viewModel.userHeight > 0 ? "\(Int(viewModel.userHeight)) cm" : "-- cm")")
                    }
                    .font(.App.small)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.purple.opacity(0.08)).foregroundColor(.purple).cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.2), lineWidth: 1))
    }
    // COMPONENT NÂNG CẤP: Ẩn/Hiện một phần công thức tính toán với nút "Xem thêm"
        private var formulaExplanationCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header cố định luôn hiển thị
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.App.subheadlineRegular)
                        .foregroundColor(Color.App.primary)
                    Text("Cơ sở tính toán khoa học")
                        .font(.App.subheadline)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Nút bấm Xem thêm / Thu gọn tối giản
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Thu gọn" : "Xem thêm")
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        }
                        .font(.App.caption)
                        .foregroundColor(Color.App.primary)
                    }
                }
                
                Text("Lượng tiêu hao được ước tính tự động dựa trên chỉ số trao đổi chất cốt lõi (BMR) kết hợp với cường độ gắng sức (MET) của bài tập:")
                    .font(.App.captionMedium)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                
                // Công thức tổng quát (Luôn hiển thị để người dùng nắm được tinh thần cốt lõi)
                VStack(spacing: 4) {
                    Text("Calories = (BMR / 1440) × MET × Thời gian")
                        .font(.App.caption)
                        .foregroundColor(Color.App.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.App.primaryLight.opacity(0.4))
                .cornerRadius(10)
                
                // KHỐI NỘI DUNG ẨN: Chỉ bung mở ra khi người dùng nhấn "Xem thêm" (isExpanded == true)
                if isExpanded {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cách tính chỉ số BMR cụ thể (Harris-Benedict):")
                            .font(.App.caption)
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.top, 4)
                        
                        // Nhánh công thức dành cho Nam
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle().fill(Color.blue).frame(width: 6, height: 6)
                                Text("Đối với Nam giới:")
                                    .font(.App.small)
                                    .foregroundColor(.blue)
                            }
                            Text("66.47 + (13.75 × W) + (5.003 × H) - (6.755 × A)")
                                .font(.App.smallSemibold)
                                .foregroundColor(.black.opacity(0.8))
                                .padding(.leading, 12)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.04))
                        .cornerRadius(8)
                        
                        // Nhánh công thức dành cho Nữ
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle().fill(Color.red).frame(width: 6, height: 6)
                                Text("Đối với Nữ giới:")
                                    .font(.App.small)
                                    .foregroundColor(.red)
                            }
                            Text("655.1 + (9.563 × W) + (1.85 × H) - (4.676 × A)")
                                .font(.App.smallSemibold)
                                .foregroundColor(.black.opacity(0.8))
                                .padding(.leading, 12)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.04))
                        .cornerRadius(8)
                        
                        // Ký hiệu biến
                        HStack(spacing: 12) {
                            Text("• W: Cân nặng (kg)").foregroundColor(.gray)
                            Text("• H: Chiều cao (cm)").foregroundColor(.gray)
                            Text("• A: Tuổi của bạn").foregroundColor(.gray)
                        }
                        .font(.App.tinyMedium)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top))) // Hiệu ứng cuộn bung mở mượt mà
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
        }
    
    private var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.App.large)
                .foregroundColor(.gray.opacity(0.4))
            Text("Không tìm thấy kết quả phù hợp")
                .foregroundColor(.gray)
                .font(.App.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private var saveButton: some View {
        Button(action: {
            if let activity = selectedActivity {
                router.showLoading()
                viewModel.addLog(userId: userId, activity: activity, duration: Double(duration), date: date)
                
                // Giả lập delay nhẹ để người dùng thấy loading mượt mà
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    router.hideLoading()
                    router.showToast(message: "Đã thêm hoạt động vào nhật ký", type: .success)
                    dismiss()
                }
            }
        }) {
            HStack(spacing: 10) {
                if selectedActivity != nil {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("Xác nhận lưu")
            }
            .font(.App.title)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(selectedActivity == nil ? Color.gray.opacity(0.3) : Color.App.primary)
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: (selectedActivity == nil ? Color.clear : Color.App.primary.opacity(0.3)), radius: 10, x: 0, y: 8)
        }
        .disabled(selectedActivity == nil)
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
}

// MARK: - ActivityTypeItem
struct ActivityTypeItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.App.primary : Color.white)
                    .frame(width: 64, height: 64)
                    .shadow(color: isSelected ? Color.App.primary.opacity(0.3) : Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                
                Image(systemName: icon)
                    .font(.App.header)
                    .foregroundColor(isSelected ? .white : Color.App.primary)
            }
            
            Text(title)
                .font(.App.subheadline)
                .foregroundColor(isSelected ? Color.App.primary : .black)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }
}

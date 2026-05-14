import SwiftUI

struct AddActivitySheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ActivityViewModel
    let userId: String
    let date: Date
    
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
        appearance.backgroundColor = UIColor.white // Nền trắng rõ ràng cho header
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
                    // 1. Thanh tìm kiếm nổi bật hơn
                    searchBar
                        .padding(.top, 15)
                        .padding(.bottom, 20)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) {
                            
                            // 2. Section: Chọn loại hoạt động
                            VStack(alignment: .leading, spacing: 16) {
                                Text(searchText.isEmpty ? "Hoạt động phổ biến" : "Kết quả tìm kiếm")
                                    .font(.system(size: 19, weight: .bold))
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
                                                        selectedActivity = activity
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
                                    .font(.system(size: 19, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 4)
                                
                                timeAdjustmentCard
                            }
                            
                            // 4. Section: Hiển thị Calo dự kiến (chỉ hiện khi đã chọn hoạt động)
                            if selectedActivity != nil {
                                estimatedCaloriesView
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Tránh đè lên nút Save
                    }
                }
                
                // Nút Lưu nằm đè lên dưới cùng với hiệu ứng mờ nền
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
                        .foregroundColor(.red) // Màu đỏ cho nút hủy để rõ chức năng
                        .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Components mở rộng
extension AddActivitySheet {
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 18, weight: .bold))
            
            TextField("", text: $searchText, prompt: Text("Tìm kiếm bài tập...").foregroundColor(.gray))
                .foregroundColor(.black)
                .font(.system(size: 16))
            
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
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(duration)")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(Color.App.primary)
                    Text("phút")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                Button(action: { if duration > 5 { duration -= 5 } }) {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(Color.App.secondaryBackground)
                        .foregroundColor(.black)
                }
                
                Divider().frame(height: 30)
                
                Button(action: { duration += 5 }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
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
    
    private var estimatedCaloriesView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Năng lượng tiêu thụ")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                
                let calories = (selectedActivity?.metValue ?? 5.0) * Double(duration)
                Text("~\(Int(calories)) kcal")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("Dự tính")
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.App.secondaryBackground)
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.orange.opacity(0.3), lineWidth: 1))
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))
            Text("Không tìm thấy kết quả phù hợp")
                .foregroundColor(.gray)
                .font(.system(size: 15))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    private var saveButton: some View {
        Button(action: {
            if let activity = selectedActivity {
                viewModel.addLog(userId: userId, activity: activity, duration: Double(duration), date: date)
                dismiss()
            }
        }) {
            HStack(spacing: 10) {
                if selectedActivity != nil {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("Xác nhận lưu")
            }
            .font(.system(size: 18, weight: .bold))
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

// MARK: - ActivityTypeItem (Tối ưu giao diện)
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
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : Color.App.primary)
            }
            
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                .foregroundColor(isSelected ? Color.App.primary : .black)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
    }
}

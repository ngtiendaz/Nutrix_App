import SwiftUI
import FirebaseAuth

struct ActivityView: View {
    @Binding var selectedDate: Date
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var showAddSheet = false
    @State private var selectedLog: UserActivityLog?

    let userId = Auth.auth().currentUser?.uid ?? ""
    
    // --- COMPUTED PROPERTIES ---
    
    // Tổng calo thực tế đã đốt từ danh sách tập luyện
    var totalCalories: Int {
        activityViewModel.userLogs.reduce(0) { $0 + Int($1.caloriesBurned) }
    }
    
    // Tổng thời gian tập luyện thực tế
    var totalDuration: Int {
        activityViewModel.userLogs.reduce(0) { $0 + Int($1.durationMinutes) }
    }
    
    // Tính toán tiến độ vòng tròn (Tối đa 1.0 để không bị vẽ đè)
    private var progress: CGFloat {
        let goal = Double(activityViewModel.goalCalories)
        guard goal > 0 else { return 0 }
        return CGFloat(min(Double(totalCalories) / goal, 1.0))
    }
    
    // Kiểm tra trạng thái hoàn thành mục tiêu
    private var isGoalAchieved: Bool {
        activityViewModel.goalCalories > 0 && totalCalories >= activityViewModel.goalCalories
    }

    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // Header chọn ngày
                        TopBar(selectedTab: .constant(.activity), selectedDate: $selectedDate)
                        
                        // Card chỉ số chính
                        mainStatsCard

                        // --- SECTION: LỊCH SỬ HOẠT ĐỘNG ---
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                Text("Lịch sử hoạt động")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Button(action: { showAddSheet = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Thêm mới")
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.App.primary)
                                }
                            }
                            
                            if activityViewModel.userLogs.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(activityViewModel.userLogs) { log in
                                    ActivityCard(log: log)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedLog = log }
                                }
                            }
                        }
                        .padding(.bottom, 70)
                    }
                }
            }  .padding(.horizontal,12)
        }
        .onAppear {
            // Load dữ liệu lần đầu
            activityViewModel.getUserLogs(userId: userId, date: selectedDate)
        }
        .onChange(of: selectedDate) { newDate in
            // Reload khi người dùng đổi ngày trên TopBar
            activityViewModel.getUserLogs(userId: userId, date: newDate)
        }
        .sheet(isPresented: $showAddSheet) {
            AddActivitySheet(viewModel: activityViewModel, userId: userId, date: selectedDate)
        }
        .sheet(item: $selectedLog) { log in
            ActivityDetailView(viewModel: activityViewModel, userId: userId, log: log, date: selectedDate)
        }
    }

    // MARK: - Components

    private var mainStatsCard: some View {
        VStack(spacing: 30) {
            // Vòng tròn Calo trung tâm
            ZStack {
                // Vòng tròn nền xám
                Circle()
                    .stroke(Color.App.secondaryBackground, lineWidth: 16)
                
                // Vòng tròn tiến độ (Cam hoặc Xanh lá nếu đạt mục tiêu)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isGoalAchieved ? Color.App.primary : Color.App.primary,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                
                VStack(spacing: 4) {
                    Text("\(totalCalories)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(isGoalAchieved ? .App.primary : .black)
                    
                    Text("kcal đã đốt")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.App.primary)
                    
                    if isGoalAchieved {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.App.lightGray)
                            .font(.system(size: 22))
                            .padding(.top, 4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(width: 200, height: 200)
            .padding(.top, 10)
            
            // Dòng thông tin Mục tiêu & Thời gian tập
            HStack {
                // Widget Mục tiêu
                VStack(alignment: .leading, spacing: 6) {
                    Text("MỤC TIÊU ĐỐT")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color.App.lightGray)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 14))
                        Text("\(activityViewModel.goalCalories) kcal")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Widget Thời gian
                VStack(alignment: .trailing, spacing: 6) {
                    Text("TỔNG THỜI GIAN")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Color.App.lightGray)
                    
                    HStack(alignment: .bottom, spacing: 2) {
                        Image(systemName: "stopwatch")
                            .font(.system(size: 14))
                            .padding(.bottom, 3)
                        Text("\(totalDuration)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                        Text("phút")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.App.lightGray)
                            .padding(.bottom, 2)
                    }
                }
            }
            .padding(.horizontal, 5)
        }
        .padding(25)
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 10)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(Color.App.secondaryBackground)
            Text("Chưa có dữ liệu tập luyện")
                .font(.system(size: 15))
                .foregroundColor(Color.App.lightGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

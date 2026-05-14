import SwiftUI
import FirebaseAuth


struct ActivityView: View {
    @Binding var selectedDate: Date
    @StateObject private var viewModel = ActivityViewModel()
    @State private var showAddSheet = false
    @State private var selectedLog: UserActivityLog?

    let userId = Auth.auth().currentUser?.uid ?? ""
    
    // Thông số tổng hợp
    var totalCalories: Int { viewModel.userLogs.reduce(0) { $0 + Int($1.caloriesBurned) } }
    var totalDuration: Int { viewModel.userLogs.reduce(0) { $0 + Int($1.durationMinutes) } }
    let goalCalories: Int = 800

    var body: some View {
        ZStack {
            Color.App.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        TopBar(selectedTab: .constant(.activity), selectedDate: $selectedDate)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        mainStatsCard
                            .padding(.horizontal)

                        // --- SECTION 2: LỊCH SỬ HOẠT ĐỘNG ---
                        VStack(alignment: .leading, spacing: 15) {
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
                            
                            if viewModel.userLogs.isEmpty {
                                emptyStateView
                            } else {
                                ForEach(viewModel.userLogs) { log in
                                    ActivityCard(log: log)
                                        .onTapGesture { selectedLog = log }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .onAppear {
            viewModel.getDataset()
            viewModel.getUserLogs(userId: userId, date: selectedDate)
        }
        .sheet(isPresented: $showAddSheet) {
            AddActivitySheet(viewModel: viewModel, userId: userId, date: selectedDate)
        }
        .sheet(item: $selectedLog) { log in
            ActivityDetailView(viewModel: viewModel, userId: userId, log: log, date: selectedDate)
        }
    }

    // MARK: - Main Stats Card Component
    private var mainStatsCard: some View {
        VStack(spacing: 25) {
            // Vòng tròn Calo lớn
            ZStack {
                Circle()
                    .stroke(Color.App.secondaryBackground, lineWidth: 15)
                Circle()
                    .trim(from: 0, to: CGFloat(min(Double(totalCalories) / Double(goalCalories), 1.0)))
                    .stroke(Color.App.primary, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(totalCalories)")
                        .font(.system(size: 45, weight: .bold))
                        .foregroundColor(.black)
                    Text("kcal đã đốt")
                        .font(.system(size: 16))
                        .foregroundColor(Color.App.lightGray)
                }
            }
            .frame(width: 180, height: 180)
            .padding(.top, 10)
            
            // Dòng thông tin mục tiêu và thời gian
            HStack {
                // Mục tiêu Calo
                VStack(alignment: .leading, spacing: 5) {
                    Text("MỤC TIÊU")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.App.lightGray)
                    Text("\(goalCalories) kcal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Đường kẻ phân cách dọc
                Rectangle()
                    .fill(Color.App.secondaryBackground)
                    .frame(width: 1, height: 35)
                
                Spacer()
                
                // Thời gian tập luyện
                VStack(alignment: .trailing, spacing: 5) {
                    Text("THỜI GIAN")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.App.lightGray)
                    HStack(alignment: .bottom, spacing: 2) {
                        Text("\(totalDuration)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        Text("phút")
                            .font(.system(size: 12))
                            .foregroundColor(Color.App.lightGray)
                            .padding(.bottom, 2)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
        .padding(25)
        .background(Color.white)
        .cornerRadius(30)
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

// MARK: - Activity Card
struct ActivityCard: View {
    let log: UserActivityLog
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.App.primaryLight)
                    .frame(width: 52, height: 52)
                
                Image(systemName: log.activityType.icon)
                    .font(.system(size: 22))
                    .foregroundColor(Color.App.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(log.activityType.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                HStack(spacing: 12) {
                    Label("\(Int(log.durationMinutes)) phút", systemImage: "clock")
                    Label("\(Int(log.caloriesBurned)) kcal", systemImage: "flame")
                }
                .font(.system(size: 13))
                .foregroundColor(Color.App.lightGray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.App.secondaryBackground)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
    }
}

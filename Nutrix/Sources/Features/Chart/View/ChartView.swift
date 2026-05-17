import SwiftUI
import Charts

struct ChartView: View {
    @Binding var selectedDate: Date
    @StateObject private var viewModel = StatisticsViewModel()
    
    private let months = Array(1...12)
    private let years = Array(2024...2030)
    
    var body: some View {
        ZStack {
            Color.App.background
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }
            
            VStack(spacing: 0) {
                // 1. Header & Điều hướng bộ lọc thời gian
                VStack(spacing: 12) {
                    TopBar(selectedTab: .constant(.chart), selectedDate: $selectedDate)
                    filterSegmentedControl
                    dynamicTimeNavigator
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 15)
                .background(Color.white)
                
                // 2. Khu vực hiển thị Nội dung chính
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Đang tải dữ liệu...").tint(Color.App.primary)
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    Text(errorMessage).foregroundColor(.red).font(.system(size: 14))
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            overviewKPISection
                            
                            let pointsForChart = viewModel.selectedTab == .month ? viewModel.visibleMonthPoints : (viewModel.report?.summaryPoints ?? [])
                            chartSection(points: pointsForChart)
                            
                            macroPieChartSection
                            
                            historyListSection(points: viewModel.report?.summaryPoints ?? [])
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 70)
                    }
                }
            }
        }
        .onAppear { viewModel.loadStatistics(targetDate: selectedDate) }
        .onChange(of: viewModel.selectedTab) { _ in viewModel.loadStatistics(targetDate: viewModel.currentWeekStartDate) }
        .onChange(of: viewModel.selectedMonth) { _ in viewModel.loadStatistics(targetDate: selectedDate) }
        .onChange(of: viewModel.selectedYear) { _ in viewModel.loadStatistics(targetDate: selectedDate) }
    }
}

// MARK: - Subviews UI Components
extension ChartView {
    
    private var filterSegmentedControl: some View {
        HStack(spacing: 4) {
            tabButton(title: "Tuần", tab: .week)
            tabButton(title: "Tháng", tab: .month)
            tabButton(title: "Năm", tab: .year)
        }
        .padding(4)
        .background(Color.App.primaryLight)
        .cornerRadius(12)
    }
    
    private func tabButton(title: String, tab: StatisticsTab) -> some View {
        Button { viewModel.selectedTab = tab } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(viewModel.selectedTab == tab ? .white : Color.App.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(viewModel.selectedTab == tab ? Color.App.primary : Color.clear)
                .cornerRadius(10)
        }
    }
    
    private var dynamicTimeNavigator: some View {
        HStack {
            if viewModel.selectedTab == .week {
                HStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button(action: { viewModel.changeWeek(by: -1) }) {
                            Image(systemName: "chevron.left").font(.system(size: 12, weight: .bold)).foregroundColor(.black)
                        }
                        
                        Text(viewModel.weekRangeString)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                        
                        // KHẮC PHỤC: Làm mờ nút Next nếu đang ở tuần hiện tại, chặn bấm tương lai
                        Button(action: { viewModel.changeWeek(by: 1) }) {
                            Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                                .foregroundColor(viewModel.isCurrentOrFutureWeek ? .gray.opacity(0.3) : .black)
                        }
                        .disabled(viewModel.isCurrentOrFutureWeek)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.App.background).cornerRadius(10)
                    
                    Spacer()
                }
            } else if viewModel.selectedTab == .month {
                HStack {
                    HStack(spacing: 10) {
                        Button(action: { if viewModel.monthSliceIndex > 0 { viewModel.monthSliceIndex -= 1 } }) {
                            Image(systemName: "arrow.left").font(.system(size: 11, weight: .bold)).foregroundColor(viewModel.monthSliceIndex == 0 ? .gray : .black)
                        }.disabled(viewModel.monthSliceIndex == 0)
                        
                        // KHẮC PHỤC LỖI TRÀN CHỮ: Thu nhỏ font xuống 12 để hiển thị vừa vặn trong ô
                        Text(viewModel.monthSliceRangeString)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .frame(width: 95) // Cố định bề ngang text để nút arrow không bị xê dịch
                        
                        Button(action: { if viewModel.monthSliceIndex < viewModel.maxMonthSliceIndex { viewModel.monthSliceIndex += 1 } }) {
                            Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold)).foregroundColor(viewModel.monthSliceIndex == viewModel.maxMonthSliceIndex ? .gray : .black)
                        }.disabled(viewModel.monthSliceIndex == viewModel.maxMonthSliceIndex)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.App.background).cornerRadius(10)
                    
                    Spacer()
                    datePickerSelectors
                }
            } else {
                HStack {
                    datePickerSelectors
                    Spacer()
                }
            }
        }
        .frame(height: 34)
    }
    
    private var datePickerSelectors: some View {
        HStack(spacing: 6) {
            if viewModel.selectedTab == .month {
                Picker("Tháng", selection: $viewModel.selectedMonth) {
                    ForEach(months, id: \.self) { Text("\($0)").tag($0) }
                }.pickerStyle(.menu).tint(Color.App.primary)
                .padding(.horizontal, 2).background(Color.App.background).cornerRadius(8)
            }
            Picker("Năm", selection: $viewModel.selectedYear) {
                ForEach(years, id: \.self) { Text(String($0)).tag($0) }
            }.pickerStyle(.menu).tint(Color.App.primary)
            .padding(.horizontal, 2).background(Color.App.background).cornerRadius(8)
        }
    }
    
    private var overviewKPISection: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Trung bình nạp/ngày").font(.system(size: 11, weight: .semibold)).foregroundColor(.gray)
                Text("\(viewModel.avgIntakePerDay) Kcal").font(.system(size: 18, weight: .black)).foregroundColor(Color.App.primary)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color.white).cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Trung bình tiêu hao/ngày").font(.system(size: 11, weight: .semibold)).foregroundColor(.gray)
                Text("\(viewModel.avgBurnedPerDay) Kcal").font(.system(size: 18, weight: .black)).foregroundColor(.orange)
            }
            .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color.white).cornerRadius(16)
        }
    }
    
    private func chartSection(points: [MetricPoint]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Biểu đồ tiến độ").font(.system(size: 14, weight: .bold)).foregroundColor(.black)
                Spacer()
                
                if !viewModel.isDataEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isTrendUp ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        Text(viewModel.isTrendUp ? "Tăng trưởng" : "Thâm hụt")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(viewModel.isTrendUp ? Color.App.primary : .orange)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(viewModel.isTrendUp ? Color.App.primaryLight : Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }.padding(.bottom, 6)
            
            ZStack {
                Chart {
                    ForEach(points) { point in
                        BarMark(
                            x: .value("Thời gian", point.label),
                            y: .value("Calo Nạp", point.intakeCalories),
                            width: .fixed(22)
                        )
                        .foregroundStyle(Color.App.primary.gradient)
                        .cornerRadius(4)
                        
                        // KHẮC PHỤC: ĐÃ XOÁ HOÀN TOÀN KHỐI LINEMARK ĐƯỜNG VÀNG MỤC TIÊU Ở ĐÂY
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Color.black.opacity(0.04))
                        AxisValueLabel().font(.system(size: 11, weight: .bold)).foregroundStyle(.black)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine().foregroundStyle(Color.black.opacity(0.04))
                        AxisValueLabel().font(.system(size: 10, weight: .medium)).foregroundStyle(.black)
                    }
                }
                
                if viewModel.isDataEmpty {
                    Color.white.opacity(0.85)
                    Text("Không có dữ liệu")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.gray)
                }
            }
            .frame(height: 180)
        }
        .padding(16).background(Color.white).cornerRadius(20)
    }
    
    private var macroPieChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tỉ lệ chất dinh dưỡng")
                .font(.system(size: 14, weight: .bold)).foregroundColor(.black)
            
            ZStack {
                HStack(spacing: 20) {
                    if #available(iOS 17.0, *), !viewModel.macroData.isEmpty {
                        Chart(viewModel.macroData) { element in
                            SectorMark(
                                angle: .value("Tỉ lệ", element.value),
                                innerRadius: .ratio(0.6),
                                angularInset: 1.5
                            )
                            .foregroundStyle(element.color)
                        }
                        .frame(width: 120, height: 120)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.macroData) { element in
                                HStack(spacing: 8) {
                                    Circle().fill(element.color).frame(width: 8, height: 8)
                                    Text(element.name).font(.system(size: 12, weight: .bold)).foregroundColor(.black)
                                    Spacer()
                                    Text(String(format: "%.1f%%", element.value)).font(.system(size: 12, weight: .heavy)).foregroundColor(.gray)
                                }
                            }
                        }
                    } else {
                        Circle()
                            .stroke(Color.black.opacity(0.04), lineWidth: 16)
                            .frame(width: 110, height: 110)
                            .padding(.leading, 10)
                        
                        Spacer()
                        Text("Không có dữ liệu")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(18).background(Color.white).cornerRadius(20)
    }
    
    private func historyListSection(points: [MetricPoint]) -> some View {
        // Lấy tất cả các ngày từ đầu chu kỳ cho đến ngày hiện tại (không lấy tương lai)
        let activePoints = points.filter { point in
            if let date = point.date { return date <= Date() }
            return true
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Chi tiết lịch sử").font(.system(size: 14, weight: .bold)).foregroundColor(.black)
            
            if activePoints.isEmpty {
                HStack {
                    Spacer()
                    Text("Danh sách lịch sử trống").font(.system(size: 13)).foregroundColor(.gray).padding()
                    Spacer()
                }
                .background(Color.white).cornerRadius(14)
            } else {
                ForEach(activePoints.reversed()) { point in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(listLabel(for: point)).font(.system(size: 15, weight: .bold)).foregroundColor(.black)
                            
                            // KHẮC PHỤC: Ẩn text mục tiêu Kcal nếu ngày đó không có lộ trình
                            if !point.hasPlan {
                                Text("Nạp thực tế: \(Int(point.intakeCalories)) Kcal")
                                    .font(.system(size: 12, weight: .medium)).foregroundColor(.gray)
                            } else {
                                Text("Nạp: \(Int(point.intakeCalories)) / Mục tiêu: \(Int(point.targetCalories)) Kcal")
                                    .font(.system(size: 12, weight: .medium)).foregroundColor(.gray)
                            }
                        }
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            // KHẮC PHỤC: Nếu ngày đó KHÔNG CÓ LỘ TRÌNH -> Ẩn phần trăm %, hiện badge xám gọn gàng
                            if !point.hasPlan {
                                Text("--").font(.system(size: 15, weight: .heavy)).foregroundColor(.gray)
                                Text("Không có lộ trình")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(Color.gray.opacity(0.1)).cornerRadius(6).foregroundColor(.gray)
                            } else {
                                Text("\(Int(point.completionRate))%")
                                    .font(.system(size: 15, weight: .heavy)).foregroundColor(statusColor(point.status))
                                Text(point.status.rawValue).foregroundColor(.white).font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6).padding(.vertical, 3).background(statusColor(point.status).opacity(0.8)).cornerRadius(6)
                            }
                        }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 14).background(Color.white).cornerRadius(14)
                }
            }
        }
    }
    
    private func listLabel(for point: MetricPoint) -> String {
        switch viewModel.selectedTab {
        case .week:
            let dayClean = point.label.replacingOccurrences(of: "T", with: "")
            return dayClean == "CN" ? "Chủ Nhật" : "Thứ \(dayClean)"
        case .month:
            return "Ngày \(point.label)"
        case .year:
            return "Tháng \(point.label.replacingOccurrences(of: "T", with: ""))"
        }
    }
}
    // Hàm phụ trợ map màu sắc tương ứng với mức độ hoàn thành dinh dưỡng
    private func statusColor(_ status: CompletionStatus) -> Color {
        switch status {
        case .perfect: return Color.App.primary // Xanh lá dịu cho ngày hoàn hảo
        case .over: return .orange            // Cam cho ngày vượt ngưỡng calo
        case .under: return .red// Đỏ cho ngày nạp thiếu hụt nhiều
        case .noPlan: return .gray
        }
    }

// Extension helper ẩn bàn phím khi tương tác chạm ngoài
#if canImport(UIKit)
extension ChartView {
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

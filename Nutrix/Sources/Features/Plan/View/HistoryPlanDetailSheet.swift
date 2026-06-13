import SwiftUI
import Charts

struct HistoryPlanDetailSheet: View {
    let plan: NutritionPlan
    let allMetrics: [BodyMetrics]
    
    @StateObject private var viewModel = HistoryPlanDetailViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                HStack {
                    Text("Chi tiết Lộ trình")
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
                .padding(.bottom, 10)
            }
            .background(Color.white)
            
            ZStack {
                Color.App.background.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Đang tải dữ liệu...")
                        .tint(Color.App.primary)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            nutritionGoalsSection
                            weightChartSection
                            executionGridSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadDetails(for: plan, allMetrics: allMetrics)
        }
    }
    
    // MARK: - Nutrition Goals
    private var nutritionGoalsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Mục tiêu dinh dưỡng")
                    .font(.App.sectionHeader)
                    .foregroundColor(.black)
                Spacer()
                Text("\(Int(plan.dailyCalories)) kcal")
                    .font(.App.subheadlineRegular)
                    .foregroundColor(Color.App.primary)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                metricCard(label: "Chỉ tiêu Đạm", value: plan.protein, unit: "g", icon: "drop.fill", color: .red)
                metricCard(label: "Chỉ tiêu Tinh bột", value: plan.carbs, unit: "g", icon: "leaf.fill", color: .blue)
                metricCard(label: "Chỉ tiêu Béo", value: plan.fat, unit: "g", icon: "circle.dotted", color: .yellow)
                metricCard(label: "Mục tiêu Cân nặng", value: plan.targetWeight ?? 0, unit: "kg", icon: "scalemass.fill", color: .purple)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(20)
    }
    
    private func metricCard(label: String, value: Double, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.App.tinyMedium)
                    .foregroundColor(color)
                Text(label)
                    .font(.App.captionMedium)
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                Text(String(format: "%.1f", value))
                    .font(.App.bodyBold)
                    .foregroundColor(.black)
                Text(unit)
                    .font(.App.smallSemibold)
                    .foregroundColor(.gray)
                    .padding(.bottom, 1.5)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.App.background)
            .cornerRadius(10)
        }
    }
    
    // MARK: - Weight Chart
    private var weightChartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Biến động cân nặng")
                .font(.App.sectionHeader)
                .foregroundColor(.black)
            
            if viewModel.weightChartData.isEmpty {
                HStack {
                    Spacer()
                    Text("Không có dữ liệu cân nặng trong giai đoạn này.")
                        .font(.App.captionMedium)
                        .foregroundColor(.gray)
                        .padding(.vertical, 30)
                    Spacer()
                }
            } else {
                Chart {
                    if let target = plan.targetWeight {
                        RuleMark(y: .value("Mục tiêu", target))
                            .foregroundStyle(.orange.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }

                    ForEach(viewModel.weightChartData) { point in
                        LineMark(
                            x: .value("Ngày", point.dateLabel),
                            y: .value("Cân nặng", point.weight)
                        )
                        .foregroundStyle(Color.App.primary)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        
                        PointMark(
                            x: .value("Ngày", point.dateLabel),
                            y: .value("Cân nặng", point.weight)
                        )
                        .foregroundStyle(Color.App.primary)
                        .annotation(position: .top) {
                            Text("\(String(format: "%.1f", point.weight))")
                                .font(.App.tinyMedium)
                                .foregroundColor(.black.opacity(0.8))
                        }
                    }
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel().font(.App.tiny).foregroundStyle(.gray)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine().foregroundStyle(Color.black.opacity(0.02))
                        AxisValueLabel {
                            if let intValue = value.as(Double.self) {
                                Text("\(Int(intValue))").font(.App.tiny).foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(20)
    }
    
    // MARK: - Execution Log Grid
    private var executionGridSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Nhật ký thực hiện")
                    .font(.App.sectionHeader)
                    .foregroundColor(.black)
                Spacer()
                Text("\(viewModel.executionLog.filter({$0.isCompleted}).count)/\(viewModel.executionLog.count) ngày")
                    .font(.App.captionMedium)
                    .foregroundColor(Color.App.primary)
            }
            
            let columns = [
                GridItem(.adaptive(minimum: 45))
            ]
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.executionLog) { day in
                    VStack(spacing: 6) {
                        Text(day.label)
                            .font(.App.tiny)
                            .foregroundColor(.gray)
                        
                        ZStack {
                            Circle()
                                .fill(day.isCompleted ? Color.App.primaryLight : Color.black.opacity(0.03))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: day.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundColor(day.isCompleted ? Color.App.primary : .gray.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(20)
    }
}

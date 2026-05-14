//
//  BodyMetricsHistorySheet.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//

import SwiftUI



struct BodyMetricsHistorySheet: View {
    let history: [BodyMetrics]
    @Environment(\.dismiss) var dismiss
    
    init(history: [BodyMetrics]) {
            self.history = history
            // Thiết lập màu sắc cho NavigationBar (Tiêu đề màu trắng trên nền đen)
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.App.background) // Hoặc .black nếu muốn đen hoàn toàn
            appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.App.background.ignoresSafeArea() // Sử dụng màu nền của App
                
                if history.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(history) { item in
                                MetricHistoryRow(item: item)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Lịch sử chỉ số")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.App.primary)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))
            Text("Chưa có dữ liệu lịch sử")
                .foregroundColor(.gray)
        }
    }
}
struct MetricHistoryRow: View {
    let item: BodyMetrics
    
    var body: some View {
        HStack(spacing: 16) {
            // Biểu tượng trạng thái bên trái
            ZStack {
                Circle()
                    .fill(statusColor(item.status).opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: statusIcon(item.status))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(statusColor(item.status))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(item.weight, specifier: "%.1f") kg")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                
                Text("\(Int(item.height)) cm")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Hiển thị phần trăm thay đổi
                if item.percentChange != 0 {
                    Text("\(item.percentChange > 0 ? "+" : "")\(item.percentChange, specifier: "%.1f")%")
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(item.status).opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(statusColor(item.status))
                }
                
                Text(item.timestamp, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    // Logic màu sắc và icon đồng bộ
    func statusIcon(_ status: String) -> String {
        switch status {
        case "Tăng": return "chart.line.uptrend.xyaxis"
        case "Giảm": return "chart.line.downtrend.xyaxis"
        default: return "equal.circle.fill"
        }
    }
    
    func statusColor(_ status: String) -> Color {
        switch status {
        case "Tăng": return .orange // Màu cam đặc trưng cho năng lượng/tăng cân
        case "Giảm": return Color.App.primary // Màu xanh lá của App cho việc giảm/duy trì
        default: return .blue
        }
    }
}

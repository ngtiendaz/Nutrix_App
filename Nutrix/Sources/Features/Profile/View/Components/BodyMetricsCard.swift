//
//  BodyMetricsCard.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//
import SwiftUI

struct BodyMetricsCard: View {
    @ObservedObject var vm: ProfileViewModel
    var onUpdate: () -> Void
    var onShowHistory: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Hàng chỉ số 2 cột
            HStack(spacing: 15) {
                // Đảm bảo sử dụng nhất quán isEditingMetrics
                MetricBox(label: "Chiều cao", value: $vm.height, unit: "cm", icon: "figure.stand", isEditing: vm.isEditingMetrics)
                MetricBox(label: "Cân nặng", value: $vm.weight, unit: "kg", icon: "scalemass.fill", isEditing: vm.isEditingMetrics)
            }
            
            HStack(spacing: 12) {
                Button(action: onShowHistory) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Lịch sử")
                    }
                    .font(.App.body)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
                }
                
                // Nút Cập nhật / Lưu
                Button(action: onUpdate) {
                    // Sửa từ isEditing sang isEditingMetrics để nút đổi chữ đúng lúc
                    Text(vm.isEditingMetrics ? "Lưu chỉ số" : "Cập nhật")
                        .font(.App.sectionHeader)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(vm.isEditingMetrics ? Color.green : Color.App.primary)
                        .cornerRadius(12)
                        .shadow(color: (vm.isEditingMetrics ? Color.green : Color.App.primary).opacity(0.2), radius: 5, y: 3)
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 8)
    }
}

struct MetricBox: View {
    let label: String
    @Binding var value: String
    let unit: String
    let icon: String
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.App.captionMedium)
                    .foregroundColor(Color.App.primary)
                Text(label)
                    .font(.App.subheadlineRegular)
                    .foregroundColor(.gray)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                if isEditing {
                    TextField("0", text: $value)
                        .font(.App.title2)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.black)
                } else {
                    Text(value.isEmpty ? "--" : value)
                        .font(.App.title2)
                        .foregroundColor(.black)
                }
                
                Text(unit)
                    .font(.App.body)
                    .foregroundColor(.gray)
                    .padding(.bottom, 2)
                
                Spacer()
            }
            .frame(height: 40)
            .padding(.horizontal, 12)
            // Hiệu ứng đổi màu nền nhẹ nhàng khi ở chế độ edit
            .background(isEditing ? Color.App.primary.opacity(0.08) : Color.black.opacity(0.03))
            .cornerRadius(10)
            // Thêm viền mỏng khi edit để làm rõ vùng nhập liệu
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isEditing ? Color.App.primary.opacity(0.2) : Color.clear, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
    }
}

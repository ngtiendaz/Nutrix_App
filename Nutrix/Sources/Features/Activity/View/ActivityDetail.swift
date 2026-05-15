//
//  ActivityDetail.swift
//  Nutrix
//
//  Created by Daz on 14/5/26.
//

import SwiftUI

struct ActivityDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ActivityViewModel
    var userId: String
    let log: UserActivityLog
    var date: Date
    
    @State private var duration: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background đồng bộ
                Color.App.background.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // 1. Header Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.App.primaryLight)
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: log.activityType.icon)
                                .font(.system(size: 45))
                                .foregroundColor(Color.App.primary)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 4) {
                            Text(log.activityType.name)
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.black)
                            
                            Text("Chỉnh sửa nhật ký tập luyện")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 2. Input Card
                    VStack(alignment: .leading, spacing: 15) {
                        Text("THỜI GIAN TẬP LUYỆN")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.App.primary)
                            .tracking(1)
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(Color.App.primary)
                            
                            TextField("0", text: $duration)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .keyboardType(.numberPad)
                            
                            Text("phút")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.App.secondaryBackground.opacity(0.5))
                        .cornerRadius(15)
                        
                        // Hiển thị calo tính toán nhanh
                        if let min = Double(duration) {
                            let burned = (log.activityType.metValue * (60.0 / 1440.0) * 1500.0 / 60.0) * min // Ước tính nhanh
                            HStack {
                                Image(systemName: "flame.fill")
                                Text("Ước tính đốt cháy: ~\(Int(log.caloriesBurned * (min / log.durationMinutes))) kcal")
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                            .padding(.leading, 4)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 3. Action Buttons
                    VStack(spacing: 15) {
                        // Nút Lưu
                        Button(action: {
                            if let min = Double(duration) {
                                viewModel.updateLog(userId: userId, logId: log.id, duration: min, activity: log.activityType, date: date)
                                dismiss()
                            }
                        }) {
                            Text("Lưu thay đổi")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.App.primary)
                                .cornerRadius(18)
                                .shadow(color: Color.App.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        
                        // Nút Xóa
                        Button(action: {
                            viewModel.deleteLog(userId: userId, logId: log.id, date: date)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Xóa hoạt động")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .onAppear {
                duration = "\(Int(log.durationMinutes))"
            }
        }
    }
}

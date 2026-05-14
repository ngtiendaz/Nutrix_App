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
            VStack(spacing: 30) {
                // Hiển thị icon & tên
                VStack {
                    Image(systemName: log.activityType.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text(log.activityType.name).font(.largeTitle).bold()
                }.padding(.top)
                
                // Nhập liệu sửa
                VStack(alignment: .leading) {
                    Text("Thời gian tập luyện (phút)").font(.caption).foregroundColor(.gray)
                    TextField("Phút", text: $duration)
                        .font(.title).bold()
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .keyboardType(.numberPad)
                }.padding(.horizontal)
                
                Spacer()
                
                // Nút Lưu
                Button(action: {
                    if let min = Double(duration) {
                        viewModel.updateLog(userId: userId, logId: log.id, duration: min, activity: log.activityType, date: date)
                        dismiss()
                    }
                }) {
                    Text("Lưu thay đổi").frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)
                }.padding(.horizontal)
                
                // Nút Xóa
                Button(action: {
                    viewModel.deleteLog(userId: userId, logId: log.id, date: date)
                    dismiss()
                }) {
                    Text("Xóa hoạt động này").foregroundColor(.red)
                }
            }
            .onAppear { duration = "\(Int(log.durationMinutes))" }
            .navigationTitle("Chi tiết")
            .navigationBarItems(trailing: Button("Đóng") { dismiss() })
        }
    }
}

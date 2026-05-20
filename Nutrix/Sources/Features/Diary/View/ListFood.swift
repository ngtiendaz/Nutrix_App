////
////  ListFood.swift
////  Nutrix
////
////  Created by Daz on 20/5/26.
////
//
//import SwiftUI
//
//struct ListFood: View {
//    @StateObject private var viewModel = ListFoodViewModel()
//    @Environment(\.dismiss) var dismiss
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                // Ô tìm kiếm (Search Bar)
//                searchBarView
//                
//                // Nội dung chính
//                if viewModel.isLoading {
//                    ProgressView("Đang tải danh sách món ăn...")
//                        .padding(.top, 40)
//                    Spacer()
//                } else if let error = viewModel.errorMessage {
//                    VStack(spacing: 12) {
//                        Text("❌").font(.largeTitle)
//                        Text(error)
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
//                            .multilineTextAlignment(.center)
//                        Button("Thử lại") { viewModel.loadAllFoods() }
//                            .padding(.horizontal, 20)
//                            .padding(.vertical, 8)
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .cornerRadius(10)
//                    }
//                    .padding()
//                    Spacer()
//                } else if viewModel.filteredFoods.isEmpty {
//                    VStack {
//                        Text("🔍").font(.largeTitle)
//                        Text("Không tìm thấy món ăn nào phù hợp.")
//                            .foregroundColor(.gray)
//                    }
//                    .padding(.top, 40)
//                    Spacer()
//                } else {
//                    // Danh sách món ăn dạng ScrollView lướt mượt mà
//                    ScrollView {
//                        LazyVStack(spacing: 12) {
//                            ForEach(viewModel.filteredFoods) { food in
//                                foodRowCard(for: food)
//                            }
//                        }
//                        .padding()
//                    }
//                }
//            }
//            .navigationTitle("Danh sách có sẵn")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button { dismiss() } label: {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.gray.opacity(0.6))
//                            .font(.title3)
//                    }
//                }
//            }
//            .background(Color(.systemGroupedBackground).ignoresSafeArea())
//            .onAppear {
//                viewModel.loadAllFoods()
//            }
//        }
//    }
//    
//    // MARK: - Subviews thành phần gọn gàng
//    private var searchBarView: some View {
//        HStack {
//            Image(systemName: "magnifyingglass").foregroundColor(.gray)
//            TextField("Tìm kiếm món ăn...", text: $viewModel.searchText)
//                .disableAutocorrection(true)
//            if !viewModel.searchText.isEmpty {
//                Button { viewModel.searchText = "" } label: {
//                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
//                }
//            }
//        }
//        .padding(10)
//        .background(Color(.white))
//        .cornerRadius(12)
//        .padding(.horizontal)
//        .padding(.vertical, 10)
//        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
//    }
//    
//    private func foodRowCard(for food: Food) -> some View {
//        HStack(spacing: 15) {
//            // Ảnh món ăn (hoặc icon nếu không có ảnh)
//            if let urlString = food.imageUrl, let url = URL(string: urlString) {
//                AsyncImage(url: url) { phase in
//                    switch phase {
//                    case .success(let image):
//                        image.resizable().aspectRatio(contentMode: .fill)
//                    default:
//                        ZStack { Color.gray.opacity(0.1); Text("🍲") }
//                    }
//                }
//                .frame(width: 65, height: 65)
//                .cornerRadius(12)
//                .clipped()
//            } else {
//                ZStack {
//                    Color.orange.opacity(0.1)
//                    Text("🍜").font(.title2)
//                }
//                .frame(width: 65, height: 65)
//                .cornerRadius(12)
//            }
//            
//            // Chi tiết Tên và Macros dinh dưỡng chính
//            VStack(alignment: .leading, spacing: 4) {
//                Text(food.name)
//                    .font(.headline)
//                    .foregroundColor(.black)
//                    .lineLimit(1)
//                
//                HStack(spacing: 8) {
//                    Text("\(Int(food.calories)) kcal")
//                        .font(.subheadline)
//                        .bold()
//                        .foregroundColor(.orange)
//                    Text("•")
//                        .foregroundColor(.gray)
//                    Text("P: \(Int(food.protein))g  C: \(Int(food.carbs))g  F: \(Int(food.fats))g")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//                
//                Text("Khẩu phần: \(Int(food.servingSize)) \(food.servingUnit)")
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            // Nút Thêm nhanh món ăn này
//            Button {
//                // Xử lý logic chọn món ăn và thêm vào nhật ký tại đây
//                print("Đã chọn món: \(food.name)")
//            } label: {
//                Image(systemName: "plus.circle.fill")
//                    .font(.title2)
//                    .foregroundColor(.blue)
//            }
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
//    }
//}

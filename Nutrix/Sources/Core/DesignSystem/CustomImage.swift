//
//  CustomImage.swift
//  Nutrix
//
//  Created by Daz on 5/5/26.
//
import SwiftUI

struct CustomImage: View {
    let urlString: String?
    var width: CGFloat = 120
    var height: CGFloat = 120
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        Group {
            if let urlString = urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        placeholderView
                    case .empty:
                        ProgressView()
                            .frame(width: width, height: height)
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
    // View hiển thị khi ảnh lỗi hoặc không có URL
    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: "fork.knife") // Hoặc icon mặc định của app bạn
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

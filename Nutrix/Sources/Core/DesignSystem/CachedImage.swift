//
//  CachedImage.swift
//  Nutrix
//
//  Created by Daz on 5/5/26.
//

import SwiftUI

struct CachedImage: View {
    let urlString: String?
    var width: CGFloat = 120
    var height: CGFloat = 120
    var cornerRadius: CGFloat = 12
    
    @State private var cachedImage: UIImage? = nil
    @State private var isLoading = false

    var body: some View {
        Group {
            if let uiImage = cachedImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(width: width, height: height)
            } else {
                placeholderView
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: urlString) {
            await loadImage()
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.1)
            Image(systemName: "fork.knife")
                .font(.system(size: min(width, height) * 0.3))
                .foregroundColor(.gray.opacity(0.4))
        }
        .frame(width: width, height: height)
    }
    
    private func loadImage() async {
        guard let urlString = urlString, !urlString.isEmpty else { return }
        
        // 1. Kiểm tra cache nhanh trước
        if let cached = ImageCache.shared.get(forKey: urlString) {
            self.cachedImage = cached
            return
        }
        
        // 2. Nếu không có mới bắt đầu tải
        isLoading = true
        if let loadedImage = await ImageCache.shared.loadImage(from: urlString) {
            self.cachedImage = loadedImage
        }
        isLoading = false
    }
}

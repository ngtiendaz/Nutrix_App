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

    var body: some View {
        Group {
            if let uiImage = cachedImage {
                // Nếu đã có trong Cache -> Hiển thị ngay
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let urlString = urlString, let url = URL(string: urlString) {
                // Nếu chưa có -> Dùng AsyncImage để tải
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .onAppear {
                                // Sau khi tải xong, lưu vào Cache
                                extractAndCacheImage(from: image, key: urlString)
                            }
                    case .failure(_):
                        placeholderView
                    case .empty:
                        ProgressView().frame(width: width, height: height)
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
        .onAppear {
            // Vừa hiện View là check kho xem có ảnh chưa
            if let urlString = urlString {
                self.cachedImage = ImageCache.shared.get(forkey: urlString)
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: "fork.knife").foregroundColor(.white.opacity(0.6))
        }
    }
    
    // Hàm phụ để chuyển đổi SwiftUI Image sang UIImage để lưu vào NSCache
    @MainActor
    private func extractAndCacheImage(from image: Image, key: String) {
        let renderer = ImageRenderer(content: image)
        if let uiImage = renderer.uiImage {
            ImageCache.shared.set(uiImage, forKey: key)
        }
    }
}

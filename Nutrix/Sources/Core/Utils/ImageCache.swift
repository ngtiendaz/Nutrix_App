//
//  ImageCache.swift
//  Nutrix
//
//  Created by Daz on 5/5/26.
//

import UIKit

class ImageCache {
    
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 200 // Tăng giới hạn số lượng ảnh
        cache.totalCostLimit = 150 * 1024 * 1024 // 150MB RAM
    }
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func loadImage(from urlString: String) async -> UIImage? {
        // 1. Kiểm tra cache trước
        if let cached = get(forKey: urlString) {
            return cached
        }
        
        // 2. Tải từ URL
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            // 3. Lưu vào cache
            set(image, forKey: urlString)
            return image
        } catch {
            print("❌ Error loading image: \(error)")
            return nil
        }
    }
}

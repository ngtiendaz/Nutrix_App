//
//  ImageCache.swift
//  Nutrix
//
//  Created by Daz on 5/5/26.
//

import UIKit

class ImageCache {
    
    static let shared = ImageCache()
    
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        
        cache.countLimit = 100 // 100 image
        cache.totalCostLimit = 100 * 1024 * 1024 // 100mb ram
    }
    
    func get(forkey key: String) -> UIImage?{
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, forKey key: String) {
        // Tính toán chi phí bộ nhớ xấp xỉ của ảnh: width * height * 4 (bytes per pixel cho RGBA)
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}

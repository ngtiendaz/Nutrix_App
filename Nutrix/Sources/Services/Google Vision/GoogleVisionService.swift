//
//  GoogleVisionService.swift
//  Nutrix
//
//  Created by Daz on 1/5/26.
//

import Foundation
import UIKit

class GoogleVisionService {
    // Thay chuỗi này bằng API Key ông lấy từ Google Cloud Console (image_65fec0.jpg)
    private let apiKey = AppConfig.visionAPIKey
    private let baseURL = "https://vision.googleapis.com/v1/images:annotate"

    func analyzeImage(uiImage: UIImage, completion: @escaping (Result<VisionResponse, Error>) -> Void) {
        
        // 1. Chuyển ảnh sang chuỗi Base64
        guard let imageData = uiImage.jpegData(compressionQuality: 0.8) else {
            let error = NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không thể chuyển đổi ảnh sang dữ liệu"])
            completion(.failure(error))
            return
        }
        let base64String = imageData.base64EncodedString()
        
        // 2. Tạo URL với API Key
        let urlString = "\(baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        // 3. Tạo Request Body (Cấu trúc mà ông đã test thành công trên Postman)
        let jsonRequest: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64String],
                    "features": [
                        ["type": "LABEL_DETECTION", "maxResults": 10]
                    ]
                ]
            ]
        ]
        
        // 4. Cấu hình URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonRequest)
            print("Đang lấy dữ liệu từ Google Vision API")
        } catch {
            completion(.failure(error))
            return
        }
        
        // 5. Thực thi Request và Decode dữ liệu vào Model
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "NoData", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không nhận được dữ liệu từ API"])
                completion(.failure(error))
                return
            }
            
            do {
                // Parse dữ liệu vào Model VisionResponse ông đã cung cấp
                let decodedResponse = try JSONDecoder().decode(VisionResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                // Trường hợp parse lỗi (có thể do cấu hình Model hoặc JSON thay đổi)
                completion(.failure(error))
            }
        }.resume()
    }
}

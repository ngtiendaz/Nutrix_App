//
//  Env.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//
import Foundation

import Foundation

enum AppConfig {
    private static let infoDict: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Không tìm thấy file Info.plist")
        }
        return dict
    }()
    
    // Lấy App ID cho Edamam
    static let edamamAppID: String = {
        return infoDict["APP_ID_EDAMAM"] as? String ?? ""
    }()
    
    // Lấy App Key cho Edamam
    static let edamamAppKey: String = {
        return infoDict["APP_KEY_EDAMAM"] as? String ?? ""
    }()
    
    // Lấy API Key cho Google Vision
    static let visionAPIKey: String = {
        return infoDict["API_KEY_VISION"] as? String ?? ""
    }()
}

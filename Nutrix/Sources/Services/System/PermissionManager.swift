//
//  Untitled.swift
//  Nutrix
//
//  Created by Daz on 23/4/26.
//

import AVFoundation
import UIKit

class PermissionManager {
    static let shared = PermissionManager()
    
    private init() {}
    
    func checkCameraPermission(authorized: @escaping () -> Void, denied: @escaping () -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            authorized()
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        authorized()
                    } else {
                        denied()
                    }
                }
            }
            
        case .denied, .restricted:
            denied()
            
        @unknown default:
            break
        }
    }
    
 
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

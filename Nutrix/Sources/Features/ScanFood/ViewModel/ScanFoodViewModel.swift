//
//  CameraService.swift
//  Nutrix
//
//  Created by Daz on 23/4/26.
//

import AVFoundation
import Foundation
import Combine

class ScanFoodViewModel: NSObject, ObservableObject {
    // Session quản lý luồng dữ liệu từ camera
    @Published var session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var isSetup = false
    
    func checkPermissionAndSetup() {
            if isSetup { return } // Không setup lại nếu đã xong
            
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
            case .authorized:
                setupSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        DispatchQueue.main.async { self.setupSession() }
                    }
                }
            default: break
            }
        }
    func setupSession() {
            guard !isSetup else { return }
            
            session.beginConfiguration()
            
            // Cấu hình Camera sau
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                session.commitConfiguration()
                return
            }

            if session.canAddInput(input) {
                session.addInput(input)
            }

            // THÊM: Phải có Output thì nhiều máy mới chịu lên hình
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }

            session.sessionPreset = .photo
            session.commitConfiguration()
            
            self.isSetup = true
            
            // Chạy session
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                if !self.session.isRunning {
                    self.session.startRunning()
                    print("--- DEBUG: Camera is now RUNNING ---")
                }
            }
        }
    }

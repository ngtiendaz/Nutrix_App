//
//  DiaryViewModel.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//
import Foundation
import Combine
import UIKit

class DiaryViewModel: ObservableObject {
    @Published var isShowingCamera = false
    @Published var isShowingLibrary = false
    @Published var isShowingPermissionAlert = false
    @Published var selectedImage: UIImage?
    
    
    func handleCameraSelection() {
            PermissionManager.shared.checkCameraPermission(
                authorized: {
                    // Đã có quyền -> Mở view camera custom
                    self.isShowingCamera = true
                },
                denied: {
                    // Bị từ chối -> Hiện thông báo dẫn đi Cài đặt
                    self.isShowingPermissionAlert = true
                }
            )
        }
        
    func showLibrary() {
        self.isShowingLibrary = true
    }
}

//
//  AddFoodViewModel.swift
//  Nutrix
//
//  Created by Daz on 16/4/26.
//

import SwiftUI
import PhotosUI
import Foundation
import Combine


class AddFoodViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var isShowingPicker = false // Thống nhất dùng biến này
    @Published var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func showCamera() {
        #if targetEnvironment(simulator)
        print("Camera không khả dụng trên Simulator")
        self.showLibrary()
        #else
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.sourceType = .camera
            self.isShowingPicker = true // Sửa lỗi tên biến ở đây
        }
        #endif
    }
    
    func showLibrary() {
        self.sourceType = .photoLibrary
        self.isShowingPicker = true
    }
}

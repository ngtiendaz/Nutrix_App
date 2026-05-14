//
//  ProfileViewModel.swift
//  Nutrix
//
//  Created by Daz on 5/5/26.
//
import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var weight: String = ""
    @Published var height: String = ""
    // Bổ sung các trường mới
    @Published var age: String = ""
    @Published var gender: String = "Nam"
    @Published var activityLevel: String = "Vừa phải"
    
    @Published var isEditing: Bool = false
    @Published var isUpdating: Bool = false
    
    private var initialData: [String: String] = [:]
    
    // Data cho Picker
    let genders = ["Nam", "Nữ"]
    let activityLevels = ["Ít vận động", "Vừa phải", "Năng động", "Rất năng động"]
    
    func setupFields(user: User?) {
        guard let user = user else { return }
        name = user.name
        weight = user.weight != nil ? "\(user.weight!)" : ""
        height = user.height != nil ? "\(user.height!)" : ""
        age = user.age != nil ? "\(user.age!)" : ""
        gender = user.gender ?? "Nam"
        activityLevel = user.activityLevel ?? "Vừa phải"
        
        initialData = [
            "name": name, "weight": weight, "height": height,
            "age": age, "gender": gender, "activityLevel": activityLevel
        ]
    }
    
    func saveProfile(authService: FirebaseAuthService) {
        let hasChanges = name != initialData["name"] || weight != initialData["weight"] ||
                         height != initialData["height"] || age != initialData["age"] ||
                         gender != initialData["gender"] || activityLevel != initialData["activityLevel"]
        
        if !hasChanges {
            self.isEditing = false
            return
        }
        
        isUpdating = true
        let data: [String: Any] = [
            "name": name,
            "weight": Double(weight) ?? 0.0,
            "height": Double(height) ?? 0.0,
            "age": Int(age) ?? 0,
            "gender": gender,
            "activityLevel": activityLevel
        ]
        
        authService.updateUserProfile(data: data) { [weak self] error in
            DispatchQueue.main.async {
                self?.isUpdating = false
                if error == nil {
                    self?.isEditing = false
                    // Cập nhật lại initialData sau khi lưu thành công
                    self?.setupFields(user: authService.currentUser)
                }
            }
        }
    }
}

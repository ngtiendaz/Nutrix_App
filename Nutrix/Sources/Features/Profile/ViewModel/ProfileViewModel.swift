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
    
    @Published var isEditingBasic: Bool = false   // Cho Tên, Tuổi, Giới tính...
    @Published var isEditingMetrics: Bool = false // Cho Cao, Nặng
    @Published var isUpdating: Bool = false
    
    private var initialData: [String: String] = [:]
    @Published var metricsHistory: [BodyMetrics] = []
    @Published var showHistorySheet: Bool = false
    
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
    
    func saveBasicInfo(authService: FirebaseAuthService, completion: @escaping (Bool) -> Void) {
            let data: [String: Any] = [
                "name": name,
                "age": Int(age) ?? 0,
                "gender": gender,
                "activityLevel": activityLevel
            ]
            
            authService.updateBasicProfile(data: data) { [weak self] error in
                DispatchQueue.main.async {
                    if error == nil {
                        self?.isEditingBasic = false
                        self?.setupFields(user: authService.currentUser)
                        completion(true)
                    } else { completion(false) }
                }
            }
        }
    func saveBodyMetrics(authService: FirebaseAuthService, completion: @escaping (Bool) -> Void) {
            let h = Double(height) ?? 0.0
            let w = Double(weight) ?? 0.0
            
            authService.updateBodyMetrics(height: h, weight: w) { [weak self] error in
                DispatchQueue.main.async {
                    if error == nil {
                        self?.isEditingMetrics = false
                        self?.setupFields(user: authService.currentUser)
                        completion(true)
                    } else { completion(false) }
                }
            }
        }
    func fetchHistory(authService: FirebaseAuthService) {
        authService.fetchBodyMetricsHistory { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let history):
                    var processedHistory = history
                    for i in 0..<processedHistory.count - 1 {
                        let current = processedHistory[i].weight
                        let previous = processedHistory[i+1].weight
                        if previous > 0 {
                            processedHistory[i].weightDiff = current - previous
                            processedHistory[i].percentChange = ((current - previous) / previous) * 100
                        }
                    }
                    self?.metricsHistory = processedHistory
                case .failure(let error):
                    print("Lỗi: \(error.localizedDescription)")
                }
            }
        }
    }
}

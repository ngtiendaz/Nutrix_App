//
//  AppRouter.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation
import Combine
import SwiftUI

enum AppRoot {
    case splash
    case login
    case main
}

class AppRouter: ObservableObject {
    // --- Điều hướng ---
    @Published var currentRoot: AppRoot = .splash
    @Published var diaryPath = NavigationPath()
    @Published var chartPath = NavigationPath()
    @Published var planPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    @Published var activityPath = NavigationPath()
    @Published var selectedTab: Tab = .diary
    
    // --- Trạng thái UI dùng chung ---
    @Published var toast: ToastData? = nil
    @Published var isLoading: Bool = false
    
    // Task quản lý thời gian ẩn Toast
    private var toastWorkItem: DispatchWorkItem?

    // MARK: - Notification Methods
    func showToast(message: String, type: ToastType) {
            toastWorkItem?.cancel()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.toast = ToastData(message: message, type: type)
            }

            let workItem = DispatchWorkItem { [weak self] in
                // Tốc độ ẩn thông báo (0.5s cho mượt mà)
                withAnimation(.easeInOut(duration: 0.5)) {
                    self?.toast = nil
                }
            }
            
            toastWorkItem = workItem
            // CHỈNH TẠI ĐÂY: Tăng từ 2.5 lên 3.5 hoặc 4.0 giây để người dùng kịp đọc
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: workItem)
        }
    
    // MARK: - Loading Methods
    func showLoading() {
            DispatchQueue.main.async {
                // Hiện loading mượt (0.2s)
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isLoading = true
                }
            }
        }

    func hideLoading() {
            DispatchQueue.main.async {
                // CHỈNH TẠI ĐÂY: duration: 0.1 hoặc thậm chí xóa hẳn withAnimation
                // để nó biến mất ngay lập tức khi xong việc
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.isLoading = false
                }
            }
        }
    
    // MARK: - Navigation Logic
    func push(_ destination: AppDestination) {
        switch selectedTab {
        case .diary: diaryPath.append(destination)
        case .chart: chartPath.append(destination)
        case .plan: planPath.append(destination)
        case .profile: profilePath.append(destination)
        case .activity: activityPath.append(destination)
        default: break
        }
    }
    
    func pop() {
        switch selectedTab {
        case .diary: if !diaryPath.isEmpty { diaryPath.removeLast() }
        case .chart: if !chartPath.isEmpty { chartPath.removeLast() }
        case .plan: if !planPath.isEmpty { planPath.removeLast() }
        case .profile: if !profilePath.isEmpty { profilePath.removeLast() }
        case .activity: if !activityPath.isEmpty { activityPath.removeLast() }
        default: break
        }
    }
    
    func changeRoot(to newRoot: AppRoot) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.5)) {
                self.currentRoot = newRoot
            }
        }
    }
    
    func resetAllPaths() {
        DispatchQueue.main.async {
            self.diaryPath = NavigationPath()
            self.chartPath = NavigationPath()
            self.planPath = NavigationPath()
            self.profilePath = NavigationPath()
            self.activityPath = NavigationPath()
            self.selectedTab = .diary
        }
    }
}

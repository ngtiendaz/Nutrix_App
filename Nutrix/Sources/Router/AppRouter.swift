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

            withAnimation(.spring(response: 0.52, dampingFraction: 0.8)) {
                self.toast = ToastData(message: message, type: type)
            }

            let workItem = DispatchWorkItem { [weak self] in
                withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
                    self?.toast = nil
                }
            }

            toastWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2, execute: workItem)
        }
    
    // MARK: - Loading Methods
    func showLoading() {
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.22)) {
                    self.isLoading = true
                }
            }
        }

    func hideLoading() {
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.18)) {
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

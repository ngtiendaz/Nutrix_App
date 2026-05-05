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
    
    @Published var currentRoot: AppRoot = .splash
    
    @Published var diaryPath = NavigationPath()
    @Published var chartPath = NavigationPath()
    @Published var nutritionPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    @Published var settingPath = NavigationPath()
    @Published var selectedTab: Tab = .diary
    
    @Published var toast: ToastData? = nil
    @Published var isLoading: Bool = false
    
    func push(_ destination: AppDestination) {
        switch selectedTab {
        case .diary:
            diaryPath.append(destination)
        case .chart:
            chartPath.append(destination)
        case .nutrition:
            nutritionPath.append(destination)
        case .profile:
            profilePath.append(destination)
        case .setting:
            settingPath.append(destination)
        default:
            break
        }
    }
    
    func pop() {
        switch selectedTab {
        case .diary:
            if !diaryPath.isEmpty { diaryPath.removeLast() }
        case .chart:
            if !chartPath.isEmpty { chartPath.removeLast() }
        case .nutrition:
            if !nutritionPath.isEmpty { nutritionPath.removeLast() }
        case .profile:
            if !profilePath.isEmpty { profilePath.removeLast() }
        case .setting:
            if !settingPath.isEmpty { settingPath.removeLast() }
        default:
            break
        }
    }
    
    func popToRoot() {
        switch selectedTab {
        case .diary:
            diaryPath.removeLast(diaryPath.count)
        case .chart:
            chartPath.removeLast(chartPath.count)
        case .nutrition:
            nutritionPath.removeLast(nutritionPath.count)
        case .profile:
            profilePath.removeLast(profilePath.count)
        case .setting:
            settingPath.removeLast(settingPath.count)
        default:
            break
        }
    }
    
    
    func showToast(message: String, type: ToastType) {
        toast = ToastData(message: message, type: type)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.toast = nil
        }
    }
    func showLoading() {
        print("SHOW LOADING")
          DispatchQueue.main.async {
              self.isLoading = true
          }
      }

      func hideLoading() {
          DispatchQueue.main.async {
              self.isLoading = false
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
            self.nutritionPath = NavigationPath()
            self.profilePath = NavigationPath()
            self.settingPath = NavigationPath()
            self.selectedTab = .diary
        }
    }
}

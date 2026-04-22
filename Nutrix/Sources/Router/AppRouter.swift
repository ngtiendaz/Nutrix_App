//
//  AppRouter.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation
import Combine
import SwiftUI


class AppRouter: ObservableObject {
    @Published var diaryPath = NavigationPath()
    @Published var chartPath = NavigationPath()
    @Published var nutritionPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    @Published var settingPath = NavigationPath()
    @Published var selectedTab: Tab = .diary
    
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
}

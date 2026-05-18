//
//  BottomMenuBar.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//
import SwiftUI

enum Tab: String, CaseIterable {
    case diary = "list.bullet.rectangle"
    case chart = "chart.bar.xaxis"
    case plan = "leaf"
    case activity = "figure.run"
    case profile = "person.crop.circle"
 
  
    
    var title: String{
        switch self {
        case .diary: return "Nhật ký"
        case .chart: return "Thống kê"
        case .plan: return "Lộ trình"
        case .activity: return "Hoạt động"
        case .profile: return "Cá nhân"
        }
    }
    var activeIcon: String {
            if self == .chart {
                return self.rawValue
            }
        if self == .activity {
            return self.rawValue
        }
            return self.rawValue + ".fill"
        }
}
struct BottomMenuBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.App.primary)
                                    .frame(width: 48, height: 36)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Icon: Trắng khi được chọn, Xám khi không chọn
                            Image(systemName: selectedTab == tab ? tab.activeIcon : tab.rawValue)
                                .font(.App.title3)
                                .foregroundColor(selectedTab == tab ? .white : .gray)
                        }
                        .frame(height: 32)
                        
                        Text(tab.title)
                            .font(.App.tiny)
                            .foregroundColor(selectedTab == tab ? Color.App.primary : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.App.menuBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 12)
    }
}

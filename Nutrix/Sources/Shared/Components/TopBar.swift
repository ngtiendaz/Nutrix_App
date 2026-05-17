//
//  TopBar.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
struct TopBar: View {
    @Binding var selectedTab: Tab
    @Binding var selectedDate: Date
    var body: some View {
        HStack(alignment: .center, spacing: 5){
            Text(selectedTab.title).font(.system(size: 32)).fontWeight(.bold)
                .foregroundColor(.black.opacity(0.8))
            Spacer()
            
            if selectedTab == .diary  || selectedTab == .activity {
                DayPicker(selectedDate: $selectedDate)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            
        }.animation(.easeInOut, value: selectedTab)
    }
}


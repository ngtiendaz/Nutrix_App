//
//  TopBar.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
struct TopBar: View {
    @Binding var selectedTab: Tab
    @State private var selectedDate = Date()
    var body: some View {
        HStack(alignment: .center, spacing: 10){
            Text(selectedTab.title).font(.system(size: 28)).fontWeight(.bold)
                .foregroundColor(.black.opacity(0.8))
            Spacer()
            
            if selectedTab == .diary {
                DayPicker(selectedDate: $selectedDate)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            
        }.padding(.horizontal,20)
            .padding(.bottom, 5)
            .animation(.easeInOut, value: selectedTab)
    }
}


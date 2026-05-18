//
//  NutritionView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
struct Barcode: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        ZStack {
            // Nền và xử lý chạm ngoài để ẩn bàn phím
            Color.App.background
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    TopBar(selectedTab: .constant(.chart), selectedDate: $selectedDate)
                    
                }
            }.padding(.horizontal, 12)
            
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

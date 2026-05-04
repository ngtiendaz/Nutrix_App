//
//  ChartView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
struct ChartView: View {
    var body: some View {
        ZStack{
            Color.App.background
            Button("Test gọi Edamam") {
                Task {
                    let service = EdamamService()
                    // Giả sử đây là nhãn nhận được từ Google Vision
                    await service.fetchNutrition(for: "Pizza")
                }
            }
        }
    }
}

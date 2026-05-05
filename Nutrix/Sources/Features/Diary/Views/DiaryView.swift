//
//  DiaryView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI

struct DiaryView: View {
    @EnvironmentObject var router: AppRouter
    @State private var isShowingAddFood = false
    @State private var animateButton = false
    
    let sampleData = DailyNutrition(
            userId: "123",
            date: "2026-04-16",
            totalCalories: 1200,
            totalProtein: 45,
            totalCarbs: 150,
            totalFat: 30,
            totalWater: 1.5
        )
    
    var body: some View {
        ZStack(alignment: .bottomTrailing){
            ScrollView{
                VStack(alignment: .leading, spacing: 10){
                    NutritionGoalCard(data: sampleData)
                    WaterGoalCard(currentWater: sampleData.totalWater)
                    Text("Hôm nay").font(Font.largeTitle.bold()).foregroundColor(.black)
                    Spacer(minLength: 100)
                } .padding(.horizontal,12)
            }
            .background(Color.App.background)
            
                plusButtonView.scaleEffect(animateButton ? 1.0 : 0.5)
                .opacity(animateButton ? 1.0 : 0)
            
        }.onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    animateButton = true
                }
        }
        .onDisappear {
            animateButton = false
        }
        .sheet(isPresented: $isShowingAddFood) {
            OptionDetail()
                .environmentObject(router)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    var plusButtonView: some View {
            Button {
                isShowingAddFood = true
            } label: {
                Image(systemName: "fork.knife")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.App.primary)
                    .clipShape(Circle())
                    .shadow(color: Color.App.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 10)
        }
}

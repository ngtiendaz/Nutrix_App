//
//  ActivityCard.swift
//  Nutrix
//
//  Created by Daz on 15/5/26.
//

import SwiftUI
struct ActivityCard: View {
    let log: UserActivityLog
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.App.primaryLight)
                    .frame(width: 54, height: 54)
                
                Image(systemName: log.activityType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color.App.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(log.activityType.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                
                HStack(spacing: 12) {
                    Label("\(Int(log.durationMinutes)) phút", systemImage: "clock")
                    Label("\(Int(log.caloriesBurned)) kcal", systemImage: "flame")
                }
                .font(.system(size: 13))
                .foregroundColor(Color.App.lightGray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.App.secondaryBackground)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
    }
}

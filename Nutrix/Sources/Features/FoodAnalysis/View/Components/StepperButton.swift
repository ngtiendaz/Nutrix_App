//
//  Untitled.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//
import SwiftUI

struct StepperButton: View {
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.App.title).foregroundColor(Color.App.primary)
                .frame(width: 44, height: 44).background(Color.App.primaryLight).clipShape(Circle())
        }
    }
}

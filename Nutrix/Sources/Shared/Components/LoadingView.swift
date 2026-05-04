//
//  LoadingView.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//

import SwiftUI

struct LoadingView: View {
    let isLoading: Bool

    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .allowsHitTesting(true) // khóa toàn bộ UI

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
            .transition(.opacity)
        }
    }
}

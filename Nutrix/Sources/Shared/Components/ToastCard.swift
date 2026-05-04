//
//  ToastCard.swift
//  Nutrix
//
//  Created by Daz on 4/5/26.
//
import SwiftUI

struct ToastView: View {
    let toast: ToastData?

    var body: some View {
        if let toast = toast {
            VStack {
                Text(toast.message)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        toast.type == .success ? Color.green : Color.red
                    )
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 12)
                    .padding(.top, 50) // cách tai thỏ nhẹ nhàng
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea(edges: .top)
        }
    }
}

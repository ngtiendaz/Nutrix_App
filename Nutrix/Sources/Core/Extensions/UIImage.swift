//
//  UIImage.swift
//  Nutrix
//
//  Created by Daz on 3/5/26.
//

import UIKit

// Giúp SwiftUI hiểu được khi nào UIImage thay đổi để mở Sheet
extension UIImage: Identifiable {
    public var id: Int {
        return self.hash
    }
}

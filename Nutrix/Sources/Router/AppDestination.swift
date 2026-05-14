//
//  AppDe.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import Foundation
import Combine
import UIKit


enum AppDestination: Hashable {
    case cameraScan
    case libraryPicker
    /// `mealDate`: ngày nhật ký đang xem (để cập nhật đúng document meal trên Firestore).
    case foodDetail(Food)
}

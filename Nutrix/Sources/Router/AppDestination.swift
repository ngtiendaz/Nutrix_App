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
    case foodDetail(Food)
    case nutritionPlan(NutritionPlan)
}

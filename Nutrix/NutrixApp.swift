//
//  NutrixApp.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
import CoreData

@main
struct NutrixApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var router = AppRouter()

    var body: some Scene {
        WindowGroup {
          ContentView().environment(\.managedObjectContext, persistenceController.container.viewContext).environmentObject(router)
        }
    }
}

//
//  ContentView.swift
//  Nutrix
//
//  Created by Daz on 15/4/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var router: AppRouter
    var body: some View {
       MainView().environmentObject(router)
        // thêm logic login để vào main
    }
}

#Preview {
    ContentView().environmentObject(AppRouter())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

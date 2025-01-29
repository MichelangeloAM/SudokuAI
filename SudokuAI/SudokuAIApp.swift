//
//  SudokuAIApp.swift
//  SudokuAI
//
//  Created by Michelangelo Amoruso Manzari on 29/01/25.
//

import SwiftUI

@main
struct SudokuAIApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

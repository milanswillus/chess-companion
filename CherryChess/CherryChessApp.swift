//
//  CherryChessApp.swift
//  CherryChess
//
//  Created by milxn on 12.05.26.
//

import SwiftUI

@main
struct CherryChessApp: App {
    init() {
        // Default the app language to the user's device/region on first launch,
        // so onboarding already appears in the right language.
        AppLanguage.registerDeviceDefault()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//
//  SwimTrackerWApp.swift
//  SwimTrackerW Watch App
//
//  Created by Nello Benini on 2025-08-09.
//

import WatchKit
import Foundation
import SwiftUI


@main
struct SwimTrackerW_Watch_AppApp: App {
    
    @StateObject var workoutManager = WorkoutManager()
    
    @WKApplicationDelegateAdaptor(ExtensionDelegate.self) var delegate

    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            // Ta bort NavigationView här - StartView har sin egen NavigationStack
            StartView()
                .environmentObject(workoutManager)
        }
    }
}

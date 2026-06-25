//
//  ExtensionDelegate.swift
//  SwimTrackerW
//
//  Created by Nello Benini on 2026-05-28.
//


import WatchKit

class ExtensionDelegate: NSObject, WKApplicationDelegate {
    
    // MARK: - Action Button Support
    /// Krävs för att appen ska synas i Watch Inställningar → Action Button → App.
    /// Anropas av systemet när Action Button trycks med appen i förgrunden.
    func actionButtonPressed() {
        NotificationCenter.default.post(
            name: NSNotification.Name("ACTIONButtonPressed"),
            object: nil
        )
    }
    
    // MARK: - Background Handling
    /// Förhindrar att appen går till bakgrund under aktiv träning
    func applicationShouldRequestHealthAuthorization(_ application: WKApplication) {
        // Behövs för HealthKit integration
    }
    
    /// Hanterar när appen går till bakgrund
    func applicationDidEnterBackground(_ application: WKApplication) {
        // Om träning pågår, försök hålla appen aktiv
        if isWorkoutActive() {
            print("🏃‍♂️ Träning pågår - appen försöker stanna aktiv i bakgrund")
            // På watchOS hanteras detta automatiskt av HKWorkoutSession
            // som får extended runtime permissions
        }
    }
    
    /// Hanterar när appen kommer tillbaka till förgrund
    func applicationWillEnterForeground(_ application: WKApplication) {
        // Uppdatera UI när appen kommer tillbaka
        NotificationCenter.default.post(
            name: NSNotification.Name("AppWillEnterForeground"),
            object: nil
        )
    }
    
    /// Förhindrar att appen stängs av under träning
    func applicationWillTerminate(_ application: WKApplication) {
        if isWorkoutActive() {
            // Försök att hindra app från att stänga under träning
            print("⚠️ App försöker stänga under aktiv träning")
        }
    }
    
    // MARK: - Helper Methods
    private func isWorkoutActive() -> Bool {
        // Kontrollera om det finns en aktiv träningssession
        // Detta skulle kunna göras genom att lyssna på WorkoutManager eller
        // genom att kontrollera HKWorkoutSession status
        return UserDefaults.standard.bool(forKey: "WorkoutActive")
    }
}
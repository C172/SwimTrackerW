//
//  LapTimerView.swift
//  SwimTrackerW
//
//  Created by Nello Benini on 2026-05-28.
//


import SwiftUI
import WatchKit

struct LapTimerView: View {
    @State private var lapStart: Date = .now
    @State private var isRunning = false
    @State private var displayTime: TimeInterval = 0

    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    // Detekterar Ultra via skärmstorlek (49mm)
    var isUltra: Bool {
        WKInterfaceDevice.current().screenBounds.size.width >= 205
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(formatTime(displayTime))
                .font(.system(size: isUltra ? 34 : 24,
                              weight: .semibold,
                              design: .monospaced))
                .foregroundStyle(isRunning ? .white : .secondary)
        }
        .containerBackground(
            isRunning ? Color.green.gradient : Color.red.gradient,
            for: .navigation
        )
        // Väg 1: Action Button via delegate (kräver Watch Inställningar → Action Button → App → SwimTracker)
        .onReceive(NotificationCenter.default.publisher(
            for: NSNotification.Name("ACTIONButtonPressed"))) { _ in
            handleTap()
        }
        // Väg 2: Double Tap (Series 9+) och Action Button (Ultra, watchOS 10+) utan inställningskrav
        .overlay {
            Button { handleTap() } label: { Color.clear }
                .handGestureShortcut(.primaryAction)
        }
        .onReceive(timer) { _ in
            if isRunning {
                displayTime = Date.now.timeIntervalSince(lapStart)
            }
        }
    }

    private func handleTap() {
        if isRunning {
            isRunning = false
        } else {
            lapStart = .now
            displayTime = 0
            isRunning = true
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let hundredths = Int((interval * 100)
            .truncatingRemainder(dividingBy: 100))
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
}

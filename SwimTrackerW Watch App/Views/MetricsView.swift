//
//  MetricsView.swift
//  MyWorkouts
//
//  Created by Nello Benini on 2025-03-12.
//

import SwiftUI

struct MetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var isPaused = false

    var isUltra: Bool {
        WKInterfaceDevice.current().screenBounds.size.width >= 205
    }

    var body: some View {
        TimelineView(
            MetricsTimelineSchedule(
                from: workoutManager.builder?.startDate ?? Date()
            )
        ) { context in
            VStack(alignment: .leading) {
                // Paus status
                if !workoutManager.running && workoutManager.isSessionActive {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.yellow)
                        Text("PAUSED")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    .padding(.bottom,4)
                }

                // Tid
                ElapsedTimeView(
                    elapsedTime: workoutManager.builder?.elapsedTime ?? 0,
                    showSubseconds: context.cadence == .live
                ).foregroundColor(workoutManager.running ? Color.yellow : Color.gray)

                // Puls + Pulszon
                HStack(alignment: .center, spacing: 8) {
                    Text(
                        workoutManager.heartRate
                            .formatted(
                                .number.precision(.fractionLength(0))
                            )

                    )
                    .foregroundColor(.orange)

                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundColor(.red)

                    HeartRateZoneViewSimple(currentHeartRate: workoutManager.heartRate)
                }

                Text("\(Int( workoutManager.distance)) m")
                    .fontWeight(.regular)
                    .foregroundColor(.white)

                // Split per 100m
                if let last = workoutManager.lastSplitTime {
                    SplitView(last: last)
                }

                // Laptimer visas bara på Ultra
                 if isUltra {
                     LapTimerView()
                 }

            }
            .font(.system(.title, design: .rounded)
                .monospacedDigit()
                .lowercaseSmallCaps()
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .ignoresSafeArea(edges: .bottom)
            .scenePadding()
            
        }
       
    }
    
    
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        MetricsView()
            .environmentObject(WorkoutManager.preview)
    }
}

private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date

    init(from startDate: Date) {
        self.startDate = startDate
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> PeriodicTimelineSchedule.Entries {
        PeriodicTimelineSchedule(
            from: self.startDate,
            by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0)
        ).entries(
            from: startDate,
            mode: mode
        )
    }
}

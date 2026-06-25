//
//  StartView.swift
//  SwimTrackerW
//
//  Created by Nello Benini on 2025-06-18.
//

import SwiftUI
import HealthKit

struct StartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var poolLength = 25
    @State private var navigationPath = NavigationPath()
    @State private var isStartingWorkout = false

    let step = 1
    let range = 1...50

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 12) {
                HStack {
                    NavigationLink(destination: SettingsView()) {
                        Text("Setup")
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }

                Spacer()

                Text("Pool length(m)")
                    .font(.title3)

                Stepper(value: $poolLength, in: range, step: step) {
                    Text("\(poolLength)")
                }

                Button("Start") {
                    startWorkoutAndNavigate()
                }
                .font(.title3)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .padding()
                .background(isStartingWorkout ? Color.gray : Color.blue)
                .cornerRadius(10)
                .disabled(isStartingWorkout)
                .buttonStyle(PlainButtonStyle())

                if isStartingWorkout {
                    ProgressView("Start workout...")
                        .font(.caption)
                }
            }
            .padding()
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "session":
                    SessionPagingView(navigationPath: $navigationPath)
                case "summary":
                    SummaryView(navigationPath: $navigationPath)
                default:
                    EmptyView()
                }
            }
            .onAppear {
                workoutManager.requestAuthorization()
                if workoutManager.locationPermissionStatus == .notDetermined {
                    workoutManager.requestLocationPermission()
                }
            }
        }
    }

    private func startWorkoutAndNavigate() {
        isStartingWorkout = true
        workoutManager.lapLength = Double(poolLength)
        workoutManager.selectedWorkout = .swimming
        workoutManager.distance = 0

        workoutManager.startWorkout { success in
            isStartingWorkout = false
            if success {
                print("🎯 Workout started successfully, navigating to session")
                navigationPath.append("session")
            } else {
                print("❌ Failed to start workout, staying on StartView")
            }
        }
    }
}

#Preview {
    StartView()
        .environmentObject(WorkoutManager())
}

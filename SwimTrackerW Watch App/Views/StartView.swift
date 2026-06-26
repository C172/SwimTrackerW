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

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 10) {

                Text("Pool")
                    .font(.title3)

                HStack(spacing: 16) {
                    poolLengthButton(length: 25)
                    poolLengthButton(length: 50)
                }

                NavigationLink(destination: CustomPoolLengthView(poolLength: $poolLength)) {
                    Text(isCustomLength ? "Anpassad: \(poolLength) m" : "Anpassad längd")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Text("Setup")
                    }
                    .buttonStyle(.plain)
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

    private var isCustomLength: Bool {
        poolLength != 25 && poolLength != 50
    }

    @ViewBuilder
    private func poolLengthButton(length: Int) -> some View {
        Button {
            poolLength = length
        } label: {
            Text("\(length) m")
                .font(.title3)
                .foregroundColor(poolLength == length ? .white : .blue)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .padding()
                .background(poolLength == length ? Color.blue : Color.blue.opacity(0.15))
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
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

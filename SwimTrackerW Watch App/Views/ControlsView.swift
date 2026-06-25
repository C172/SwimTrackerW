//
//  ControlsView.swift
//  MyWorkouts
//
//  Created by Nello Benini on 2025-03-12.
//

import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var navigationPath: NavigationPath

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 40) {
                VStack {
                    Button {
                        workoutManager.showingDiscardAlert = true
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.red)
                    .font(.title2)
                    Text("Discard")
                        .font(.caption)
                }

                VStack {
                    Button {
                        workoutManager.togglePause()
                    } label: {
                        Image(systemName: workoutManager.running ? "pause" : "play")
                    }
                    .tint(.yellow)
                    .font(.title2)
                    Text(workoutManager.running ? "Pause" : "Resume")
                        .font(.caption)
                }
            }

            VStack {
                Button {
                    workoutManager.endWorkout()
                } label: {
                    Image(systemName: "checkmark")
                }
                .tint(.green)
                .font(.title2)
                Text("End")
                    .font(.caption)
            }
        }
        .alert("Discard Workout", isPresented: $workoutManager.showingDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                workoutManager.discardWorkout()
                // Navigate immediately – the delete + resetAfterDiscard() runs
                // asynchronously and finishes well after the pop animation (~250 ms).
                navigationPath.removeLast(navigationPath.count)
            }
        } message: {
            Text("Are you sure you want to discard this workout? This action cannot be undone.")
        }
        // Navigate to summary as soon as HealthKit confirms the workout is saved.
        .onChange(of: workoutManager.workout) { _, workout in
            if workout != nil {
                navigationPath.append("summary")
            }
        }
    }
}

#Preview {
    ControlsView(navigationPath: .constant(NavigationPath()))
        .environmentObject(WorkoutManager())
}

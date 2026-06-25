//
//  SessionPagingView.swift
//  MyWorkouts
//
//  Created by Nello Benini on 2025-03-12.
//

import SwiftUI
import WatchKit

struct SessionPagingView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var navigationPath: NavigationPath

    @State private var selection: Tab = .metrics

    enum Tab {
        case controls, metrics
    }

    var body: some View {
        TabView(selection: $selection) {
            ControlsView(navigationPath: $navigationPath).tag(Tab.controls)
            MetricsView().tag(Tab.metrics)
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: workoutManager.running) { _, _ in
            displayMetricsView()
        }
        .tabViewStyle(
            PageTabViewStyle(indexDisplayMode: isLuminanceReduced ? .never : .automatic)
        )
        .onChange(of: isLuminanceReduced) { _, _ in
            displayMetricsView()
        }
    }

    private func displayMetricsView() {
        withAnimation { selection = .metrics }
    }
}

#Preview("SessionPaging") {
    SessionPagingView(navigationPath: .constant(NavigationPath()))
        .environmentObject(WorkoutManager())
}

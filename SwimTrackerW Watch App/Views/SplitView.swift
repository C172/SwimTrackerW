//
//  SplitView.swift
//  MyWorkouts
//
//  Created by Nello Benini on 2026-08-25.
//

import SwiftUI

struct SplitView: View {
    let last: TimeInterval

    var body: some View {
        HStack(spacing: 4) {
            Text(formatSplit(last))
                .foregroundStyle(.cyan)
        }
        .font(.system(.title, design: .rounded).monospacedDigit())
        .fixedSize()
    }

    private func formatSplit(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        let h = Int((t * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%d:%02d.%d", m, s, h)
    }
}

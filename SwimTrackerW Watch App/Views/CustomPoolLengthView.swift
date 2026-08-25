//
//  CustomPoolLengthView.swift
//  SwimTrackerW
//
//  Created by Nello Benini on 2025-06-18.
//

import SwiftUI

struct CustomPoolLengthView: View {
    @Binding var poolLength: Int
    @Environment(\.dismiss) private var dismiss

    let step = 1
    let range = 1...50

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Custom length")
                .font(.headline)

            Stepper(value: $poolLength, in: range, step: step) {
                Text("\(poolLength) m")
                    .font(.title3)
            }

            Spacer()

            Button("Done") {
                dismiss()
            }
            .font(.title3)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .navigationTitle("Pool")
    }
}

#Preview {
    NavigationStack {
        CustomPoolLengthView(poolLength: .constant(25))
    }
}

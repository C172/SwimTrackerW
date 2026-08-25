//
//  SettingsView.swift
//  MyWorkouts
//
//  Created by Nello Benini on 2025-03-14.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("userAge") private var userAge: Int = 30
    @AppStorage("restingHeartRate") private var restingHeartRate: Int = 60
    @AppStorage("maxHeartRate") private var maxHeartRate: Int = 190
    @AppStorage("useCustomMaxHR") private var useCustomMaxHR: Bool = false
    
    @State private var showingAgeInput = false
    @State private var showingRestingHRInput = false
    @State private var showingMaxHRInput = false
    
    // Beräknad max puls baserat på ålder: 220 - (0.7 * ålder)
    //https://traningslara.se/vilken-formel-ar-bast-for-att-uppskatta-sin-maxpuls/
    private var calculatedMaxHeartRate: Int {
        208 - Int(0.7 * Double(userAge))
    }
    
    // Faktisk max puls som används för pulszoner
    private var effectiveMaxHeartRate: Int {
        useCustomMaxHR ? maxHeartRate : calculatedMaxHeartRate
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Userdata") {
                    // Ålder
                    HStack {
                        Text("Age")
                        Spacer()
                        Button("\(userAge) years") {
                            showingAgeInput = true
                        }
                        .foregroundColor(.blue)
                    }
                    
                    // Vilopuls
                    HStack {
                        Text("HR Resting")
                        Spacer()
                        Button("\(restingHeartRate) bpm") {
                            showingRestingHRInput = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section("Max HR") {
                    // Använd beräknad eller anpassad max puls
                    Toggle("Custom max HR", isOn: $useCustomMaxHR)

                    HStack {
                        Text(useCustomMaxHR ? "Your max HR" : "Computed max HR")
                        Spacer()
                        if useCustomMaxHR {
                            Button("\(maxHeartRate) bpm") {
                                showingMaxHRInput = true
                            }
                            .foregroundColor(.blue)
                        } else {
                            Text("\(calculatedMaxHeartRate) bpm")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("HR Zones") {
                    HeartRateZonesPreview(
                        restingHR: restingHeartRate,
                        maxHR: effectiveMaxHeartRate
                    )
                }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAgeInput) {
            NumberInputSheet(
                title: "Your age",
                value: $userAge,
                range: 15...100,
                unit: "years"
            )
        }
        .sheet(isPresented: $showingRestingHRInput) {
            NumberInputSheet(
                title: "Your resting HR",
                value: $restingHeartRate,
                range: 40...100,
                unit: "bpm"
            )
        }
        .sheet(isPresented: $showingMaxHRInput) {
            NumberInputSheet(
                title: "Your max HR",
                value: $maxHeartRate,
                range: 150...250,
                unit: "bpm"
            )
        }
    }
}

// Vy för att visa pulszoner som förhandsvisning
struct HeartRateZonesPreview: View {
    let restingHR: Int
    let maxHR: Int

    private var zones: HeartRateZones {
        HeartRateZones(restingHeartRate: restingHR, maxHeartRate: maxHR)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(HeartRateZone.allCases.enumerated()), id: \.offset) { _, zone in
                let range = zones.range(for: zone)
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(zone.color)
                        .frame(width: 20, height: 16)
                    Text(zone.description)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(range.lowerBound)–\(range.upperBound)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Enkel input-sheet för numeriska värden
struct NumberInputSheet: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempValue: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(title)
                    .font(.headline)
                
                TextField("Value", text: $tempValue)
                    //.textFieldStyle(.roundedBorder)
                    .onAppear {
                        tempValue = String(value)
                    }
                
                Text("\(range.lowerBound) - \(range.upperBound) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let newValue = Int(tempValue), 
                           range.contains(newValue) {
                            value = newValue
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}



#Preview {
    SettingsView()
}

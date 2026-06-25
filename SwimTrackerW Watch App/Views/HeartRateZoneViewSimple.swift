//
//  HeartRateZoneView.swift
//  MyWorkouts
//
//  Created by Nello Benini on 2025-03-14.
//

import SwiftUI

struct HeartRateZoneViewSimple: View {
    let currentHeartRate: Double
    @AppStorage("restingHeartRate") private var restingHeartRate: Int = 60
    @AppStorage("maxHeartRate") private var maxHeartRate: Int = 190
    @AppStorage("useCustomMaxHR") private var useCustomMaxHR: Bool = false
    @AppStorage("userAge") private var userAge: Int = 30
    
    // Beräknad max puls baserat på ålder
    private var calculatedMaxHeartRate: Int {
        208 - Int(0.7 * Double(userAge))
    }
    
    // Faktisk max puls som används
    private var effectiveMaxHeartRate: Int {
        useCustomMaxHR ? maxHeartRate : calculatedMaxHeartRate
    }
    
    private var heartRateZones: HeartRateZones {
        HeartRateZones(restingHeartRate: restingHeartRate, maxHeartRate: effectiveMaxHeartRate)
    }
    
    private var currentZone: HeartRateZone? {
        heartRateZones.zone(for: Int(currentHeartRate))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let zone = currentZone {
                // Kompakt zonvisning
                HStack(spacing: 8) {
//                    // Färgindikator
//                    RoundedRectangle(cornerRadius: 3)
//                        .fill(zone.color)
//                        .frame(width: 24, height: 16)
                    
                    // Zontext
                    Text(zone.displayNameShort)
                        //.font(.caption)
                        //.fontWeight(.bold)
                        .foregroundColor(zone.color)
                        .font(.system(.title, design: .rounded)
                            .monospacedDigit()
                            .lowercaseSmallCaps()
                        )
                    Spacer()
                }
                
//                // Pulszon-bar (enkel visualisering)
//                HeartRateZoneBarSimple(
//                    currentHeartRate: Int(currentHeartRate),
//                    heartRateZones: heartRateZones,
//                    currentZone: zone
//                )
            } else {
                // Fallback när puls är utanför zonerna
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.gray)
                        .frame(width: 24, height: 16)
                    
                    Text("--")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
            }
        }
    }
}

struct HeartRateZoneBarSimple: View {
    let currentHeartRate: Int
    let heartRateZones: HeartRateZones
    let currentZone: HeartRateZone
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(HeartRateZone.allCases, id: \.self) { zone in
                let isCurrentZone = zone == currentZone
                let range = heartRateZones.range(for: zone)
                
                Rectangle()
                    .fill(isCurrentZone ? zone.color : zone.color.opacity(0.3))
                    .frame(height: 8)
                    .overlay(
                        Rectangle()
                            .stroke(isCurrentZone ? zone.color : Color.clear, lineWidth: 1)
                    )
                    .scaleEffect(y: isCurrentZone ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isCurrentZone)
            }
        }
        .frame(height: 12)
    }
}

#Preview {
    VStack(spacing: 20) {
        HeartRateZoneViewSimple(currentHeartRate: 140)
        HeartRateZoneViewSimple(currentHeartRate: 165)
        HeartRateZoneViewSimple(currentHeartRate: 185)
    }
    .padding()
    .background(Color.black)
}

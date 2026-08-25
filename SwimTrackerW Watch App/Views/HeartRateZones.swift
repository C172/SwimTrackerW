//
//  HeartRateZones.swift
//  MyWorkouts
//
//  Created by Nello Benini on 2025-03-14.
//

import SwiftUI

// MARK: - Pulszons-logik
enum HeartRateZone: Int, CaseIterable {
    case zone1 = 1
    case zone2 = 2
    case zone3 = 3
    case zone4 = 4
    case zone5 = 5
    
    var displayName: String {
        switch self {
        case .zone1: return "Zone 1"
        case .zone2: return "Zone 2"
        case .zone3: return "Zone 3"
        case .zone4: return "Zone 4"
        case .zone5: return "Zone 5"
        }
    }

    var displayNameShort: String {
        switch self {
        case .zone1: return "z1"
        case .zone2: return "z2"
        case .zone3: return "z3"
        case .zone4: return "z4"
        case .zone5: return "z5"
        }
    }

    var description: String {
        switch self {
        case .zone1: return "Recovery"
        case .zone2: return "Aerobic"
        case .zone3: return "Tempo"
        case .zone4: return "Threshld"
        case .zone5: return "Anerobic"
        }
    }
    
    var color: Color {
        switch self {
        case .zone1: return .gray
        case .zone2: return .blue
        case .zone3: return .green
        case .zone4: return .orange
        case .zone5: return .red
        }
    }
    
    // Procent av HRR (Heart Rate Reserve)
    var intensityRange: ClosedRange<Double> {
        switch self {
        case .zone1: return 0.50...0.60
        case .zone2: return 0.60...0.70
        case .zone3: return 0.70...0.80
        case .zone4: return 0.80...0.90
        case .zone5: return 0.90...1.00
        }
    }
}

struct HeartRateZones {
    let restingHeartRate: Int
    let maxHeartRate: Int

    // Vid simning är pulsen ~10 bpm lägre för samma ansträngning
    private let swimmingOffset = 10

    // Heart Rate Reserve (HRR)
    private var heartRateReserve: Int {
        maxHeartRate - restingHeartRate
    }

    // Beräkna pulsintervall för en specifik zon
    func range(for zone: HeartRateZone) -> ClosedRange<Int> {
        let lower = restingHeartRate + Int(Double(heartRateReserve) * zone.intensityRange.lowerBound) - swimmingOffset
        let upper = restingHeartRate + Int(Double(heartRateReserve) * zone.intensityRange.upperBound) - swimmingOffset
        return lower...upper
    }

    // Bestäm vilken zon en given puls tillhör
    func zone(for heartRate: Int) -> HeartRateZone? {
        for zone in HeartRateZone.allCases {
            if range(for: zone).contains(heartRate) {
                return zone
            }
        }
        return HeartRateZone.zone1
    }
}

//
//  SwimTrackerW_Watch_AppTests.swift
//  SwimTrackerW Watch AppTests
//
//  Created by Nello Benini on 2026-09-08.
//

import Testing
@testable import SwimTrackerW_Watch_App
import Foundation

struct SwimTrackerW_Watch_AppTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    @Suite("Split-beräkning i WorkoutManager")
    struct WorkoutManagerSplitTests {
        @Test("Beräkna 100m split i 25m bassäng")
        func testSplit25mPool() async throws {
            let manager = WorkoutManager()
            manager.lapLength = 25
            let start = Date()
            // Simulera fyra längder á 25s, bör ge split = 100
            manager.recordLap(at: start)
            manager.recordLap(at: start.addingTimeInterval(25))
            manager.recordLap(at: start.addingTimeInterval(50))
            manager.recordLap(at: start.addingTimeInterval(100))
            let split = manager.lastLapTime
            #expect(split != nil && abs(split! - 100) < 0.001, "Felaktig split för 4x25m")
        }
    
        @Test("Beräkna 100m split i 50m bassäng")
        func testSplit50mPool() async throws {
            let manager = WorkoutManager()
            manager.lapLength = 50
            let start = Date()
            // Simulera två längder á 30s, bör ge split = 60
            manager.recordLap(at: start)
            manager.recordLap(at: start.addingTimeInterval(60))
            let split = manager.lastLapTime
            #expect(split != nil && abs(split! - 60) < 0.001, "Felaktig split för 2x50m")
        }
    }

}

//
//  WorkoutManager.swift
//  SwimTrackerW
//
//  Created by Nello Benini on 2025-08-10.
//

import Foundation
import HealthKit
import WatchKit
import CoreLocation

class WorkoutManager: NSObject, ObservableObject {
    @Published var lapLength: Double = 25.0
    @Published var isSessionActive: Bool = false
    @Published var showingDiscardAlert: Bool = false
    @Published var workoutLocation: CLLocation?
    @Published var locationName: String?
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var running = false
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var workout: HKWorkout?
    @Published var waterTemperature: Double = 0
    @Published var splitTimes: [TimeInterval] = []
    @Published var lastSplitTime: TimeInterval? = nil
    var bestSplitTime: TimeInterval? { splitTimes.min() }

    private var lastSplitDistance: Double = 0
    private var lastSplitDate: Date = Date()

    var selectedWorkout: HKWorkoutActivityType?

    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?

    private var startWorkoutCompletion: ((Bool) -> Void)?
    private var isDiscarding = false

    private let locationManager = CLLocationManager()
    private var hasLoggedStartLocation = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Location

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    private func logWorkoutStartLocation() {
        guard locationPermissionStatus == .authorizedWhenInUse ||
              locationPermissionStatus == .authorizedAlways else { return }
        guard !hasLoggedStartLocation else { return }
        locationManager.requestLocation()
    }

    private func stopLocationTracking() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Pool Location Route

    private func savePoolLocationRoute() {
        guard let location = workoutLocation, let savedWorkout = workout else { return }

        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        routeBuilder.insertRouteData([location]) { success, error in
            guard success else {
                print("❌ Failed to insert route data: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            routeBuilder.finishRoute(with: savedWorkout, metadata: nil) { route, error in
                if route != nil {
                    print("📍 Pool route saved: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                } else {
                    print("❌ Failed to save pool route: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }

    // MARK: - Workout Control

    func startWorkout(completion: @escaping (Bool) -> Void) {
        guard let workoutType = selectedWorkout else { completion(false); return }
        guard !isSessionActive else { completion(false); return }

        workout = nil   // clear stale value from previous session

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .indoor

        if workoutType == .swimming {
            configuration.swimmingLocationType = .pool
            configuration.lapLength = HKQuantity(unit: .meter(), doubleValue: lapLength)
        }

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            session?.delegate = self
            builder?.delegate = self

            // Completion is called from the delegate once the session reaches .running,
            // ensuring isSessionActive/running are true before navigation fires.
            startWorkoutCompletion = completion

            let startDate = Date()
            session?.startActivity(with: startDate)

            builder?.beginCollection(withStart: startDate) { success, error in
                if !success {
                    DispatchQueue.main.async {
                        print("❌ beginCollection failed: \(error?.localizedDescription ?? "Unknown")")
                        self.startWorkoutCompletion?(false)
                        self.startWorkoutCompletion = nil
                    }
                }
            }

            // Fallback: if the .running delegate callback is unexpectedly slow
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                guard self.startWorkoutCompletion != nil else { return }
                print("⚠️ Running-state timeout – assuming success")
                self.isSessionActive = true
                self.running = true
                self.workoutLocation = nil
                self.logWorkoutStartLocation()
                self.startWorkoutCompletion?(true)
                self.startWorkoutCompletion = nil
            }

        } catch {
            print("❌ Error creating workout session: \(error.localizedDescription)")
            startWorkoutCompletion = nil
            completion(false)
        }
    }

    func endWorkout() {
        guard isSessionActive else { return }
        stopLocationTracking()
        session?.end()
    }

    func discardWorkout() {
        guard isSessionActive else { return }

        isDiscarding = true
        stopLocationTracking()

        // session.end() triggers watchOS auto-save for swimming workouts.
        // The .ended delegate path below handles the save → immediate delete.
        session?.end()

        // Safety net: if delegate never fires, force a reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self, self.isDiscarding else { return }
            print("⚠️ Discard timeout – forcing reset")
            Task { @MainActor [weak self] in self?.resetAfterDiscard() }
        }
    }

    private func resetAfterDiscard() {
        isDiscarding = false
        selectedWorkout = nil
        builder = nil
        session = nil
        workout = nil
        workoutLocation = nil
        locationName = nil
        hasLoggedStartLocation = false
        activeEnergy = 0
        averageHeartRate = 0
        heartRate = 0
        distance = 0
        waterTemperature = 0
        splitTimes = []
        lastSplitTime = nil
        lastSplitDistance = 0
        running = false
        isSessionActive = false
        showingDiscardAlert = false
        
        // Säkerställ att träningsläget stängs av vid avbrott
        setWorkoutActiveState(false)
    }

    // MARK: - Pause / Resume

    func pause()  { session?.pause() }
    func resume() { session?.resume() }
    func togglePause() {
        running ? pause() : resume()
    }

    // MARK: - HealthKit Authorization

    func requestAuthorization() {
        let typesToShare: Set = [
            HKQuantityType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!,
            HKQuantityType.quantityType(forIdentifier: .waterTemperature)!,
            HKSeriesType.workoutRoute()
        ]
        let typesToRead: Set = [
            HKQuantityType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount)!,
            HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!,
            HKQuantityType.quantityType(forIdentifier: .waterTemperature)!,
            HKObjectType.activitySummaryType(),
            HKSeriesType.workoutRoute()
        ]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { _, error in
            if let error {
                print("❌ HealthKit authorization error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Statistics

    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics else { return }
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let unit = HKUnit.count().unitDivided(by: .minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: unit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .distanceSwimming):
                self.distance = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                self.checkSplit(newDistance: self.distance)
            case HKQuantityType.quantityType(forIdentifier: .waterTemperature):
                self.waterTemperature = statistics.mostRecentQuantity()?.doubleValue(for: .degreeCelsius()) ?? 0
            default:
                return
            }
        }
    }

    // MARK: - Preview Helper

    static var preview: WorkoutManager {
        let m = WorkoutManager()
        m.running = true
        m.isSessionActive = true
        m.heartRate = 142
        m.distance = 250
        m.splitTimes = [102.3, 98.7]
        m.lastSplitTime = 102.3
        return m
    }

    // MARK: - Split Tracking

    private func checkSplit(newDistance: Double) {
        let splitsPassed = Int(newDistance / 100.0)
        let previousSplits = Int(lastSplitDistance / 100.0)
        guard splitsPassed > previousSplits else { return }

        let now = Date()
        let elapsed = now.timeIntervalSince(lastSplitDate)
        splitTimes.append(elapsed)
        lastSplitTime = elapsed
        lastSplitDate = now
        lastSplitDistance = newDistance
    }

    // MARK: - Water Lock

    private func enableWaterLockSafely() {
        let rating = WKInterfaceDevice.current().waterResistanceRating
        guard rating == .wr50 || rating == .wr100 else { return }
        guard let session, session.state == .running else { return }
        WKInterfaceDevice.current().enableWaterLock()
        print("🔒 Water Lock enabled")
    }
    
    // MARK: - App State Management
    
    /// Spårar träningsstatus för att hålla appen aktiv
    private func setWorkoutActiveState(_ active: Bool) {
        UserDefaults.standard.set(active, forKey: "WorkoutActive")
        
        if active {
            print("🏃‍♂️ Träningsläge aktiverat - HKWorkoutSession håller appen aktiv")
            // På watchOS får HKWorkoutSession automatiskt extended runtime permissions
            // som håller appen aktiv under träning utan extra API-anrop
        } else {
            print("⏹️ Träningsläge inaktiverat - återgår till normal energisparning")
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WorkoutManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.locationPermissionStatus = manager.authorizationStatus
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, !hasLoggedStartLocation else { return }
        guard location.horizontalAccuracy > 0 && location.horizontalAccuracy < 200 else { return }
        hasLoggedStartLocation = true
        DispatchQueue.main.async { self.workoutLocation = location }
        print("📍 Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location failed: \(error.localizedDescription)")
        hasLoggedStartLocation = true
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WorkoutManager: HKWorkoutSessionDelegate {

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {

        DispatchQueue.main.async {
            // During discard all @Published changes are batched in resetAfterDiscard()
            // to avoid "Publishing changes from within view updates" warnings.
            guard !self.isDiscarding else { return }

            self.running = toState == .running

            if toState == .running && fromState == .notStarted {
                self.isSessionActive = true
                self.workoutLocation = nil
                self.logWorkoutStartLocation()
                
                // Aktivera träningsläge för att förhindra bakgrundsförflyttning
                self.setWorkoutActiveState(true)

                if self.selectedWorkout == .swimming {
                    self.enableWaterLockSafely()
                }

                if let completion = self.startWorkoutCompletion {
                    print("✅ Workout started")
                    completion(true)
                    self.startWorkoutCompletion = nil
                }
            }

            switch toState {
            case .ended:
                self.isSessionActive = false
                // Inaktivera träningsläge när sessionen är avslutad
                self.setWorkoutActiveState(false)
            case .stopped:
                self.isSessionActive = false
                // Inaktivera träningsläge när sessionen stoppas
                self.setWorkoutActiveState(false)
            default:
                break
            }
        }

        // Discard path: watchOS auto-saves on session.end(), so we let it save and
        // immediately delete via the exact HKWorkout reference from finishWorkout.
        if toState == .ended && isDiscarding {
            builder?.endCollection(withEnd: date) { [weak self] _, _ in
                guard let self else { return }
                self.builder?.finishWorkout { workout, _ in
                    if let workout {
                        self.healthStore.delete(workout) { _, error in
                            if let error {
                                print("❌ Discard delete failed: \(error.localizedDescription)")
                            }
                            Task { @MainActor [weak self] in
                                try? await Task.sleep(nanoseconds: 400_000_000)
                                self?.resetAfterDiscard()
                            }
                        }
                    } else {
                        Task { @MainActor [weak self] in
                            try? await Task.sleep(nanoseconds: 400_000_000)
                            self?.resetAfterDiscard()
                        }
                    }
                }
            }
        }

        // Save path: commit builder data and save workout
        if toState == .ended && !isDiscarding {
            builder?.endCollection(withEnd: date) { [weak self] _, _ in
                guard let self else { return }
                self.builder?.finishWorkout { workout, error in
                    DispatchQueue.main.async {
                        self.workout = workout
                        if workout != nil {
                            self.savePoolLocationRoute()
                        } else {
                            print("❌ finishWorkout failed: \(error?.localizedDescription ?? "Unknown")")
                        }
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isSessionActive = false
            self.running = false
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        guard let event = workoutBuilder.workoutEvents.last,
              event.type == .pauseOrResumeRequest else { return }
        DispatchQueue.main.async {
            self.running ? self.pause() : self.resume()
        }
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { return }
            updateForStatistics(workoutBuilder.statistics(for: quantityType))
        }
    }
}

//
//  RunManager.swift
//  RunDJ
//
//  Created by Richard Cong on 5/11/25.
//

import CoreLocation
import Combine

/// Manages running sessions and location tracking
class RunManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    private let locationManager: CLLocationManager
    private let runStatsManager: RunningStatsManager
    
    // Published properties for UI updates
    @Published private(set) var isRunning = false
    @Published private(set) var isTrackingActivity = false
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private var previousLocation: CLLocation?
    private var currentCumulativeDistance: Double = 0.0 // meters
    private var cancellables = Set<AnyCancellable>()
    private var updateTimer: Timer?
    
    // MARK: - Initialization
    
    init(locationManager: CLLocationManager = CLLocationManager(),
         runStatsManager: RunningStatsManager = RunningStatsManager.shared) {
        self.locationManager = locationManager
        self.runStatsManager = runStatsManager
        super.init()
        setupLocationManager()
    }

    // MARK: - Location Manager Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5.0
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // Set initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Run Control
    
    /// Request location permissions and start the run
    func requestPermissionsAndStart() {
        // Set flag indicating user has explicitly requested to start tracking
        userRequestedStart = true
        
        // Check current status stored in our property (which is updated via the delegate)
        switch authorizationStatus {
        case .notDetermined:
            print("Requesting location authorization...")
            // Authorization requests should be made on the main thread
            // The system will show the permission dialog and then call locationManagerDidChangeAuthorization
            locationManager.requestAlwaysAuthorization()
            // Start will be called from locationManagerDidChangeAuthorization if permission granted
        case .restricted, .denied:
            print("Location access was restricted or denied.")
            // Inform the user they need to enable permissions in Settings
            break
        case .authorizedWhenInUse, .authorizedAlways:
            start()
        @unknown default:
            print("Unknown location authorization status.")
        }
    }
    
    /// Start location tracking and running session
    private func start() {
        // Instead of checking locationServicesEnabled directly, we rely on the
        // authorization status that's updated via the delegate callback
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("Location services are not authorized or enabled.")
            return
        }

        print("Starting location tracking...")
        isRunning = true
        isTrackingActivity = true
        previousLocation = nil
        currentCumulativeDistance = 0.0
        
        runStatsManager.startRun()
        locationManager.startUpdatingLocation()
        startUpdateTimer()
    }

    /// Stop the current running session
    func stop() {
        if isRunning {
            print("Stopping location tracking...")
            isRunning = false
            isTrackingActivity = false
            userRequestedStart = false // Reset the flag when stopping
            stopUpdateTimer()
            locationManager.stopUpdatingLocation()
            runStatsManager.stopRun()
            displayFinalStats()
        }
    }

    // MARK: - Timer Logic
    
    private func startUpdateTimer() {
        stopUpdateTimer() // Ensure any existing timer is stopped
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.periodicUpdate()
        }
        print("Update timer started.")
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
        print("Update timer stopped.")
    }
    
    @objc private func periodicUpdate() {
        guard isRunning else {
            stopUpdateTimer() // Should not happen if logic is correct, but as a safeguard
            return
        }
        
        // Record a data point with the current cumulative distance and the current time.
        // This ensures elapsedTime is updated every second.
        // Distance and pace will reflect the latest known values.
        runStatsManager.recordDataPoint(newCumulativeDistance: currentCumulativeDistance, timestamp: Date())
        
        // Update UI
        updateUIDisplay()
    }

    // MARK: - CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTrackingActivity, let newLocation = locations.last else { return }

        // Basic accuracy filter
        guard newLocation.horizontalAccuracy >= 0 && newLocation.horizontalAccuracy < 65 else { // Accuracy within 65m
            print("Skipping location with poor accuracy: \(newLocation.horizontalAccuracy)m")
            return
        }
        
        // Ensure the location is reasonably new
        guard abs(newLocation.timestamp.timeIntervalSinceNow) < 15 else {
             print("Skipping old location data.")
             return
        }


        if let prevLocation = previousLocation {
            // Calculate distance increment from the last valid point
            // Only add distance if it's a meaningful change and accuracy is good
            if newLocation.horizontalAccuracy < 30 { // Stricter accuracy for distance accumulation
                 let distanceIncrement = newLocation.distance(from: prevLocation)
                 if distanceIncrement > 0 { // Ensure actual movement
                    currentCumulativeDistance += distanceIncrement
                 }
            }
        }
        previousLocation = newLocation // Update for the next calculation

        // Feed data to RunStatsManager
        // Crucially, use the timestamp from the CLLocation object
        runStatsManager.recordDataPoint(newCumulativeDistance: currentCumulativeDistance, timestamp: newLocation.timestamp)

        // Update your UI with the latest stats from runStatsManager
        updateUIDisplay()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
        // Consider pausing or notifying user based on error severity
    }
    
    // Track whether the user has explicitly requested to start tracking
    private var userRequestedStart = false
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        print("Location authorization status changed to: \(newStatus)")
        
        // Update our tracked status
        self.authorizationStatus = newStatus
        
        // Only start if the user has explicitly requested to start AND permission is granted
        if userRequestedStart && !isRunning && (newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways) {
            start()
        }
        // If we're running and permission is revoked, stop the run
        else if isRunning && (newStatus != .authorizedWhenInUse && newStatus != .authorizedAlways) {
            print("Permissions changed, stopping run.")
            stop()
            // Inform user that permissions were revoked
        }
    }
    
    // MARK: - UI Updates
    
    /// Update the UI with current running stats
    private func updateUIDisplay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let time = self.runStatsManager.formatTimeInterval(self.runStatsManager.totalElapsedTime)
            let distance = self.runStatsManager.formatDistance(self.runStatsManager.totalDistance)
            let pace = self.runStatsManager.formatPace(self.runStatsManager.currentPace, perKm: true)
            
            var rollingPaceInfo = "--:--"
            if let rollingMilePace = self.runStatsManager.rollingMilePace {
                rollingPaceInfo = self.runStatsManager.formatPace(rollingMilePace)
            }

            print("--- LIVE RUN DATA ---")
            print("Time: \(time)")
            print("Distance: \(distance)")
            print("Pace: \(pace)")
            print("Last Mile: \(rollingPaceInfo)")
            print("---------------------")
        }
    }

    /// Display final statistics after run completion
    private func displayFinalStats() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("--- FINAL RUN STATS ---")
            print("Total Time: \(self.runStatsManager.formatTimeInterval(self.runStatsManager.totalElapsedTime))")
            print("Total Distance: \(self.runStatsManager.formatDistance(self.runStatsManager.totalDistance))")
            print("Avg Pace: \(self.runStatsManager.formatPace(self.runStatsManager.currentPace, perKm: true))")
            
            if let finalRollingPace = self.runStatsManager.rollingMilePace {
                print("Last Mile Pace: \(self.runStatsManager.formatPace(finalRollingPace))")
            }
            print("-----------------------")
        }
    }
}

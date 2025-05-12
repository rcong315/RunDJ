//
//  RunManager.swift
//  RunDJ
//
//  Created by Richard Cong on 5/11/25.
//

import CoreLocation
// Assuming RunStatsManager class is in your project

class RunManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    let locationManager = CLLocationManager()
    let runStatsManager = RunningStatsManager()

    private var previousLocation: CLLocation?
    private var currentCumulativeDistance: Double = 0.0 // meters
    private var isTrackingActivity: Bool = false

    override init() {
        super.init()
        setupLocationManager()
    }

    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // High accuracy for running
        locationManager.distanceFilter = 5.0 // Update after 5 meters of movement. Adjust as needed.
        locationManager.allowsBackgroundLocationUpdates = true // For background tracking
        locationManager.pausesLocationUpdatesAutomatically = false // Keep updates active
    }

    // MARK: - Workout Control
    func requestPermissionsAndStart() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization() // Or requestAlwaysAuthorization for background
        case .restricted, .denied:
            print("Location access was restricted or denied.")
            // Inform the user they need to enable permissions in Settings
            break
        case .authorizedWhenInUse, .authorizedAlways:
            start()
        @unknown default:
            fatalError("Unhandled authorization status.")
        }
    }
    
    private func start() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services are not enabled on this device.")
            return
        }

        print("Starting location tracking...")
        isTrackingActivity = true
        previousLocation = nil
        currentCumulativeDistance = 0.0
        
        runStatsManager.startRun() // Critical: Resets and starts the stats manager
        locationManager.startUpdatingLocation()
    }

    func stop() {
        if isTrackingActivity {
            print("Stopping location tracking...")
            isTrackingActivity = false
            locationManager.stopUpdatingLocation()
            runStatsManager.stopRun() // Finalizes stats in the manager
            displayFinalStats()
        }
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
        // You might want to stop the workout or inform the user
        if isTrackingActivity {
            // Potentially stop or pause based on the error type
        }
    }
    
    // Handle authorization changes (e.g., user changes permissions in settings)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("Location authorization status changed to: \(manager.authorizationStatus)")
        if isTrackingActivity { // If a workout was active
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                // Permissions still good, or restored. Ensure location updates are running if they were stopped.
                // locationManager.startUpdatingLocation() // Could restart if it was implicitly stopped.
            } else {
                // Permissions revoked or reduced.
                print("Permissions changed, stopping workout.")
                stop()
                // Inform user
            }
        } else { // If no workout was active, but we were waiting for permission
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                // If `isTrackingActivity` was set true in `requestPermissionsAndStartWorkout` pending authorization,
                // you might call `startActualWorkout()` here.
                // For this example, assume `startActualWorkout` is only called if permission already exists or is granted then.
            }
        }
    }

    // MARK: - UI Update and Final Stats
    func updateUIDisplay() {
        // In a real app, update labels on the main thread
        DispatchQueue.main.async {
            let time = self.runStatsManager.formatTimeInterval(self.runStatsManager.totalElapsedTime)
            let distanceMi = self.runStatsManager.formatDistance(self.runStatsManager.totalDistance, useMetric: false) // Miles
            let distanceKm = self.runStatsManager.formatDistance(self.runStatsManager.totalDistance, useMetric: true)  // Kilometers
            
            let avgPaceKm = self.runStatsManager.formatPace(self.runStatsManager.currentPace, perKm: true)
            
            var rollingPaceInfo = "Last Mile Pace: Calculating..."
            if let rollingMilePace = self.runStatsManager.rollingMilePace {
                rollingPaceInfo = "Last Mile Pace: \(self.runStatsManager.formatPace(rollingMilePace, perKm: false))"
            }

            print("--- LIVE RUN DATA ---")
            print("Time: \(time)")
            print("Distance: \(distanceMi) (\(distanceKm))")
            print("Avg Pace: \(avgPaceKm)")
            print(rollingPaceInfo)
            print("---------------------")
            
            // Example:
            // self.timeLabel.text = time
            // self.distanceLabel.text = distanceMi
            // self.avgPaceLabel.text = avgPaceKm
            // self.rollingPaceLabel.text = rollingPaceInfo
        }
    }

    func displayFinalStats() {
        DispatchQueue.main.async {
            print("--- FINAL RUN STATS ---")
            print("Total Time: \(self.runStatsManager.formatTimeInterval(self.runStatsManager.totalElapsedTime))")
            print("Total Distance: \(self.runStatsManager.formatDistance(self.runStatsManager.totalDistance, useMetric: false))")
            print("Overall Avg Pace (per km): \(self.runStatsManager.formatPace(self.runStatsManager.currentPace, perKm: true))")
            if let finalRollingPace = self.runStatsManager.rollingMilePace {
                 print("Final Last Mile Pace: \(self.runStatsManager.formatPace(finalRollingPace, perKm: false))")
            }
            print("-----------------------")
        }
    }
}

//
//  RunManager.swift
//  RunDJ
//
//  Created by Richard Cong on 5/11/25.
//

import CoreLocation
import Combine
import Sentry

/// Manages running sessions and location tracking
class RunManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    static let shared = RunManager()
    
    private let locationManager: CLLocationManager
    private let runStatsManager: RunningStatsManager
    
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
        
        configureLocationManager()
        
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Location Manager Setup
    
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5.0
        
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Run Control
    
    /// Request location permissions and start the run
    func requestPermissionsAndStart() {
        userRequestedStart = true
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted, .denied:
            SentrySDK.capture(message: "Location access restricted or denied") { scope in
                scope.setContext(value: ["authorization_status": self.authorizationStatus.rawValue], key: "permissions")
                scope.setLevel(.warning)
            }
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
            return
        }
        
        isRunning = true
        isTrackingActivity = true
        previousLocation = nil
        currentCumulativeDistance = 0.0
        
        locationManager.allowsBackgroundLocationUpdates = true
        
        runStatsManager.startRun()
        locationManager.startUpdatingLocation()
        startUpdateTimer()
    }
    
    /// Stop the current running session
    func stop() {
        if isRunning {
            isRunning = false
            isTrackingActivity = false
            userRequestedStart = false
            stopUpdateTimer()
            locationManager.stopUpdatingLocation()
            
            locationManager.allowsBackgroundLocationUpdates = false
            
            runStatsManager.stopRun()
            displayFinalStats()
        }
    }
    
    // MARK: - Timer Logic
    
    private func startUpdateTimer() {
        stopUpdateTimer()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.periodicUpdate()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    @objc private func periodicUpdate() {
        guard isRunning else {
            stopUpdateTimer()
            return
        }
        
        runStatsManager.recordDataPoint(newCumulativeDistance: currentCumulativeDistance, timestamp: Date())
        
        updateUIDisplay()
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTrackingActivity, let newLocation = locations.last else { return }
        
        guard newLocation.horizontalAccuracy >= 0 && newLocation.horizontalAccuracy < 65 else {
            let breadcrumb = Breadcrumb()
            breadcrumb.level = .warning
            breadcrumb.category = "location"
            breadcrumb.message = "Skipped location with accuracy \(newLocation.horizontalAccuracy)m"
            SentrySDK.addBreadcrumb(breadcrumb)
            return
        }
        
        guard abs(newLocation.timestamp.timeIntervalSinceNow) < 15 else {
            return
        }
        
        if let prevLocation = previousLocation {
            if newLocation.horizontalAccuracy < 30 {
                let distanceIncrement = newLocation.distance(from: prevLocation)
                if distanceIncrement > 0 {
                    currentCumulativeDistance += distanceIncrement
                }
            }
        }
        previousLocation = newLocation
        
        runStatsManager.recordDataPoint(newCumulativeDistance: currentCumulativeDistance, timestamp: newLocation.timestamp)
        
        updateUIDisplay()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        SentrySDK.capture(error: error) { scope in
            scope.setContext(value: [
                "is_running": self.isRunning,
                "is_tracking": self.isTrackingActivity,
                "authorization_status": self.authorizationStatus.rawValue
            ], key: "location_tracking")
            scope.setLevel(.error)
        }
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                stop()
            case .network:
                let breadcrumb = Breadcrumb()
                breadcrumb.level = .warning
                breadcrumb.category = "location"
                breadcrumb.message = "Network error during location update"
                SentrySDK.addBreadcrumb(breadcrumb)
            default:
                break
            }
        }
    }
    
    private var userRequestedStart = false
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        
        self.authorizationStatus = newStatus
        
        if userRequestedStart && !isRunning && (newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways) {
            start()
        }
        
        else if isRunning && (newStatus != .authorizedWhenInUse && newStatus != .authorizedAlways) {
            SentrySDK.capture(message: "Location permissions revoked during active run") { scope in
                scope.setContext(value: [
                    "old_status": self.authorizationStatus.rawValue,
                    "new_status": newStatus.rawValue
                ], key: "permissions")
                scope.setLevel(.error)
            }
            stop()
        }
    }
    
    // MARK: - UI Updates
    
    /// Update the UI with current running stats
    private func updateUIDisplay() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            _ = self.runStatsManager.formatTimeInterval(self.runStatsManager.totalElapsedTime)
            _ = self.runStatsManager.formatDistance(self.runStatsManager.totalDistance)
            _ = self.runStatsManager.formatPace(self.runStatsManager.currentPace, perKm: false)
        }
    }
    
    /// Display final statistics after run completion
    private func displayFinalStats() {
        DispatchQueue.main.async { [weak self] in
            guard self != nil else { return }
        }
    }
}

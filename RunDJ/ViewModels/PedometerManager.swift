//
//  PedometerManager.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import CoreMotion
import Combine
import Sentry

/// Manages pedometer data tracking including steps per minute
class PedometerManager: ObservableObject {
    
    static let shared = PedometerManager()
    
    private let pedometer: CMPedometer
    
    /// The current steps per minute (cadence)
    @Published private(set) var stepsPerMinute: Double = 0.0
    
    /// Indicates if pedometer updates are active
    @Published private(set) var isActive: Bool = false
    
    /// Indicates if step counting is available on this device
    let isStepCountingAvailable: Bool
    
    // MARK: - Initialization
    
    init(pedometer: CMPedometer = CMPedometer()) {
        self.pedometer = pedometer
        self.isStepCountingAvailable = CMPedometer.isStepCountingAvailable()
        
        startPedometerUpdates()
    }

    // MARK: - Pedometer Control
    
    /// Start tracking pedometer updates
    func startPedometerUpdates() {
        guard isStepCountingAvailable else {
            print("Pedometer not available on this device")
            return
        }
        
        isActive = true
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error starting pedometer: \(error.localizedDescription)")
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "start_pedometer_updates"], key: "pedometer")
                    scope.setLevel(.error)
                }
                return
            }
            
            guard let data = data else {
                print("No pedometer data received")
                return
            }
            
            DispatchQueue.main.async {
                self.stepsPerMinute = (data.currentCadence?.doubleValue ?? 0.0) * 60
                print("Steps per minute: \(self.stepsPerMinute)")
            }
        }
    }
    
    /// Stop pedometer updates
    func stopPedometerUpdates() {
        isActive = false
        pedometer.stopUpdates()
    }
}

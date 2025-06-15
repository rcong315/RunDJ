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
    @Published private(set) var steps: Int = 0
    @Published private(set) var stepsPerMinute: Double = 0.0
    @Published private(set) var pace: Double = 0.0
    
    /// Indicates if pedometer updates are active
    @Published private(set) var isActive: Bool = false
    
    /// Indicates if step counting is available on this device
    let isStepCountingAvailable: Bool
    let isCadenceAvailable: Bool
    let isPaceAvailable: Bool
    
    /// Start time of the current pedometer session
    @Published private(set) var startTime: Date?
    
    // MARK: - Initialization
    
    init(pedometer: CMPedometer = CMPedometer()) {
        self.pedometer = pedometer
        self.isStepCountingAvailable = CMPedometer.isStepCountingAvailable()
        self.isCadenceAvailable = CMPedometer.isCadenceAvailable()
        self.isPaceAvailable = CMPedometer.isPaceAvailable()
        
        self.startPedometerUpdates()
    }

    // MARK: - Pedometer Control
    
    /// Start tracking pedometer updates
    func startPedometerUpdates() {
        guard isCadenceAvailable && isPaceAvailable else {
            return
        }
        
        isActive = true
        startTime = Date()
        pedometer.startUpdates(from: startTime!) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                SentrySDK.capture(error: error) { scope in
                    scope.setContext(value: ["action": "start_pedometer_updates"], key: "pedometer")
                    scope.setLevel(.error)
                }
                return
            }
            
            guard let data = data else {
                return
            }
            
            DispatchQueue.main.async {
                self.steps = data.numberOfSteps.intValue
                self.stepsPerMinute = (data.currentCadence?.doubleValue ?? 0.0) * 60
                self.pace = data.currentPace?.doubleValue ?? 0.0
            }
        }
    }
    
    /// Stop pedometer updates
    func stopPedometerUpdates() {
        isActive = false
        startTime = nil
        pedometer.stopUpdates()
    }
}

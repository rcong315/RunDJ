//
//  PedometerManager.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import CoreMotion

class PedometerManager: ObservableObject {
    
    static let shared = PedometerManager()
    
    private var pedometer = CMPedometer()
    @Published var stepsPerMinute: Double = 0.0
    
    init() {
        startPedometerUpdates()
    }

    private func startPedometerUpdates() {
        guard CMPedometer.isStepCountingAvailable() else { print("Pedometer not available"); return }
        
        pedometer.startUpdates(from: Date()) { data, error in
            guard let data = data, error == nil else {
                print("Error starting pedometer: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.stepsPerMinute = (data.currentCadence?.doubleValue ?? 0.0) * 60
                print("Steps per minute: \(self.stepsPerMinute)")
            }
        }
    }
}

//
//  PedometerManager.swift
//  RunDJ
//
//  Created by Richard Cong on 2/8/25.
//

import CoreMotion


protocol PedometerManagerDelegate: AnyObject {
    func didUpdateStepsPerMinute(_ stepsPerMinute: Double)
}


class PedometerManager: ObservableObject {
    
    private var pedometer = CMPedometer()
    private var steps: [Date] = []
    private let windowSize = 60
    private let refreshRate = 5
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
                print(self.stepsPerMinute * 60)
            }
        }
    }
}

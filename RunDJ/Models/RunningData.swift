//
//  RunningData.swift
//  RunDJ
//
//  Created on 5/15/25.
//

import Foundation
import CoreLocation

/// Model representing running workout data
struct RunningData {
    var totalDistance: Double
    var currentPace: Double
    var elapsedTime: TimeInterval
    var route: [CLLocationCoordinate2D]
    var stepsPerMinute: Double
    
    init(totalDistance: Double = 0.0, 
         currentPace: Double = 0.0, 
         elapsedTime: TimeInterval = 0.0, 
         route: [CLLocationCoordinate2D] = [], 
         stepsPerMinute: Double = 0.0) {
        self.totalDistance = totalDistance
        self.currentPace = currentPace
        self.elapsedTime = elapsedTime
        self.route = route
        self.stepsPerMinute = stepsPerMinute
    }
    
    /// Format distance in kilometers or meters based on value
    func formattedDistance() -> String {
        if totalDistance >= 1000 {
            let kilometers = totalDistance / 1000
            return String(format: "%.2f km", kilometers)
        } else {
            return String(format: "%.0f m", totalDistance)
        }
    }
    
    /// Format pace in minutes per kilometer
    func formattedPace() -> String {
        guard currentPace > 0 else { return "--:--" }
        
        let minutesPerKm = currentPace
        let minutes = Int(minutesPerKm)
        let seconds = Int((minutesPerKm - Double(minutes)) * 60)
        
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Format elapsed time in HH:MM:SS
    func formattedElapsedTime() -> String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
